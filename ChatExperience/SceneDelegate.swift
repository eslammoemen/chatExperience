//
//  SceneDelegate.swift
//  ChatExperience
//
//  Created by Eslam Mohamed on 17/12/2023.
//

import UIKit
import DNDResources
import IQKeyboardManagerSwift
import chatsModule
import Combine
import DNDCorePackage
import NetworkLayer
import FirebaseMessaging
import FirebaseFirestore
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var cancellables = Set<AnyCancellable>()
    var user:authUseCase!
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        PublicFonts.Register()
        //        MOLH.shared.activate()
        //        MOLH.setLanguageTo("ar")
        //        MOLH.reset()
        //
        let repository = IntegrationRepo()
        let suit = IntegrationUsecase(repository: repository)
//        suit.updateUserSettings(params: ["notifications":1,"last_seen":1,"profile_photo":1,"about":1,"calls":1,"groups":1,"status":1])
//       suit.createCall(params: ["type":"audio","users_id[]":"8"])
//        suit.addPeopleToCall(params: ["call_id":4,"users_id[]":10])
//        suit.getuser(with: 3)
//        suit.pushNotifications(with: ["user_id":3,"title":"dend","title_body":"dwf","body":["example1":"dafdf"]])
        //suit.chatsLogin(with: [:])
        //        suit.chatsSearch(with: ["name":"ahmed"])
        
       // hitLoginAPI(with: "someToken simulator")
        suit.report(params: ["name":"test","explain":"test"])
        //
        Messaging.messaging().delegate = self
        IQKeyboardManager.shared.enable = true
        window?.backgroundColor = .white
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        let controller = UINavigationController(rootViewController:chatsFactory().chatsController())
        controller.setNavigationBarHidden(true, animated: true)
        window?.rootViewController = controller
        window?.makeKeyAndVisible()
        
       // self.hitLoginAPI(with:"someToken")
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        UserDefaults.standard.set(true, forKey: "isForground")
        let userSettings:updateUserSettingUseCase? = CachceManager.shared.get(key: .chatUserSettings)
        
        if let myUser=user,let mySettings=userSettings{
            if(mySettings.toJSON()["status"] as! Bool && mySettings.toJSON()["isOnline"] as! Bool){
                let doc = Firestore.firestore().collection("Users").document("\(myUser.id!)")
                doc.setData(["isOnline":true,"activeStatus":mySettings.toJSON()["status"] as! Bool])
            }
        }
        
//        if let root = UIApplication.topViewController() {
//            if(root is ConversationController){
//                (root as! ConversationController).isForground(flag: true)
//            }
//        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        UserDefaults.standard.set(false, forKey: "isForground")
        let userSettings:updateUserSettingUseCase? = CachceManager.shared.get(key: .chatUserSettings)
        user = CachceManager.shared.get(key: .user)
        if let myUser=user,let mySettings=userSettings{
            if(mySettings.toJSON()["status"] as! Bool && mySettings.toJSON()["isOnline"] as! Bool){
                let doc = Firestore.firestore().collection("Users").document("\(myUser.id!)")
                doc.setData(["isOnline":false,"activeStatus":mySettings.toJSON()["status"] as! Bool])
            }
        }
//        if let root = UIApplication.topViewController() {
//            print(root is ConversationController)
//            if(root is ConversationController){
//                (root as! ConversationController).isForground(flag: false)
//            }
//        }
    }


}
extension SceneDelegate:MessagingDelegate{
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//        if let token = fcmToken {
            //                refreshToken(with: token)
        if !CachceManager.shared.isAuthSaved {
            print("ourToken6 \(fcmToken)")
            
        }
        hitLoginAPI(with:fcmToken ?? "someToken")
//        }
        print("ourToken6 \(fcmToken)")
    }
}
import Alamofire
extension SceneDelegate {
    func hitLoginAPI(with fcm:String) {
        let url = URL(string: "https://deshanddez.com/api/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        let httpBody:[String:Any] = ["email_or_mobile":"saadzayed@gmail.com","password":"123456","fcm_token":fcm,"device_type":"ios"]
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("en", forHTTPHeaderField: "Accept-Language")
        request.setValue("ios", forHTTPHeaderField: "Accept-Platform")
        guard let body = try? JSONSerialization.data(withJSONObject: httpBody, options: []) else {
            return
        }
        //
        print("ourToken login start")
        request.httpBody = body
        AF.request(request)
            .validate()
            .publishData(queue: .global())
            .tryMap { response throws -> authUseCase in
                print("ourToken \(String(data: response.data!, encoding: .utf8))")
                let decoeed = try JSONDecoder().decode(staticApiResponse<userData>.self, from: response.data!) as staticApiResponse<userData>
                
                if let token = decoeed.data?.token {
                    CachceManager.shared.set(element: "Bearer \(token)", key: .authToken)
                }
                if let videoToken = decoeed.data?.video_token {
                    CachceManager.shared.set(element: videoToken, key: .videoToken)
                }
                if let profile = decoeed.data?.loginUser?.profile {
                    DispatchQueue.global().async {
                        do {
                            let imageData = try Data(contentsOf: URL(string: profile)!)
                            DispatchQueue.main.async {
                                UserDefaults.standard.set(imageData, forKey: "##UserImage")
                            }
                        }catch {
                            
                        }
                        
                    }
                }

                return authUseCase(loginModel:decoeed.data?.loginUser)
            }
            .receive(on: RunLoop.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print(error)
                case .finished:
                    print("finished")
                }
            } receiveValue: { usermodel in
                print(usermodel)
                if let id = usermodel.id {
                    CachceManager.shared.set(element: usermodel, key: .user)
                }
            }.store(in: &cancellables)
    }
}
