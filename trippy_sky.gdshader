shader_type sky;
render_mode use_half_res_pass; // optional: enables half-res subpass for expensive ops

/* Bitstream / Grid Sky shader
   - Perspective-correct grid from EYEDIR
   - Animated "bitstream" vertical streaks
   - Neon palette, glow at intersections
   - Tunable: scale, speed, line thickness, colors
*/

/* === Exposed uniforms === */
uniform float grid_scale : hint_range(0.1, 64.0) = 12.0;
uniform float line_thickness : hint_range(0.001, 0.1) = 0.014;
uniform float glow : hint_range(0.0, 2.0) = 0.9;
uniform float speed : hint_range(-4.0, 4.0) = 0.55;
uniform float binary_density : hint_range(0.0, 1.0) = 0.45;
uniform vec3 color_base : source_color = vec3(0.02, 0.05, 0.12); // deep background
uniform vec3 color_grid : source_color = vec3(0.0, 1.0, 0.9);     // neon cyan
uniform vec3 color_accent : source_color = vec3(1.0, 0.0, 0.9);   // magenta accent
uniform vec3 color_glow : source_color = vec3(0.6, 0.2, 1.0);     // glow tint

/* small helpers */
float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}
float hash11(float x) {
    return fract(sin(x) * 43758.5453123);
}

/* 2D smooth tileable noise (value noise-ish) */
float tileable_noise(vec2 uv, float scale) {
    uv *= scale;
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    // corners
    float a = hash21(i + vec2(0.0, 0.0));
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    // smooth interp
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

/* Convert eye direction to equirectangular UV (tiling across 360°) */
vec2 sky_uv_from_eyedir(vec3 ed) {
    // ed is EYEDIR built-in, pointing from camera into world
    // spherical coords -> equirectangular uv [0,1]
    float lon = atan(ed.x, ed.z); // -PI..PI
    float lat = asin(clamp(ed.y, -1.0, 1.0)); // -PI/2..PI/2
    vec2 uv = vec2((lon / (PI * 2.0)) + 0.5, (lat / PI) + 0.5);
    return uv;
}

/* Soft line drawing: returns intensity for line centered at `pos` in [0,1] */
float soft_line(float v, float width) {
    return smoothstep(width, 0.0, abs(v));
}

void sky() {
    // built-ins: EYEDIR (vec3), TIME (float), POSITION (camera pos)
    vec3 ed = normalize(EYEDIR);
    vec2 uv = sky_uv_from_eyedir(ed);

    // Make uv tileable horizontally by repeating across columns naturally from lon mapping.
    // We'll use uv in grid space
    vec2 g = uv * grid_scale;

    // Add a little polar stretch so grid feels like receding (y compression)
    float perspective = pow(1.0 - clamp(ed.y * 0.5 + 0.5, 0.0, 1.0), 0.8);
    g.y *= mix(1.0, 1.6, perspective);

    // base background with subtle noise for depth
    float base_noise = tileable_noise(uv * 3.0, 4.0) * 0.25;
    vec3 base = color_base + base_noise * 0.12;

    // Grid lines (both X and Y)
    vec2 gv = fract(g) - 0.5; // centered [-0.5,0.5]
    vec2 id = floor(g);       // grid cell integer coords

    float line_x = soft_line(gv.x+0.5, line_thickness);
    float line_y = soft_line(gv.y, line_thickness-0.01);

    // Crossing brightness gives stronger intersections
    float cross = line_x * line_y;
    float line_mask = max(line_x, line_y);

    // Animated bitstream: vertical streaks of binary-looking dots moving 'down' uv.y
    // We'll generate per-column pseudo-random streams using id.x as seed
    float col_seed = hash11(id.x * 12.9898);
    // per-cell vertical offset (makes bits staggered)
    float stream_phase = fract(TIME * speed + col_seed * 7.0 + id.y * 0.37);
    // create a repeating column of bright bits
    float bit_pos = fract(g.y + stream_phase);
    // shape each bit as a small pulse
    float bit = smoothstep(0.18, 0.0, abs(bit_pos - 0.02)) * smoothstep(0.0, 0.2, binary_density);
    // modulate with hash to vary brightness per-column
    float col_variation = hash21(id + vec2(0.5, 0.2));
    bit *= mix(0.6, 1.6, col_variation);

    // Alternating binary-like pattern: choose 0/1 per-cell with hash
    float bval = step(0.5, hash21(id));
    // make binary dots (0 or 1 brightness) combined with moving bits
    float binary = bit * bval;

    // Soft glow around lines & bits
    float glow_lines = pow(line_mask, 1.5) * glow;
    float glow_cross = pow(cross, 2.2) * (glow * 1.6);
    float glow_bits = pow(binary, 1.2) * 1.8;

    // Color mixing: grid base plus accent for intersections and streaming bits
    vec3 grid_col = mix(color_grid * 0.9, color_accent * 0.9, smoothstep(0.2, 1.0, cross));
    vec3 bit_col = mix(color_grid, color_accent, fract(col_seed * 10.0));

    // Slight vignette by vertical (makes bottom feel "grounded")
    float vertical_fade = smoothstep(0.0, 0.6, ed.y); // fades toward top
    // Compose final color
    vec3 col = base;

    // Add grid lines
    col += grid_col * (line_mask * 0.9);

    // Add binary stream brightness
    col += bit_col * (binary * 0.85);

    // Add glows
    col += color_glow * (glow_lines * 0.35 + glow_cross * 0.45 + glow_bits * 0.65);

    // subtle chromatic tint by latitude to give a bitstream-aurora feel
    float lat_tint = smoothstep(0.0, 1.0, uv.y);
    col = mix(col * (1.0 - 0.05 * lat_tint), col * (1.0 + 0.08 * lat_tint), lat_tint);

    // final color tone mapping clamp
    COLOR = clamp(col, 0.0, 1.0);
}
