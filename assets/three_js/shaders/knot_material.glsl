// Knot Material Shader
// For standard knot visualization with invariant-based coloring
// Part of 3D Visualization System

// ─────────────────────────────────────────────────────────────
// VERTEX SHADER
// ─────────────────────────────────────────────────────────────

#ifdef VERTEX_SHADER

uniform float uTime;
uniform float uWrithe;           // Knot writhe value
uniform float uCrossingNumber;   // Knot crossing number

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying float vTubeProgress;     // 0-1 along tube length

void main() {
    vNormal = normalize(normalMatrix * normal);
    vPosition = position;
    vWorldPosition = (modelMatrix * vec4(position, 1.0)).xyz;
    
    // Calculate progress along tube (for color gradient)
    // This is an approximation based on position
    vTubeProgress = fract((position.x + position.y + position.z) * 0.1 + 0.5);
    
    // Apply subtle animation based on writhe
    vec3 pos = position;
    float writheEffect = uWrithe * 0.01;
    pos += normal * sin(uTime * 2.0 + vTubeProgress * 6.28318) * writheEffect;
    
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#endif

// ─────────────────────────────────────────────────────────────
// FRAGMENT SHADER
// ─────────────────────────────────────────────────────────────

#ifdef FRAGMENT_SHADER

uniform vec3 uPrimaryColor;
uniform vec3 uSecondaryColor;
uniform float uMetalness;
uniform float uRoughness;
uniform float uEmissiveIntensity;
uniform float uTime;
uniform float uWrithe;
uniform float uSignature;

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying float vTubeProgress;

// Simple lighting calculation
vec3 calculateLighting(vec3 normal, vec3 viewDir, vec3 baseColor) {
    // Key light
    vec3 lightDir = normalize(vec3(5.0, 5.0, 5.0));
    float diff = max(dot(normal, lightDir), 0.0);
    
    // Specular (Blinn-Phong)
    vec3 halfDir = normalize(lightDir + viewDir);
    float spec = pow(max(dot(normal, halfDir), 0.0), 32.0 * (1.0 - uRoughness));
    
    // Fresnel
    float fresnel = pow(1.0 - max(dot(normal, viewDir), 0.0), 5.0);
    fresnel = mix(0.04, 1.0, fresnel) * uMetalness;
    
    // Combine
    vec3 ambient = baseColor * 0.2;
    vec3 diffuse = baseColor * diff * 0.7;
    vec3 specular = vec3(1.0) * spec * 0.3 * (uMetalness + 0.1);
    vec3 fresnelColor = baseColor * fresnel * 0.3;
    
    return ambient + diffuse + specular + fresnelColor;
}

void main() {
    vec3 viewDir = normalize(cameraPosition - vWorldPosition);
    
    // Color gradient based on tube progress and invariants
    float colorMix = vTubeProgress;
    
    // Writhe affects color distribution
    float writheInfluence = abs(uWrithe) * 0.1;
    colorMix = colorMix * (1.0 + writheInfluence * sin(vTubeProgress * 6.28318 * 3.0));
    colorMix = fract(colorMix);
    
    // Signature affects overall hue shift
    float hueShift = uSignature * 0.05;
    
    // Base color with gradient
    vec3 baseColor = mix(uPrimaryColor, uSecondaryColor, colorMix * writheInfluence);
    
    // Apply hue shift based on signature
    // Simple RGB rotation approximation
    float cosH = cos(hueShift);
    float sinH = sin(hueShift);
    mat3 hueMatrix = mat3(
        0.299 + 0.701*cosH + 0.168*sinH,
        0.587 - 0.587*cosH + 0.330*sinH,
        0.114 - 0.114*cosH - 0.497*sinH,
        0.299 - 0.299*cosH - 0.328*sinH,
        0.587 + 0.413*cosH + 0.035*sinH,
        0.114 - 0.114*cosH + 0.292*sinH,
        0.299 - 0.300*cosH + 1.250*sinH,
        0.587 - 0.588*cosH - 1.050*sinH,
        0.114 + 0.886*cosH - 0.203*sinH
    );
    baseColor = hueMatrix * baseColor;
    
    // Calculate lighting
    vec3 litColor = calculateLighting(vNormal, viewDir, baseColor);
    
    // Add emissive glow
    float fresnelGlow = pow(1.0 - max(dot(vNormal, viewDir), 0.0), 3.0);
    vec3 emissive = baseColor * uEmissiveIntensity * fresnelGlow;
    
    vec3 finalColor = litColor + emissive;
    
    gl_FragColor = vec4(finalColor, 1.0);
}

#endif
