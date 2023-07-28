Pod::Spec.new do |s|
  s.name             = 'ThenDynamicLaunch'
  s.version          = '0.0.1'
  s.summary          = 'Modify launch image and manager.'

  s.description      = <<-DESC
fork with LLDynamicLaunchScreen(https://github.com/internetWei/LLDynamicLaunchScreen)
                       DESC

  s.homepage         = 'https://github.com/ghostcrying/ThenDynamicLaunch'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.author           = { 'ghost' => 'czios1501@gmail.com' }
  s.source           = { :git => 'https://github.com/ghostcrying/ThenDynamicLaunch.git', :tag => s.version.to_s }
  
  s.platform      = :ios, "11.0"
  s.swift_version = "5.0"

  s.source_files = 'Sources/**/*.swift'
  s.frameworks   = 'Foundation', 'UIKit'
  
end

