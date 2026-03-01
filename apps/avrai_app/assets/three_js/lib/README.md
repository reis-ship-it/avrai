# Three.js Local Bundle

This directory contains a local bundle of Three.js v0.160.0 for offline support.

## Contents

- `three.module.js` - Core Three.js library
- `controls/OrbitControls.js` - Camera orbit controls
- `postprocessing/` - Post-processing effects
  - `EffectComposer.js` - Effect composer for multi-pass rendering
  - `RenderPass.js` - Basic render pass
  - `UnrealBloomPass.js` - Bloom/glow effect
  - `ShaderPass.js` - Generic shader pass
  - `Pass.js` - Base pass class
  - `CopyShader.js` - Simple copy shader
  - `LuminosityHighPassShader.js` - Luminosity extraction for bloom

## Why Local Bundle?

1. **Offline Support** - App works without internet connection
2. **Guaranteed Version** - No unexpected CDN changes
3. **Faster Loading** - No network latency after first load
4. **Privacy** - No external CDN requests

## Updating

To update Three.js, download new versions from unpkg.com:

```bash
# Core library
curl -o three.module.js "https://unpkg.com/three@VERSION/build/three.module.js"

# Addons (as needed)
curl -o controls/OrbitControls.js "https://unpkg.com/three@VERSION/examples/jsm/controls/OrbitControls.js"
curl -o postprocessing/EffectComposer.js "https://unpkg.com/three@VERSION/examples/jsm/postprocessing/EffectComposer.js"
# ... etc
```

## Version

Current version: **0.160.0** (January 2026)
