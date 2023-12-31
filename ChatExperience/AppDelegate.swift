//
//  AppDelegate.swift
//  DNDChat
//
//  Created by Karim on 11/6/23.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import FirebaseFirestore
import chatsModule
import AVKit
import DNDCorePackage
import Combine
@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
   
    var cancellables = Set<AnyCancellable>()
    var notification:UIView!
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
       
        
        let settings = Firestore.firestore().settings
        settings.isPersistenceEnabled = false
        Firestore.firestore().settings = settings
        print("ourToken1 \(Messaging.messaging().fcmToken)")
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
        }
        Messaging.messaging().token(completion: {token,error in
            let token = Messaging.messaging().fcmToken
            print("ourToken2 \(token)")
            if let token = token {
//                self.hitLoginAPI(with:token)
                
            }
        })
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        
        let session=AVAudioSession.sharedInstance()
        try? session.setCategory(.playback,mode: .moviePlayback)
        
        // Override point for customization after application launch.
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
            if let token = fcmToken {
//                refreshToken(with: token)
//                self.hitLoginAPI(with:token)
            }
        print("token \(fcmToken)")
    }
    func application(application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print("token register")
        Messaging.messaging().apnsToken = deviceToken as Data
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("token failed \(error)")
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("notifications \(userInfo)")
//        let content = UNMutableNotificationContent()
//        content.title = userInfo["senderName"] as! String
//        content.subtitle = userInfo["message"] as! String
//        content.sound = UNNotificationSound.default
//
//        // show this notification five seconds from now
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
//
//        // choose a random identifier
//        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//
//        // add our notification request
//        UNUserNotificationCenter.current().add(request)
        
        if(UserDefaults.standard.bool(forKey: "isForground")){
            if let root = UIApplication.topViewController() {
                if((userInfo["type"] as? String) == "Chat"){
                    showChatNotification(userInfo: userInfo, root: root)
                }else if((userInfo["type"] as? String) == "Call"){
                    if((userInfo["status"] as? String) == "0"){
                        let vc = UIStoryboard.ChatsModule.instantiateViewController(withIdentifier:AudioCallController.className) as! AudioCallController
                        
                        vc.setData(meetingId: userInfo["meetingId"] as! String,isCalling: false, recipientId: userInfo["callerId"] as! String, recipientName: userInfo["callerName"] as! String, recipientImage: userInfo["callerImage"] as! String, videoEnabled: (userInfo["videoEnabled"] as! String) == "true" , audioEnabled: (userInfo["audioEnabled"] as! String) == "true")
                        
                        root.present(vc)
                    }else if((userInfo["status"] as? String) == "-1"){
                        if(root is AudioCallController){
                            (root as! AudioCallController).incommingCallRejected()
                        }
                    }else if((userInfo["status"] as? String) == "1"){
                        if(root is AudioCallController){
                            (root as! AudioCallController).outgoingCallccepted()
                        }
                    }
                }
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                  didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo

        // ...

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)

        // Print full message.
        print("notifications \(userInfo)")
      }
    
}

