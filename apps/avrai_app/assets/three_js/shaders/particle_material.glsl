// Particle Material Shader
// For particle systems in birth experience and ambient effects
// Part of 3D Visualization System

// ─────────────────────────────────────────────────────────────
// VERTEX SHADER
// ─────────────────────────────────────────────────────────────

#ifdef VERTEX_SHADER

attribute float size;
attribute vec3 customColor;

uniform float uTime;
uniform float uPixelRatio;
uniform float uSizeMultiplier;

varying vec3 vColor;
varying float vOpacity;

void main() {
    vColor = customColor;
    
    // Calculate distance-based size
    vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
    float distanceFactor = 300.0 / -mvPosition.z;
    
    // Pulsing size based on time
    float pulse = 1.0 + 0.1 * sin(uTime * 3.0 + position.x * 10.0);
    
    gl_PointSize = size * uPixelRatio * distanceFactor * uSizeMultiplier * pulse;
    gl_Position = projectionMatrix * mvPosition;
    
    // Opacity based on distance (fade distant particles)
    vOpacity = clamp(1.0 - (-mvPosition.z / 20.0), 0.0, 1.0);
}

#endif

// ─────────────────────────────────────────────────────────────
// FRAGMENT SHADER
// ─────────────────────────────────────────────────────────────

#ifdef FRAGMENT_SHADER

varying vec3 vColor;
varying float vOpacity;

void main() {
    // Soft circular particle with glow falloff
    float dist = length(gl_PointCoord - vec2(0.5));
    
    if (dist > 0.5) discard;
    
    // Soft edge with glow
    float alpha = 1.0 - smoothstep(0.0, 0.5, dist);
    float glow = exp(-dist * 4.0);
    
    // Combine base alpha with glow
    float finalAlpha = alpha * vOpacity * 0.8 + glow * 0.2;
    
    // Brighten center
    vec3 finalColor = vColor + vec3(1.0) * glow * 0.5;
    
    gl_FragColor = vec4(finalColor, finalAlpha);
}

#endif
