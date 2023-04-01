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
  pod 'SwiftyJSON'
  pod 'Introspect'
  pod 'Starscream'
  pod 'SDWebImageSwiftUI'
  pod 'InjectHotReload'
  pod 'RainbowSwift'
  pod 'Watchdog'
  pod 'Alamofire'
  pod 'WrappingHStack'
  pod 'UIImageColors', :modular_headers => true
  # Pods installed with coke, run `coke install` first
  pod "Preferences", :path => '.coke/pods/sindresorhus/Preferences'
  pod "SwiftUISliders", :path => '.coke/pods/spacenation/swiftui-sliders'
  pod "Throttler", :path => '.coke/pods/boraseoksoon/Throttler'
  pod "AttributedText", :path => '.coke/pods/Iaenhaall/AttributedText'
  pod "Defaults", :path => '.coke/pods/sindresorhus/Defaults'

  # Firebase
  pod 'FirebaseAuth'
  pod 'FirebaseFirestore'
  pod 'FirebaseAnalytics'
end

target 'CiderPlaybackAgent' do
  # own private fork of Swifter
  pod 'Swifter'
  pod 'ArgumentParserKit'
  pod 'SwiftyJSON'
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '12.3'
      config.build_settings['SWIFT_VERSION'] = '5'
      config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
      config.build_settings.delete 'ARCHS'
    end
  end


  Dir["**/*.xcodeproj"].select { |project_path| !project_path.to_s.start_with?('Pods') }.each do |project_path|
    proj = Xcodeproj::Project.open project_path
    proj.targets.each do |target|
      if target.name == "CiderPlaybackAgent"
        target.build_configurations.each do |config|
          config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
        end
      end
    end
  end
end
