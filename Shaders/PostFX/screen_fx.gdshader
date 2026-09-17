shader_type canvas_item;
render_mode unshaded;

// Pos-processamento 2D usado pela aba DEV das opcoes.
// Ordem: pixelation -> distortion -> chromatic aberration -> cel -> grading
//        -> speed lines -> film grain.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;

// ---------------------------------------------------------------- cel shading
uniform bool cel_enabled = false;
uniform float cel_bands = 4.0;
uniform float cel_mix : hint_range(0.0, 1.0) = 1.0;

// ---------------------------------------------------------------- speed lines
uniform bool speedlines_enabled = false;
uniform float speedlines_strength : hint_range(0.0, 1.0) = 0.5;
uniform float speedlines_density = 60.0;
uniform float speedlines_speed = 1.0;
uniform float speedlines_falloff : hint_range(0.0, 1.0) = 0.5;
uniform vec4 speedlines_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// ----------------------------------------------------------------- distortion
uniform bool distortion_enabled = false;
uniform float distortion_strength = 0.005;
uniform float distortion_speed = 1.0;
uniform float distortion_scale = 8.0;

// ----------------------------------------------------------------- film grain
uniform bool grain_enabled = false;
uniform float grain_amount : hint_range(0.0, 1.0) = 0.08;
uniform float grain_size = 2.0;
uniform bool grain_animated = true;

// --------------------------------------------------------------- color grading
uniform bool grading_enabled = false;
uniform float grading_exposure = 1.0;
uniform float grading_contrast = 1.0;
uniform float grading_saturation = 1.0;
uniform float grading_temperature : hint_range(-1.0, 1.0) = 0.0;
uniform float grading_tint : hint_range(-1.0, 1.0) = 0.0;

// --------------------------------------------------------- chromatic aberration
uniform bool chroma_enabled = false;
uniform float chroma_strength = 0.003;
uniform float chroma_falloff = 2.0;

// ------------------------------------------------------------------ pixelation
uniform bool pixelate_enabled = false;
uniform float pixelate_size = 4.0;
uniform bool pixelate_quantize = false;
uniform float pixelate_levels = 16.0;

const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

// Hash por permutacao de bits (mesmo estilo do cartoon_sky.gdshader)
float hash(vec2 p) {
	uvec2 q = uvec2(ivec2(p));
	q = q * uvec2(1597334677u, 3812015801u);
	uint n = (q.x ^ q.y) * 1597334677u;
	return float(n) * (1.0 / 4294967295.0);
}

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv = SCREEN_UV;

	if (pixelate_enabled) {
		vec2 grid = max(resolution / max(pixelate_size, 1.0), vec2(1.0));
		uv = (floor(uv * grid) + 0.5) / grid;
	}

	if (distortion_enabled) {
		float t = TIME * distortion_speed;
		vec2 wave = vec2(
			sin(uv.y * distortion_scale + t),
			cos(uv.x * distortion_scale + t * 1.3)
		);
		uv += wave * distortion_strength;
	}

	uv = clamp(uv, vec2(0.0), vec2(1.0));

	vec3 color;
	if (chroma_enabled) {
		vec2 radial = uv - vec2(0.5);
		float distance_factor = pow(clamp(length(radial) * 2.0, 0.0, 1.0), chroma_falloff);
		vec2 shift = normalize(radial + vec2(0.000001)) * distance_factor * chroma_strength;
		color.r = texture(screen_tex, clamp(uv + shift, vec2(0.0), vec2(1.0))).r;
		color.g = texture(screen_tex, uv).g;
		color.b = texture(screen_tex, clamp(uv - shift, vec2(0.0), vec2(1.0))).b;
	} else {
		color = texture(screen_tex, uv).rgb;
	}

	if (pixelate_enabled && pixelate_quantize) {
		float levels = max(pixelate_levels, 2.0);
		color = floor(color * levels + 0.5) / levels;
	}

	if (cel_enabled) {
		float bands = max(cel_bands, 1.0);
		float luma = dot(color, LUMA);
		float banded = floor(luma * bands + 0.5) / bands;
		vec3 celled = color * (banded / max(luma, 0.0001));
		color = mix(color, celled, cel_mix);
	}

	if (grading_enabled) {
		color *= grading_exposure;
		color = (color - vec3(0.5)) * grading_contrast + vec3(0.5);
		float luma = dot(color, LUMA);
		color = mix(vec3(luma), color, grading_saturation);
		color.r *= 1.0 + grading_temperature * 0.3;
		color.b *= 1.0 - grading_temperature * 0.3;
		color.g *= 1.0 + grading_tint * 0.3;
		color = max(color, vec3(0.0));
	}

	if (speedlines_enabled) {
		vec2 radial = SCREEN_UV - vec2(0.5);
		float angle = atan(radial.y, radial.x);
		float radius = clamp(length(radial) * 2.0, 0.0, 1.0);
		float stroke = floor(angle * max(speedlines_density, 1.0));
		float flicker = hash(vec2(stroke, floor(TIME * speedlines_speed * 12.0)));
		float length_variation = mix(0.35, 1.0, hash(vec2(stroke, 7.0)));
		float start = mix(1.0, speedlines_falloff, length_variation);
		float mask = smoothstep(start, 1.0, radius) * smoothstep(0.55, 1.0, flicker);
		color = mix(color, speedlines_color.rgb, mask * speedlines_strength * speedlines_color.a);
	}

	if (grain_enabled) {
		vec2 grain_uv = floor(SCREEN_UV * resolution / max(grain_size, 1.0));
		float frame = grain_animated ? floor(TIME * 24.0) : 0.0;
		float noise = hash(grain_uv + vec2(frame * 13.0, frame * 7.0)) - 0.5;
		color += vec3(noise * grain_amount);
	}

	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), 1.0);
}
