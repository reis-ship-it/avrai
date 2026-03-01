// Portal World Shader
// Procedural infinite world with sensor fusion input

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uCameraRotation; // Quaternion (x, y, z, w)
uniform float uDayCycle;      // 0.0 = Night, 1.0 = Day

out vec4 fragColor;

// Constants
const float PI = 3.14159265359;

// Noise Functions
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 0.0;
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(st);
        st *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// 3D Rotation using Quaternion
vec3 rotateVector(vec3 v, vec4 q) {
    // Standard quaternion rotation: v' = q * v * q^-1
    // Simplified GLSL version
    vec3 t = 2.0 * cross(q.xyz, v);
    return v + q.w * t + cross(q.xyz, t);
}

// Raycasting Plane (Ground)
float rayPlane(vec3 ro, vec3 rd, float planeHeight) {
    // Intersect ray with plane y = planeHeight
    // P = ro + t * rd
    // P.y = planeHeight
    // ro.y + t * rd.y = planeHeight
    // t = (planeHeight - ro.y) / rd.y
    if (rd.y >= 0.0) return -1.0; // Ray pointing up/parallel
    return (planeHeight - ro.y) / rd.y;
}

// Main Render Loop
void main() {
    vec2 uv = gl_FragCoord.xy / uResolution.xy;
    vec2 p = (2.0 * gl_FragCoord.xy - uResolution.xy) / min(uResolution.x, uResolution.y);

    // Camera Setup (Sensor Fusion)
    vec3 ro = vec3(0.0, 0.5, 0.0); // Camera Origin (0.5m off ground)
    vec3 rd = normalize(vec3(p.x, p.y, -1.5)); // Base ray direction (looking forward -Z)

    // Apply Sensor Rotation
    // Note: Sensors usually give rotation of device relative to world.
    // We want the view to match device.
    rd = rotateVector(rd, uCameraRotation);

    vec3 col = vec3(0.0);

    // Sky or Ground?
    if (rd.y > 0.0) {
        // SKY RENDER
        // Simple Gradient for now
        vec3 skyTopDay = vec3(0.2, 0.5, 0.9);
        vec3 skyHorizonDay = vec3(0.7, 0.8, 0.9);
        vec3 skyTopNight = vec3(0.05, 0.05, 0.15);
        vec3 skyHorizonNight = vec3(0.1, 0.1, 0.25);

        vec3 skyTop = mix(skyTopNight, skyTopDay, uDayCycle);
        vec3 skyHorizon = mix(skyHorizonNight, skyHorizonDay, uDayCycle);

        // Gradient based on vertical angle
        float skyGradient = pow(1.0 - rd.y, 2.0);
        col = mix(skyTop, skyHorizon, skyGradient);

        // Clouds (FBM)
        vec2 cloudUV = rd.xz / (rd.y + 0.1) * 2.0; // Planar projection on sky dome
        cloudUV += vec2(uTime * 0.05, uTime * 0.02); // Wind
        float clouds = fbm(cloudUV);
        
        vec3 cloudColor = mix(vec3(0.8), vec3(1.0), uDayCycle);
        float cloudAlpha = smoothstep(0.4, 0.8, clouds);
        
        col = mix(col, cloudColor, cloudAlpha * 0.7 * (1.0 - smoothstep(0.0, 0.2, rd.y))); // Fade at horizon

        // Sun/Moon?
        // Assume Sun at East (X+)
        vec3 sunDir = normalize(vec3(1.0, 0.2, 0.0));
        float sunDot = max(dot(rd, sunDir), 0.0);
        
        // Sun glow
        col += vec3(1.0, 0.9, 0.6) * pow(sunDot, 500.0) * uDayCycle; // Sharp Sun
        col += vec3(1.0, 0.6, 0.3) * pow(sunDot, 20.0) * 0.5 * uDayCycle; // Glow

    } else {
        // GROUND RENDER
        float t = rayPlane(ro, rd, 0.0);
        if (t > 0.0) {
            vec3 pos = ro + rd * t;
            
            // Grass Texture (Noise)
            vec2 grassUV = pos.xz * 5.0; // Tiling
            // Wind wave
            grassUV += vec2(sin(uTime + pos.x) * 0.1, cos(uTime + pos.z) * 0.1);
            
            float grassNoise = fbm(grassUV);
            
            vec3 grassColorDay = vec3(0.1, 0.6, 0.1);
            vec3 grassColorNight = vec3(0.02, 0.1, 0.05);
            vec3 grassColor = mix(grassColorNight, grassColorDay, uDayCycle);
            
            // Variation
            grassColor *= (0.5 + 0.5 * grassNoise);
            
            // Atmospheric Fog (Distance)
            float dist = length(pos - ro);
            float fogFactor = 1.0 - exp(-dist * 0.1);
            
            vec3 horizonColor = mix(vec3(0.1, 0.1, 0.25), vec3(0.7, 0.8, 0.9), uDayCycle);
            col = mix(grassColor, horizonColor, fogFactor);
        }
    }

    // Output
    fragColor = vec4(col, 1.0);
}
