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
  pod 'Starscream', '~> 4.0.0'
  pod 'SDWebImageSwiftUI'
  pod 'InjectHotReload'
  pod 'RainbowSwift'
  pod 'UIImageColors', :modular_headers => true
  pod 'Preferences', :git => 'https://github.com/ciderapp/Preferences.git', :branch => 'main'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '12.3'
      end
    end
  end
end

target 'CiderPlaybackAgent' do
  # use_frameworks!
  # own private fork of Swifter
  pod 'Swifter', :git => 'https://github.com/ciderapp/swifter.git', :branch => 'stable'
  pod 'ArgumentParserKit'
  pod 'SwiftyJSON', '~> 4.0'
end
