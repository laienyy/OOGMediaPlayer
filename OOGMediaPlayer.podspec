
Pod::Spec.new do |spec|


  spec.name         = "OOGMediaPlayer"
  spec.version      = "1.0.41"
  spec.summary      = "A short description of OOGMediaPlayer."
  
  spec.description  = <<-DESC
  音频播放器
                   DESC

  spec.homepage     = "https://github.com/laienyy/OOGMediaPlayer"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "yy" => "yiyuan@laien.io" }
  spec.platform     = :ios, "15.0"
  spec.swift_versions = ['5']

  #  When using multiple platforms
  # spec.ios.deployment_target = "5.0"
  # spec.osx.deployment_target = "10.7"
  # spec.watchos.deployment_target = "2.0"
  # spec.tvos.deployment_target = "9.0"
  # spec.visionos.deployment_target = "1.0"

  spec.source       = { :git => "https://github.com/laienyy/OOGMediaPlayer.git", :tag => spec.version }
  
  spec.source_files  = "OOGMediaPlayer/Sources/**/*.swift", "OOGMediaPlayer/Sources/**/**/*.swift", "OOGMediaPlayer/Sources/**/**/**/*.swift"


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # spec.resource  = "icon.png"
  # spec.resources = "Resources/*.png"

  # spec.preserve_paths = "FilesToSave", "MoreFilesToSave"

  spec.framework  = "UIKit", "AVFoundation", "AVFAudio"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  # spec.requires_arc = true
  spec.module_name = "OOGMediaPlayer"

  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # spec.dependency "JSONKit", "~> 1.4"

end
