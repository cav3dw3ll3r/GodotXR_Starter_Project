shader_type spatial;

render_mode unshaded,cull_back,depth_draw_opaque;

uniform float time_speed : hint_range(0.0, 5.0) = 1.2;
uniform vec3 glow_color = vec3(0.1, 0.8, 1.5);
uniform float glow_strength = 3.0;

uniform float grid_density = 35.0;
uniform float scroll_speed = 1.5;

uniform float distortion_amount = 0.25;
uniform float fresnel_power = 4.0;

// Simple hash-based noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Smooth noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0,0.0));
    float c = hash(i + vec2(0.0,1.0));
    float d = hash(i + vec2(1.0,1.0));
    
    vec2 u = f*f*(3.0-2.0*f);
    
    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

void fragment() {
    float t = TIME * time_speed;

    // UV but force spherical wrap for sphere meshes
    vec2 uv = UV * vec2(1.0, 1.0);

    // Procedural scrolling grid
    vec2 grid_uv = uv * grid_density;
    grid_uv.y += t * scroll_speed;

    vec2 cell = fract(grid_uv) - 0.5;
    float line_x = smoothstep(0.48, 0.49, abs(cell.x));
    float line_y = smoothstep(0.48, 0.49, abs(cell.y));
    float grid = max(line_x, line_y);

    // Pixelation
	float pixel_count = 28.0;          // tweak for chunk size
	vec2 px_uv = floor(uv * pixel_count) / pixel_count;

	// Chunky noise
	float bit_noise = noise(px_uv * 60.0 + t * 1.0);

	// Binary chunky bits
	float bits = smoothstep(0.5, 0.8, bit_noise);
	bits = floor(bits * 2.0);   // 0 or 1 only

    // Distortion waves
    float distort = noise(uv * 5.0 + t * 0.3) * distortion_amount;
    uv += vec2(distort, distort * 0.5);

    // Fresnel glow
    float fres = pow(1.0 - dot(NORMAL, VIEW), fresnel_power);

    // Chromatic glitch
    vec3 col = vec3(0.0);

    col.r = bits * 0.5 + fres * glow_strength;
    col.g = bits * 0.8 + fres * glow_strength * 0.5;
    col.b = bits * 1.2 + fres * glow_strength * 0.9;

    // Apply tint
    col *= glow_color;

    ALBEDO = col;
    EMISSION = col * 2.0 * glow_strength;
	ALPHA = col.r+0.5;
}
