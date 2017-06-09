//
//  NMNotification.swift
//  Nicolas Mahe
//
//  Created by Nicolas Mahé on 11/10/2016.
//  Copyright © 2016 Nicolas Mahé. All rights reserved.
//

import UIKit
import UserNotifications
import PromiseKit
import NMLocalize

//@todo: improve popup by adding a reject with a specific error

public enum NMNotificationError: Error {
  case notDetermined
  case notAuthorized
}

public class NMNotification: NSObject {
  
  //----------------------------------------------------------------------------
  // MARK: - Properties
  //----------------------------------------------------------------------------
  
  public static var willAuthorize: (_ fromController: UIViewController?) -> Promise<Void> = { (_) in
    return Promise(value: ())
  }
  public static var didAuthorize: ((_ deviceToken: String, _ deviceTokenData: Data) -> Void)?
  public static var didReceiveRemoteNotification: ((_ userInfo: [AnyHashable : Any]?) -> Void)?
  
  //----------------------------------------------------------------------------
  // MARK: - Not Activated default popup
  //----------------------------------------------------------------------------
  
  public static var refuseAuthorization: (UIViewController?) -> Void = { (controller: UIViewController?) -> Void in
    let alert = UIAlertController(
      title: L("notification.popup.refuse_authorization.title"),
      message: L("notification.popup.refuse_authorization.message"),
      preferredStyle: UIAlertControllerStyle.alert
    )
    alert.addAction(
      UIAlertAction(
        title: L("notification.popup.refuse_authorization.go_to_settings"),
        style: UIAlertActionStyle.default,
        handler: { (alertAction: UIAlertAction) in
          if let url = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(url)
          }
      }
      )
    )
    alert.addAction(
      UIAlertAction(
        title: L("notification.popup.refuse_authorization.cancel"),
        style: UIAlertActionStyle.cancel,
        handler: nil
      )
    )
    controller?.present(alert, animated: true, completion: nil)
  }
  
  
  //----------------------------------------------------------------------------
  // MARK: - Refresh the remote notification token
  //----------------------------------------------------------------------------
  
  public class func refreshRemoteToken() {
    let _ = self.isAuthorized(forRemoteNotification: true)
      .then { () -> Void in
        let _ = self.authorize(
          fromController: nil,
          enableRemoteNotification: true
        )
      }
      .catch { (error: Error) in
        print("error refresh remote token. reason: \(error)")
    }
  }
  
  //----------------------------------------------------------------------------
  // MARK: - Check if the notification has been ask
  //----------------------------------------------------------------------------
  
  public class func isAuthorized(forRemoteNotification: Bool) -> Promise<Void> {
    if #available(iOS 10.0, *) {
      return Promise<Void> { (fulfill, reject) in
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
          if settings.authorizationStatus == .authorized {
            fulfill()
          }
          else if settings.authorizationStatus == .notDetermined {
            reject(NMNotificationError.notDetermined)
          }
          else {
            reject(NMNotificationError.notAuthorized)
          }
        }
      }
    }
    else {
      if forRemoteNotification == true,
        UIApplication.shared.isRegisteredForRemoteNotifications == true {
        return Promise(value: ())
      }
      else {
        return Promise(error: NMNotificationError.notDetermined)
      }
    }
  }
  
  //----------------------------------------------------------------------------
  // MARK: - Authorize notification
  //----------------------------------------------------------------------------
  
  public class func authorize(
    fromController: UIViewController?,
    enableRemoteNotification: Bool
  ) -> Promise<Void> {
    return self.isAuthorized(forRemoteNotification: enableRemoteNotification)
      .recover { [weak fromController] (error: Error) -> Promise<Void> in
        return self.willAuthorize(fromController)
      }
      .then {
        return self._authorize(
          enableRemoteNotification: enableRemoteNotification
        )
      }
      .catch { [weak fromController] (error: Error) in
        print("error: \(error)")
        self.refuseAuthorization(fromController)
    }
  }
  
  private class func _authorize(
    enableRemoteNotification: Bool
  ) -> Promise<Void> {
    return Promise<Void> { (fulfill, reject) in
      if #available(iOS 10.0, *) {
        let authOptions : UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions)
        { (granted: Bool, errorD: Error?) -> Void in
          if granted {
            if enableRemoteNotification == true {
              UIApplication.shared.registerForRemoteNotifications()
            }
            
            fulfill()
          }
          else {
            reject(NMNotificationError.notAuthorized)
          }
        }
      }
      else {
        let settings = UIUserNotificationSettings(
          types: [
            UIUserNotificationType.alert,
            UIUserNotificationType.badge,
            UIUserNotificationType.sound
          ],
          categories: nil
        )
        UIApplication.shared.registerUserNotificationSettings(settings)
        if enableRemoteNotification == true {
          UIApplication.shared.registerForRemoteNotifications()
        }
        
        fulfill()
      }
    }
  }
  
  //----------------------------------------------------------------------------
  // MARK: - Delegate fron AppDelegate
  //----------------------------------------------------------------------------
  
  public class func didAuthorize(deviceToken: Data) {
    // Print it to console
    let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
    print("APNs device token: \(deviceTokenString)")
    
    self.didAuthorize?(deviceTokenString, deviceToken)
  }
  
  public class func didFailToAuthorize(error: Error) {
    print("Registration failed!")
    print(error)
  }
  
  public class func didReceiveRemoteNotification(_ userInfo: [AnyHashable : Any]?) {
    print("notification received")
    self.didReceiveRemoteNotification?(userInfo)
  }
  
  //----------------------------------------------------------------------------
  // MARK: - Schedule notif
  //----------------------------------------------------------------------------
  
  public class func scheduleNotification(
    title: String?,
    body: String,
    identifier: String,
    badge: Int?
  ) -> Promise<Void> {
    //check if authorized
    return self.isAuthorized(forRemoteNotification: false)
      .then {
        if #available(iOS 10.0, *) {
          return Promise<Void> { (fulfill, reject) in
            let content = UNMutableNotificationContent()
            if let title = title {
              content.title = title
            }
            content.body = body
            if let badge = badge {
              content.badge = NSNumber(value: badge)
            }
            //        content.sound = UNNotificationSound.default()
            
//            let date = date
//            let triggerDate = Calendar.current.dateComponents(
//              [.year,.month,.day,.hour,.minute,.second],
//              from: date
//            )
//            let trigger = UNCalendarNotificationTrigger(
//              dateMatching: triggerDate,
//              repeats: false
//            )
            
            let trigger = UNTimeIntervalNotificationTrigger(
              timeInterval: 1,
              repeats: false
            )
            
            let identifier = identifier
            let request = UNNotificationRequest(
              identifier: identifier,
              content: content,
              trigger: trigger
            )
            UNUserNotificationCenter.current().add(request) { (error) in
              if let error = error {
                return reject(error)
              }
              fulfill()
            }
          }
        }
        else {
          let notification = UILocalNotification()
          notification.alertTitle = title
          notification.alertBody = body
//          notification.fireDate = date
          UIApplication.shared.scheduleLocalNotification(notification)
          
          return Promise(value: ())
        }
    }
  }
  
  //----------------------------------------------------------------------------
  // MARK: - Badge
  //----------------------------------------------------------------------------
  
  public class func resetBadge() {
    UIApplication.shared.applicationIconBadgeNumber = 0
  }
  
  
}
