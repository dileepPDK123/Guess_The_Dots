shader_type canvas_item;
// Animated hex-grid background for NEURAL GRID — subtle cyan lines on void black.

uniform float scroll_speed : hint_range(0.0, 0.3) = 0.04;
uniform vec4  line_color   : source_color = vec4(0.0, 0.85, 1.0, 0.07);
uniform float hex_radius   : hint_range(20.0, 200.0) = 72.0;
uniform float line_width   : hint_range(0.5, 5.0) = 1.6;

// Background void color — must match C_BG in Main.gd
const vec4 BG = vec4(0.016, 0.012, 0.039, 1.0);
const float SQRT3 = 1.7320508;

// Pointy-top hex SDF (circumradius R).
// Returns 0 on the boundary, <0 inside, >0 outside.
float hex_sdf(vec2 p, float R) {
	p = abs(p);
	float d = max(p.y, dot(p, vec2(SQRT3 * 0.5, 0.5)));
	return (d - R);
}

// Returns the local position relative to the nearest hex centre
// in a pointy-top grid with circumradius R.
vec2 hex_nearest(vec2 p, float R) {
	// Two interleaved rectangular grids cover all hex centres.
	// Grid spacing: w = sqrt(3)*R (x), h = 1.5*R (y per half-period = 3R total period)
	float w = SQRT3 * R;
	float h = 1.5 * R;

	vec2 pa = vec2(mod(p.x,       w) - w * 0.5,
	               mod(p.y,   2.0*h) - h);
	vec2 pb = vec2(mod(p.x + w*0.5, w) - w * 0.5,
	               mod(p.y +     h, 2.0*h) - h);

	return length(pa) < length(pb) ? pa : pb;
}

void fragment() {
	vec2 uv = FRAGCOORD.xy;

	// Slow diagonal scroll — imperceptible drift that makes it feel alive
	uv += TIME * scroll_speed * vec2(11.0, 6.5);

	vec2 local = hex_nearest(uv, hex_radius);
	float d     = abs(hex_sdf(local, hex_radius));   // distance to hex edge

	// Thin glowing edge
	float alpha = 1.0 - smoothstep(0.0, line_width, d);

	// Mix edge colour over void background
	COLOR = vec4(mix(BG.rgb, line_color.rgb, alpha * line_color.a), 1.0);
}
