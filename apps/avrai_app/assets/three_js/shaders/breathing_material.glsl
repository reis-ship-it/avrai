// Breathing Material Shader
// For meditation knot visualization with breath-synchronized animation
// Part of 3D Visualization System

// ─────────────────────────────────────────────────────────────
// VERTEX SHADER
// ─────────────────────────────────────────────────────────────

#ifdef VERTEX_SHADER

uniform float uBreathPhase;      // 0-1 breath cycle
uniform float uStressLevel;      // 0-1 stress indicator
uniform float uTime;             // Animation time

varying vec3 vNormal;
varying vec3 vPosition;
varying float vBreathScale;

void main() {
    vNormal = normalize(normalMatrix * normal);
    vPosition = position;
    
    // Calculate breath scale (expands on inhale, contracts on exhale)
    float breathScale = 1.0 + 0.15 * sin(uBreathPhase * 3.14159);
    vBreathScale = breathScale;
    
    // Apply breath scaling
    vec3 pos = position * breathScale;
    
    // Add organic movement based on stress level
    // Higher stress = more turbulent movement
    float turbulence = uStressLevel * 0.1;
    pos += normal * sin(position.x * 5.0 + uTime * 2.0) * turbulence;
    pos += normal * sin(position.y * 4.0 + uTime * 1.5) * turbulence * 0.5;
    pos += normal * sin(position.z * 3.0 + uTime * 1.0) * turbulence * 0.3;
    
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#endif

// ─────────────────────────────────────────────────────────────
// FRAGMENT SHADER
// ─────────────────────────────────────────────────────────────

#ifdef FRAGMENT_SHADER

uniform vec3 uPrimaryColor;      // Main color
uniform vec3 uSecondaryColor;    // Accent color
uniform float uGlowIntensity;    // Emissive strength
uniform float uBreathPhase;      // 0-1 breath cycle
uniform float uTime;             // Animation time

varying vec3 vNormal;
varying vec3 vPosition;
varying float vBreathScale;

void main() {
    // Calculate view direction for fresnel
    vec3 viewDir = normalize(cameraPosition - vPosition);
    
    // Fresnel effect for edge glow
    float fresnel = pow(1.0 - max(dot(vNormal, viewDir), 0.0), 2.0);
    
    // Pulse glow with breath cycle
    float breathPulse = 0.5 + 0.5 * sin(uBreathPhase * 3.14159);
    float glowStrength = uGlowIntensity * (0.5 + breathPulse * 0.5);
    
    // Color gradient based on position
    float gradient = (vPosition.y + 2.0) / 4.0;
    vec3 baseColor = mix(uPrimaryColor, uSecondaryColor, gradient * 0.3);
    
    // Add fresnel glow
    vec3 glowColor = baseColor * glowStrength;
    vec3 finalColor = baseColor + glowColor * fresnel;
    
    // Add subtle color shift during exhale (calming)
    float exhaleBlend = 1.0 - breathPulse;
    vec3 calmColor = mix(baseColor, vec3(0.3, 0.4, 0.8), exhaleBlend * 0.2);
    finalColor = mix(finalColor, calmColor, exhaleBlend * 0.3);
    
    // Transparency based on fresnel
    float alpha = 0.8 + fresnel * 0.2;
    
    gl_FragColor = vec4(finalColor, alpha);
}

#endif
