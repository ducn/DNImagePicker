Pod::Spec.new do |s|
  s.name = "DNImagePicker"
  s.version = "0.0.1"
  s.summary = "A replacement of UIImagePickerController with additional trim/crop video supported!"
  s.description = "Use DNImagePickerController when you want to pick user photo or video with trim/crop square video supported"
  s.homepage = "https://github.com/ducn/DNImagePicker"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "Duc Ngo" => "ngoduc.smpt@gmail.com" }
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.framework  = "UIKit"
  s.dependency 'ICGVideoTrimmer'
  s.source = { :git => "https://github.com/ducn/DNImagePicker.git", :tag => "#{s.version}" }
  s.source_files = "DNImagePicker/Classes", "DNImagePicker/Classes/*.swift", "DNImagePicker/Classes/**/*.swift"
#s.resources = "DNImagePicker/**/*.{png,jpeg,jpg,storyboard,xib}"
  s.resource_bundles = { 'DNImagePicker' => ['DNImagePicker/**/*.{png,jpeg,jpg,storyboard,xib}']}
end
