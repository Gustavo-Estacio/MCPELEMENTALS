shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

// Toon shader aplicado como surface override pelo DevFX. Copia albedo/textura
// do StandardMaterial3D original e troca a iluminacao por faixas duras.

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(1.0, 1.0);

uniform float bands = 3.0;
uniform float band_softness : hint_range(0.0, 0.5) = 0.02;
uniform float shadow_tint : hint_range(0.0, 1.0) = 0.35;
uniform float specular_size : hint_range(1.0, 128.0) = 32.0;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.3;
uniform float light_energy : hint_range(0.1, 2.0) = 0.5;

void fragment() {
	vec4 texture_color = texture(albedo_texture, UV * uv_scale);
	// Nao escrever ALPHA de proposito: qualquer escrita marca o material como
	// transparente, e ai a malha sai da passada opaca e some atras do chao.
	ALBEDO = albedo.rgb * texture_color.rgb;
	SPECULAR = 0.0;
	ROUGHNESS = 1.0;
}

void light() {
	float steps = max(bands, 1.0);
	float lambert = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;

	// Faixa dura com borda suavizada por band_softness.
	float scaled = lambert * steps;
	float level = floor(scaled);
	float fraction = smoothstep(0.5 - band_softness * steps, 0.5 + band_softness * steps, fract(scaled));
	float banded = (level + fraction) / steps;
	banded = mix(shadow_tint, 1.0, banded);

	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * banded * light_energy;

	if (specular_strength > 0.0) {
		vec3 half_vector = normalize(LIGHT + VIEW);
		float highlight = pow(clamp(dot(NORMAL, half_vector), 0.0, 1.0), specular_size);
		highlight = smoothstep(0.45, 0.55, highlight);
		SPECULAR_LIGHT += LIGHT_COLOR * highlight * specular_strength * ATTENUATION;
	}
}
