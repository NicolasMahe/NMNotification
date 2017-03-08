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

public enum NMNotificationError: Error {
  case notAuthorized
}

public class NMNotification: NSObject {
  
  public static var notActivated: (UIViewController?) -> Void = { (controller: UIViewController?) -> Void in
    let alert = UIAlertController(
      title: L("notification.popup.not_authorized.title"),
      message: L("notification.popup.not_authorized.message"),
      preferredStyle: UIAlertControllerStyle.alert
    )
    alert.addAction(
      UIAlertAction(
        title: L("notification.popup.not_authorized.go_to_settings"),
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
        title: L("notification.popup.not_authorized.cancel"),
        style: UIAlertActionStyle.cancel,
        handler: nil
      )
    )
    controller?.present(alert, animated: true, completion: nil)
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
        return Promise(error: NMNotificationError.notAuthorized)
      }
    }
  }
  
  //----------------------------------------------------------------------------
  // MARK: - Authorize notification
  //----------------------------------------------------------------------------
  
  public class func authorize(
    fromController: UIViewController? = nil,
    enableRemoteNotification: Bool = false
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
            self.notActivated(fromController)
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
  }
  
  public class func receiveRemoteNotification(_ userInfo: [AnyHashable : Any]?) {
  }
  
  //----------------------------------------------------------------------------
  // MARK: - Schedule notif
  //----------------------------------------------------------------------------
  
  public class func scheduleNotification(
    title: String,
    body: String,
    identifier: String
  ) -> Promise<Void> {
    //check if authorized
    return self.isAuthorized(forRemoteNotification: false)
      .then {
        if #available(iOS 10.0, *) {
          return Promise<Void> { (fulfill, reject) in
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
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
  
}
