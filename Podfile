platform :ios, '15.0'
workspace 'ChatExperience.xcworkspace'
project 'ChatExperience.xcodeproj'

use_frameworks!

def _resource
  pod 'R.swift','~> 5.1.0'
  end


def _corePackage
  pod 'KRProgressHUD'
  pod 'NotificationBannerSwift'
  end

def _CorePods
  _resource
  _corePackage
  pod 'IQKeyboardManagerSwift'
  pod "KingfisherWebP"
  pod "BSImagePicker", "~> 3.1"
  pod 'KDCircularProgress'
  pod 'VideoSDKRTC', '~> 2.0.13'
  pod 'Alamofire'
  pod 'PIPKit'
  pod 'CryptoSwift', '~> 1.8.0'
  pod 'SwiftyJSON', '~> 4.0'
  pod 'UIPiPView', :git => 'https://github.com/uakihir0/UIPiPView/', :branch => 'main'
  end
target 'ChatExperience' do
  # Comment the next line if you don't want to use dynamic frameworks
  
  _CorePods
  pod 'Alamofire'
  pod 'CropViewController'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
	if target.name == 'R.swift.Library' ||
	   target.name == 'NotificationBannerSwift' ||
	   target.name == 'SwiftyJSON' ||
	   target.name == 'PIPKit' ||
           target.name == 'CropViewController'
       	   config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
      	end
        
    end
  end
end

  end

target 'chatsModule' do
  project 'chatsModule/chatsModule.project'
  _CorePods
  end

target 'DNDCorePackage' do
  project 'DNDCorePackage/DNDCorePackage.project'
  _corePackage
  
  end

target 'DNDResources' do
  project 'DNDResources/DNDResources.project'
  _resource
  
  end
target 'NetworkLayer' do
  project 'NetworkLayer/NetworkLayer.project'
   pod 'Alamofire'
 end

target 'PhotoLibraryMedia' do
  
  project 'PhotoLibraryMedia/PhotoLibraryMedia.project'
  pod 'CropViewController'
  _resource
  _corePackage
  
end
