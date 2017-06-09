Pod::Spec.new do |s|
  s.name             = 'NMNotification'
  s.version          = '0.0.5'
  s.summary          = 'Easier way to authorize and send notification'
  s.description      = <<-DESC
Easier API to manage Notification on iOS. Authorize and send notification.
                       DESC

  s.homepage         = 'https://github.com/NicolasMahe/NMNotification'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Nicolas Mahé' => 'nicolas@mahe.me' }
  s.source           = { :git => 'https://github.com/NicolasMahe/NMNotification.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'NMNotification/**/*.swift'

  s.frameworks = 'UIKit', 'UserNotifications'
  s.dependency 'PromiseKit', '~> 4.1'
  s.dependency 'NMLocalize'
end
