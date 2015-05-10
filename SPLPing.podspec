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
  s.version          = "0.1.0"
  s.summary          = "A short description of SPLPing."
  s.homepage         = "https://github.com/OliverLetterer/SPLPing"
  s.license          = 'MIT'
  s.author           = { "Oliver Letterer" => "oliver.letterer@gmail.com" }
  s.source           = { :git => "https://github.com/OliverLetterer/SPLPing.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/oletterer'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'SPLPing'
  # s.resource_bundles = {
  #   'SPLPing' => [ 'SPLPing/Resources/*' ]
  # }

  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
