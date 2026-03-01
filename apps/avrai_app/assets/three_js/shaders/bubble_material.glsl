// Bubble Material Shader
// Glass bubble container for knot visualization with motion response
// Part of Motion-Reactive 3D Visualization System

// ─────────────────────────────────────────────────────────────
// VERTEX SHADER
// ─────────────────────────────────────────────────────────────

#ifdef VERTEX_SHADER

uniform float uTime;           // Animation time
uniform vec2 uTilt;            // Device tilt (x, y)
uniform float uRippleStrength; // Ripple intensity from motion

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vViewPosition;
varying vec2 vUv;

void main() {
    vNormal = normalize(normalMatrix * normal);
    vPosition = position;
    vUv = uv;
    
    // Apply subtle ripple effect from device motion
    vec3 pos = position;
    float ripple = sin(position.x * 10.0 + uTime * 2.0) * 
                   sin(position.y * 10.0 + uTime * 1.5) * 
                   uRippleStrength * 0.02;
    pos += normal * ripple;
    
    vec4 mvPosition = modelViewMatrix * vec4(pos, 1.0);
    vViewPosition = -mvPosition.xyz;
    
    gl_Position = projectionMatrix * mvPosition;
}

#endif

// ─────────────────────────────────────────────────────────────
// FRAGMENT SHADER
// ─────────────────────────────────────────────────────────────

#ifdef FRAGMENT_SHADER

uniform float uTime;           // Animation time
uniform float uOpacity;        // Base opacity
uniform float uFresnelPower;   // Fresnel edge brightness
uniform float uIridescence;    // Iridescence intensity
uniform float uRefraction;     // Refraction distortion strength
uniform vec3 uTintColor;       // Bubble tint color
uniform vec2 uTilt;            // Device tilt for parallax

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vViewPosition;
varying vec2 vUv;

// Rainbow color from angle (for iridescence)
vec3 iridescenceColor(float angle) {
    float r = sin(angle) * 0.5 + 0.5;
    float g = sin(angle + 2.094) * 0.5 + 0.5; // 2π/3
    float b = sin(angle + 4.189) * 0.5 + 0.5; // 4π/3
    return vec3(r, g, b);
}

void main() {
    // Calculate view direction
    vec3 viewDir = normalize(vViewPosition);
    vec3 normal = normalize(vNormal);
    
    // Fresnel effect - brighter at edges
    float fresnel = pow(1.0 - abs(dot(viewDir, normal)), uFresnelPower);
    
    // Iridescence - rainbow shift based on view angle
    float iridAngle = dot(viewDir, normal) * 6.28318 + uTime * 0.5;
    vec3 iridColor = iridescenceColor(iridAngle) * uIridescence;
    
    // Base bubble color with tint
    vec3 baseColor = uTintColor;
    
    // Combine colors
    vec3 finalColor = mix(baseColor, iridColor, fresnel * 0.5);
    finalColor += vec3(fresnel * 0.3); // Add white rim
    
    // Add subtle refraction distortion effect
    // This creates the glass-like visual
    float refractionOffset = sin(vUv.x * 20.0 + uTilt.x) * 
                             sin(vUv.y * 20.0 + uTilt.y) * 
                             uRefraction * 0.05;
    finalColor += vec3(refractionOffset);
    
    // Opacity: more transparent in center, opaque at edges
    float alpha = mix(uOpacity * 0.3, uOpacity, fresnel);
    
    // Add subtle pulsing
    alpha *= 0.9 + 0.1 * sin(uTime * 2.0);
    
    gl_FragColor = vec4(finalColor, alpha);
}

#endif
