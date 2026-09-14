shader_type spatial;
render_mode unshaded;

uniform float timeScaleFactor = 0.4;
uniform sampler2D noise_texture : repeat_enable, filter_linear;

float localTime() {
	return TIME * timeScaleFactor;
}

mat2 makem2(float theta) {
	float c = cos(theta);
	float s = sin(theta);
	return mat2(vec2(c, -s), vec2(s, c));
}

float noise(vec2 x) {
	return texture(noise_texture, x * 0.01).x;
}

vec2 gradn(vec2 p) {
	float ep = 0.09;
	float gradx = noise(vec2(p.x + ep, p.y)) - noise(vec2(p.x - ep, p.y));
	float grady = noise(vec2(p.x, p.y + ep)) - noise(vec2(p.x, p.y - ep));
	return vec2(gradx, grady);
}

float flow(vec2 p) {
	float z = 2.0;
	float rz = 0.0;
	vec2 bp = p;

	for (float i = 1.0; i < 7.0; i += 1.0) {
		p += localTime() * 0.6;
		bp += localTime() * 1.9;
		vec2 gr = gradn(i * p * 0.34 + localTime());
		gr *= makem2(localTime() * 6.0 - (0.05 * p.x + 0.03 * p.y) * 40.0);
		p += gr * 0.5;
		rz += (sin(noise(p) * 7.0) * 0.5 + 0.5) / z;
		p = mix(bp, p, 0.77);
		z *= 1.4;
		p *= 2.0;
		bp *= 1.9;
	}
	return rz;
}

void fragment() {
	vec2 p = UV - 0.5;
	p *= 3.0;

	float rz = flow(p);
	vec3 col = vec3(0.2, 0.07, 0.01) / rz;
	col = pow(col, vec3(1.4));

	ALBEDO = col;
	EMISSION = col * 2.5;
}
