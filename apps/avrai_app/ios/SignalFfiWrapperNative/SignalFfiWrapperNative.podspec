Pod::Spec.new do |s|
  s.name             = 'SignalFfiWrapperNative'
  s.version          = '0.1.0'
  s.summary          = 'SPOTS vendored Signal Rust wrapper XCFramework'
  s.description      = 'Vendored Rust wrapper for libsignal-ffi store callbacks (Dart FFI).'
  s.homepage         = 'https://avrai.app'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'avrai' => 'dev@avrai.app' }
  s.source           = { :path => '.' }

  s.platform         = :ios, '14.0'

  s.vendored_frameworks = [
    'Vendored/SignalFfiWrapper.xcframework',
  ]
end

