# NMNotification

[![CI Status](http://img.shields.io/travis/nicolas@mahe.me/NMNotification.svg?style=flat)](https://travis-ci.org/nicolas@mahe.me/NMNotification)
[![Version](https://img.shields.io/cocoapods/v/NMNotification.svg?style=flat)](http://cocoapods.org/pods/NMNotification)
[![License](https://img.shields.io/cocoapods/l/NMNotification.svg?style=flat)](http://cocoapods.org/pods/NMNotification)
[![Platform](https://img.shields.io/cocoapods/p/NMNotification.svg?style=flat)](http://cocoapods.org/pods/NMNotification)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

NMNotification is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "NMNotification"
```

Then if you use the default `not activated popup`, please add those translation to your app and fell free to modify them:

```
notification.popup.not_authorized.title = "Notifications unauthorized";
notification.popup.not_authorized.message = "You need to authorize the notifications in Settings";
notification.popup.not_authorized.go_to_settings = "Go to Settings";
notification.popup.not_authorized.cancel = "Cancel";
```

## Author

Nicolas Mahé, nicolas@mahe.me

## License

NMNotification is available under the MIT license. See the LICENSE file for more info.
