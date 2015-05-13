#
# Be sure to run `pod lib lint SPLPing.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SPLPing"
  s.version          = "1.1.3"
  s.summary          = "Lightweight, reusable and race free ping implementation."
  s.homepage         = "https://github.com/OliverLetterer/SPLPing"
  s.license          = 'MIT'
  s.author           = { "Oliver Letterer" => "oliver.letterer@gmail.com" }
  s.source           = { :git => "https://github.com/OliverLetterer/SPLPing.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/oletterer'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'SPLPing/*.{h,m}'
  s.private_header_files = 'SPLPing/ICMPHeader.h'

  s.frameworks = 'Foundation', 'CFNetwork'
end
