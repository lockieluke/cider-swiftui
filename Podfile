source 'https://github.com/CocoaPods/Specs.git'

# Uncomment the next line to define a global platform for your project
platform :osx, '12.3'

# Disable all warnings from Pods
inhibit_all_warnings!

# Patch Plugin
plugin 'cocoapods-patch'

target 'Cider' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Cider
  pod 'SwiftyJSON', :git => 'https://github.com/SwiftyJSON/SwiftyJSON.git', :branch => 'master'
  pod 'Introspect'
  pod 'Starscream'
  pod 'SDWebImageSwiftUI'
  pod 'InjectHotReload'
  pod 'RainbowSwift'
  pod 'UIImageColors', :modular_headers => true
  pod 'Preferences', :git => 'https://github.com/ciderapp/Preferences.git', :branch => 'main'
end

target 'CiderPlaybackAgent' do
  # use_frameworks!
  # own private fork of Swifter
  pod 'Swifter', :git => 'https://github.com/ciderapp/swifter.git', :branch => 'stable'
  pod 'ArgumentParserKit'
  pod 'SwiftyJSON', :git => 'https://github.com/SwiftyJSON/SwiftyJSON.git', :branch => 'master'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '12.3'
    end
  end
end
