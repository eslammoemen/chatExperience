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
import Alamofire
import Kingfisher
import KingfisherWebP

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    var notificationTimer : Timer!
    var notificationRootController : UIViewController!
    var cancellables = Set<AnyCancellable>()
    var notification:UIView!
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        let modifier = AnyModifier { request in
            var req = request
            req.addValue("image/webp */*", forHTTPHeaderField: "Accept")
            return req
        }
        
        KingfisherManager.shared.defaultOptions += [
            .processor(WebPProcessor.default),
            .cacheSerializer(WebPSerializer.default),
            .requestModifier(modifier)
        ]
        
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
            refreshToken(with: token)
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
        print("notifications \(userInfo) \(UserDefaults.standard.bool(forKey: "isForground"))")
       
        if(UserDefaults.standard.bool(forKey: "isForground")){
            if let root = UIApplication.topViewController() {
                if((userInfo["type"] as? String) == "Chat"){
                    showChatNotification(userInfo: userInfo, root: root)
                }else if((userInfo["type"] as? String) == "Call"){
                    if((userInfo["state"] as? String) == "0"){
                        let vc = UIStoryboard.ChatsModule.instantiateViewController(withIdentifier:AudioCallController.className) as! AudioCallController
                        
                        let user:authUseCase! = CachceManager.shared.get(key: .user)
                        vc.setData(meetingId: userInfo["meetingId"] as! String, callerId: userInfo["callerId"] as! String, myId: "\(user.id!)", userIds: ["\(user.id!)",userInfo["callerId"] as! String], userNames: ["\(user.name!)",userInfo["callerName"] as! String], userImages: ["\(user.image!)",userInfo["callerImage"] as! String], videoEnabled: (userInfo["videoEnabled"] as! String) == "true", audioEnabled: (userInfo["audioEnabled"] as! String) == "true")
                        
                        root.present(vc)
                    }else if((userInfo["state"] as? String) == "-1"){
                        if(root is AudioCallController){
                            (root as! AudioCallController).incommingCallRejected()
                        }else if(root is AddPeopleToCall){
                            (root as! AddPeopleToCall).incommingCallRejected()
                        }
                    }else if((userInfo["state"] as? String) == "1"){
                        if(root is AudioCallController){
                            (root as! AudioCallController).outgoingCallccepted()
                        }else if(root is AddPeopleToCall){
                            (root as! AddPeopleToCall).outgoingCallccepted()
                        }
                    }
                }
            }
        }else{
            if((userInfo["type"] as? String) == "Call"){
                if let root = UIApplication.topViewController() {
                    if((userInfo["state"] as? String) == "0"){
                        let vc = UIStoryboard.ChatsModule.instantiateViewController(withIdentifier:AudioCallController.className) as! AudioCallController
                        
                        let user:authUseCase! = CachceManager.shared.get(key: .user)
                        vc.setData(meetingId: userInfo["meetingId"] as! String, callerId: userInfo["callerId"] as! String, myId: "\(user.id!)", userIds: ["\(user.id!)",userInfo["callerId"] as! String], userNames: ["\(user.name!)",userInfo["callerName"] as! String], userImages: ["\(user.image!)",userInfo["callerImage"] as! String], videoEnabled: (userInfo["videoEnabled"] as! String) == "true", audioEnabled: (userInfo["audioEnabled"] as! String) == "true")
                        
                        root.present(vc)
                }else if((userInfo["state"] as? String) == "-1"){
                    if(root is AudioCallController){
                        (root as! AudioCallController).incommingCallRejected()
                    }else if(root is AddPeopleToCall){
                        (root as! AddPeopleToCall).incommingCallRejected()
                    }
                }else if((userInfo["state"] as? String) == "1"){
                    if(root is AudioCallController){
                        (root as! AudioCallController).outgoingCallccepted()
                    }else if(root is AddPeopleToCall){
                        (root as! AddPeopleToCall).outgoingCallccepted()
                    }
                }
            }
        }
    }
}

func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse) async {
    let userInfo = response.notification.request.content.userInfo
    if let root = UIApplication.topViewController() {
        if((userInfo["type"] as? String) == "Chat"){
            let vc = UIStoryboard.ChatsModule.instantiateViewController(withIdentifier:ConversationController.className) as! ConversationController
            let user:authUseCase! = CachceManager.shared.get(key: .user)
            vc.setData(myId: "\(user.id!)", myName: user.name!, myImage: user.image!, recipientId: userInfo["senderId"] as! String, recipientName: userInfo["senderName"] as! String, recipientImage: userInfo["senderImage"] as! String)
            vc.modalPresentationStyle = .fullScreen
            if(root is ConversationController){
                root.dismiss(animated: false,completion: {
                    if let root = UIApplication.topViewController() {
                        root.present(vc, animated: true)
                    }
                })
            }else{
                root.present(vc,animated: true)
            }
        }
    }

    // ...
    
    // With swizzling disabled you must let Messaging know about the message, for Analytics
    // Messaging.messaging().appDidReceiveMessage(userInfo)
    
    // Print full message.
    print("notifications \(userInfo) \(UserDefaults.standard.bool(forKey: "isForground"))")
}

}

extension AppDelegate {
    func refreshToken(with fcm:String) {
        let url = URL(string: "https://deshanddez.com/api/auth/refresh_token")!
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        //        let httpBody:[String:Any] = ["email_or_mobile":"eslam@gmail.coms","password":"123456","fcm_token":fcm,"device_type":"ios"]
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let token:String? = CachceManager.shared.get(key: .authToken)
        
        request.setValue("Bearer \(token ?? "")", forHTTPHeaderField: "Authorization")
        //        guard let body = try? JSONSerialization.data(withJSONObject: httpBody, options: []) else {
        //            return
        //        }
        //
        //        request.httpBody = body
        AF.request(request)
            .validate()
            .publishData(queue: .global())
            .receive(on: RunLoop.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print(error)
                case .finished:
                    print("finished")
                }
            } receiveValue: { responseData in
                print(String(data: responseData.data!, encoding: .utf8))
            }.store(in: &cancellables)
        
    }
}
