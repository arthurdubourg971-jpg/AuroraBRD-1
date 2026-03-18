// =============================================================
//  Aurora BRD — stars.fsh
//  Overworld: night stars that fade with sunrise/sunset
//  The End:   dense stars + colored nebula wisps
// =============================================================
#version 300 es
precision highp float;

#include "include/config.glsl"
#include "include/noise.glsl"

uniform vec4 ViewPositionAndTime;
uniform vec4 SunMoonColor;
uniform vec4 LightWorldSpaceDirection;
uniform int  uDimensionId;

in vec3 v_WorldPos;
in vec4 v_Color;
in vec3 v_RayDir;

out vec4 FragColor;

// ── Procedural star field ─────────────────────────────────────
// Uses a grid-based approach for reproducible placement
vec3 StarField(vec3 dir, float time, float density, float brightness) {
    vec2  proj  = vec2(atan(dir.x, dir.z), asin(dir.y));
    proj       *= vec2(60.0, 40.0);

    vec2  cell  = floor(proj);
    vec2  f     = fract(proj) - 0.5;

    vec2  rpos  = (hash22(cell) - 0.5) * 0.7;
    float dist  = length(f - rpos);

    // Only show in occupied cells
    float occ   = step(density, hash12(cell));
    float star  = smoothstep(0.07, 0.01, dist) * occ;

    // Star colour variation
    float colVar = hash12(cell + 13.7);
    vec3  col    = mix(
        vec3(0.9, 0.9, 1.0),      // blue-white
        mix(vec3(1.0, 0.7, 0.5),  // warm orange
            vec3(0.6, 0.8, 1.0),  // cool blue
            colVar),
        step(0.6, colVar)
    );

    // Twinkle
    float tw = 0.85 + 0.15 * sin(time * (2.0 + hash12(cell + 4.1) * 3.0));
    return col * star * brightness * tw;
}

// ── End star field (denser, colored) ─────────────────────────
vec3 EndStarField(vec3 dir, float time) {
    vec3 s0 = StarField(dir, time, 0.35, 2.5);   // dense layer
    vec3 s1 = StarField(dir * 2.1 + 0.5, time * 0.7, 0.45, 1.2); // second layer
    vec3 s2 = StarField(dir * 3.7 + 1.2, time * 1.3, 0.55, 0.6); // faint

    // Purple-tinted milky way band
    float band = exp(-pow(abs(dir.y) * 2.5, 2.0));
    vec3  mw   = vec3(0.15, 0.04, 0.25) * band * (fbm3D(dir * 4.0, 3) * 0.5 + 0.5);

    return s0 + s1 + s2 + mw;
}

void main() {
    vec3  dir   = normalize(v_RayDir);
    float time  = ViewPositionAndTime.w;
    vec3  sunDir = normalize(LightWorldSpaceDirection.xyz);

    vec3 col = vec3(0.0);

    if (uDimensionId == 2) {
        // ── The End: always render full star field
        col = EndStarField(dir, time);

    } else {
        // ── Overworld: fade with sun elevation
        float nightFactor = smoothstep(0.1, -0.08, sunDir.y);
        if (nightFactor < 0.001) discard;
        col = StarField(dir, time, 0.50, 1.0) * nightFactor;
    }

    if (length(col) < 0.001) discard;

    // Gamma + engine tint
    col  = pow(clamp(col, 0.0, 1.0), vec3(1.0 / 2.2));
    col *= v_Color.rgb;

    FragColor = vec4(col, 1.0);
}
