shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

// Quad de tela cheia preso na camera. Le so o DEPTH_TEXTURE, entao nao depende
// do buffer de normais (que e exclusivo do renderer Forward+).
// Outline: sobel na profundidade. Rim light: normal reconstruida da profundidade.

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;

uniform bool outline_enabled = false;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_thickness = 1.0;
uniform float outline_threshold = 0.25;

uniform bool rim_enabled = false;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_power = 3.0;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.5;

vec3 view_position(vec2 uv, mat4 inverse_projection) {
	float raw = texture(depth_tex, uv).r;
	vec4 position = inverse_projection * vec4(vec3(uv * 2.0 - 1.0, raw), 1.0);
	return position.xyz / position.w;
}

void vertex() {
	// QuadMesh 2x2 mapeado direto em clip space.
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 texel = 1.0 / VIEWPORT_SIZE;
	float raw_center = texture(depth_tex, SCREEN_UV).r;
	bool is_sky = raw_center <= 0.000001;

	vec3 center = view_position(SCREEN_UV, INV_PROJECTION_MATRIX);
	float depth_center = -center.z;

	vec3 color = vec3(0.0);
	float alpha = 0.0;

	if (rim_enabled && !is_sky) {
		vec3 right = view_position(SCREEN_UV + vec2(texel.x, 0.0), INV_PROJECTION_MATRIX);
		vec3 up = view_position(SCREEN_UV + vec2(0.0, texel.y), INV_PROJECTION_MATRIX);
		vec3 normal = normalize(cross(right - center, up - center));
		if (normal.z < 0.0) {
			normal = -normal;
		}
		float facing = clamp(dot(normal, normalize(-center)), 0.0, 1.0);
		float rim = pow(1.0 - facing, max(rim_power, 0.01));
		color = rim_color.rgb;
		alpha = rim * rim_strength * rim_color.a;
	}

	if (outline_enabled) {
		vec2 offset = texel * max(outline_thickness, 0.5);
		float left = -view_position(SCREEN_UV - vec2(offset.x, 0.0), INV_PROJECTION_MATRIX).z;
		float right = -view_position(SCREEN_UV + vec2(offset.x, 0.0), INV_PROJECTION_MATRIX).z;
		float down = -view_position(SCREEN_UV - vec2(0.0, offset.y), INV_PROJECTION_MATRIX).z;
		float up = -view_position(SCREEN_UV + vec2(0.0, offset.y), INV_PROJECTION_MATRIX).z;

		// Segunda derivada da profundidade: acusa quebra (silhueta) e ignora
		// superficie plana inclinada, que e so um gradiente constante.
		float horizontal = abs(left + right - 2.0 * depth_center);
		float vertical = abs(down + up - 2.0 * depth_center);
		float difference = max(horizontal, vertical);
		// Limiar relativo a distancia: geometria longe nao vira borrao de linha.
		float reference = max(depth_center, 0.05) * max(outline_threshold, 0.001) * 0.05;
		float edge = smoothstep(reference, reference * 2.0, difference);
		if (is_sky) {
			edge = 0.0;
		}

		color = mix(color, outline_color.rgb, edge);
		alpha = max(alpha, edge * outline_color.a);
	}

	ALBEDO = color;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
