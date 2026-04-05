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
    bash ../../../../work/scripts/build_rust_ios_xcframework.sh
  CMD

  # The XCFramework output is created under `native/knot_math/ios/`.
  s.vendored_frameworks = 'ios/knot_math.xcframework'
  s.preserve_paths      = 'ios/knot_math.xcframework', 'ios/Headers'

  # NOTE:
  # The XCFramework above is linked via CocoaPods directly.
  # Avoid explicit `-force_load` flags to prevent duplicate symbol collisions
  # when CocoaPods also stages an XCFramework intermediate copy.
end

