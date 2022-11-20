source 'https://github.com/CocoaPods/Specs.git'

# Uncomment the next line to define a global platform for your project
platform :osx, '12.3'

target 'Cider' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Cider
  pod 'SwiftyJSON', '~> 4.0'
  pod 'Introspect'
  # pod 'SwiftHTTP', :git => 'https://github.com/rahul-racha/SwiftHTTP.git', :branch => 'issue-305'
  pod 'SDWebImageSwiftUI'
  pod 'InjectHotReload'
end

target 'CiderPlaybackAgent' do
  # use_frameworks!
  pod "GCDWebServer", "~> 3.0", :modular_headers => true
  pod 'Swifter', '~> 1.5.0'
  pod 'ArgumentParserKit'
end
