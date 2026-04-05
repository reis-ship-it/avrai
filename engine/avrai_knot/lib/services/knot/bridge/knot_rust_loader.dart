import 'dart:io' as io;
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import 'knot_math_bridge.dart/frb_generated.dart';

/// Provides the correct `ExternalLibrary` strategy per platform.
///
/// On **iOS**, Rust is expected to be **statically linked** (`.a`) into the app.
/// In that case, the correct way to access symbols is `DynamicLibrary.process()`,
/// exposed here as `ExternalLibrary.process()`.
///
/// If iOS static linking is not configured yet, initialization should still
/// succeed, but calling Rust symbols will fail later (and callers should
/// fall back accordingly).
const kIsWeb = identical(0, 0.0);

Future<void> initKnotRustLib() async {
  // Web uses the web backend (not dart:ffi).
  if (kIsWeb) {
    await RustLib.init();
    return;
  }

  if (!kIsWeb && io.Platform.isIOS) {
    await RustLib.init(
      externalLibrary: ExternalLibrary.process(iKnowHowToUseIt: true),
    );
    return;
  }

  // Android/macOS/Windows/Linux: fall back to generated default loader config.
  // (If needed, we can later specialize this for Android `.so` names or desktop
  // bundling paths.)
  await RustLib.init();
}
