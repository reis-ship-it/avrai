// Formation Material Shader
// For knot materialization effect during birth experience
// Part of 3D Visualization System

// ─────────────────────────────────────────────────────────────
// VERTEX SHADER
// ─────────────────────────────────────────────────────────────

#ifdef VERTEX_SHADER

uniform float uProgress;         // 0-1 formation progress
uniform float uTime;             // Animation time

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying float vFormationProgress;

void main() {
    vNormal = normalize(normalMatrix * normal);
    vPosition = position;
    vWorldPosition = (modelMatrix * vec4(position, 1.0)).xyz;
    
    // Calculate local formation progress based on position
    // Formation sweeps from one end to other
    float localT = (position.x + 3.0) / 6.0; // Normalize position to 0-1
    vFormationProgress = smoothstep(localT - 0.1, localT + 0.1, uProgress);
    
    // Scale down unformed parts
    vec3 pos = position;
    if (vFormationProgress < 0.01) {
        pos *= 0.0;
    } else {
        // Add slight wobble as it forms
        float wobble = (1.0 - vFormationProgress) * 0.1;
        pos += normal * sin(uTime * 10.0 + position.y * 5.0) * wobble;
    }
    
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#endif

// ─────────────────────────────────────────────────────────────
// FRAGMENT SHADER
// ─────────────────────────────────────────────────────────────

#ifdef FRAGMENT_SHADER

uniform vec3 uPrimaryColor;
uniform vec3 uSecondaryColor;
uniform float uEmissiveIntensity;
uniform float uProgress;
uniform float uTime;

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying float vFormationProgress;

void main() {
    if (vFormationProgress < 0.01) discard;
    
    // Calculate view direction
    vec3 viewDir = normalize(cameraPosition - vWorldPosition);
    
    // Fresnel for edge effect
    float fresnel = pow(1.0 - max(dot(vNormal, viewDir), 0.0), 2.0);
    
    // Color gradient
    float gradient = (vPosition.y + 2.0) / 4.0;
    vec3 baseColor = mix(uPrimaryColor, uSecondaryColor, gradient * 0.3);
    
    // Formation edge glow
    float edgePosition = (vPosition.x + 3.0) / 6.0;
    float edgeDistance = abs(edgePosition - uProgress);
    float edgeGlow = exp(-edgeDistance * 30.0) * 2.0;
    
    // Emissive based on formation state
    float emissive = uEmissiveIntensity * (fresnel * 0.5 + edgeGlow);
    
    // Transition from pure white (just formed) to final color
    float colorTransition = smoothstep(0.0, 0.3, vFormationProgress);
    vec3 formingColor = mix(vec3(1.0), baseColor, colorTransition);
    
    // Add glow
    vec3 finalColor = formingColor + formingColor * emissive;
    
    // Opacity increases as formation completes
    float alpha = vFormationProgress;
    
    gl_FragColor = vec4(finalColor, alpha);
}

#endif
