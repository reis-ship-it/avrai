Pod::Spec.new do |s|
  s.name             = 'knot_math'
  s.version          = '0.1.0'
  s.summary          = 'Rust knot_math library for Dart FFI (flutter_rust_bridge)'
  s.description      = <<-DESC
Provides the knot_math Rust implementation bundled for iOS as a static XCFramework.

This is required so iOS devices can run the app without attempting to load a
developer-machine dylib path at runtime.
  DESC

  s.homepage         = 'https://example.invalid/avrai/knot_math'
  s.license          = { :type => 'Proprietary', :text => 'Internal use' }
  s.author           = { 'AVRAI' => 'dev@avrai.invalid' }
  s.source           = { :path => '.' }

  s.platform         = :ios, '15.0'
  s.requires_arc     = false

  # Build the Rust static libs and package them into an XCFramework during `pod install`.
  # CocoaPods runs this from the pod's root directory (`native/knot_math`).
  s.prepare_command  = <<-CMD
    set -e
    bash ../../scripts/build_rust_ios_xcframework.sh
  CMD

  # The XCFramework output is created under `native/knot_math/ios/`.
  s.vendored_frameworks = 'ios/knot_math.xcframework'
  s.preserve_paths      = 'ios/knot_math.xcframework', 'ios/Headers'

  # CRITICAL:
  # Dart FFI (and flutter_rust_bridge) resolves symbols via dlsym at runtime.
  # With static libraries, the linker can dead-strip "unused" symbols unless
  # we force-load the library. We do this per SDK to avoid arch mismatch.
  s.user_target_xcconfig = {
    # NOTE:
    # These flags are applied to the *Runner* target, not the pod target, so we
    # must use variables available to the app build settings.
    #
    # `$(SRCROOT)` for Runner points to `ios/`, so this resolves to the repo's
    # `native/knot_math/` folder when building from the Flutter project.
    'OTHER_LDFLAGS[sdk=iphoneos*]' => '$(inherited) -Wl,-force_load,"$(SRCROOT)/../native/knot_math/ios/knot_math.xcframework/ios-arm64/libknot_math.a"',
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '$(inherited) -Wl,-force_load,"$(SRCROOT)/../native/knot_math/ios/knot_math.xcframework/ios-arm64_x86_64-simulator/libknot_math.a"',
  }
end

