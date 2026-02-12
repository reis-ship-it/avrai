Pod::Spec.new do |s|
  s.name             = 'SignalNative'
  s.version          = '0.1.0'
  s.summary          = 'SPOTS vendored Signal native XCFrameworks'
  s.description      = 'Vendored native libraries for Signal Protocol (libsignal-ffi) and SPOTS callback wrappers.'
  s.homepage         = 'https://avrai.app'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'avrai' => 'dev@avrai.app' }
  s.source           = { :path => '.' }

  s.platform         = :ios, '14.0'

  # These are produced in-repo (see native/signal_ffi build scripts).
  s.vendored_frameworks = [
    'Vendored/SignalFfi.xcframework',
    'Vendored/SignalFfiWrapper.xcframework',
  ]
end

