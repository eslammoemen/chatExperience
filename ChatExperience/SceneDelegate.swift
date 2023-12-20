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

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        PublicFonts.Register()
        //        MOLH.shared.activate()
        //        MOLH.setLanguageTo("ar")
        //        MOLH.reset()
        //
        let repository = IntegrationRepo()
        let suit = IntegrationUsecase(repository: repository)
//        suit.getuser(with: 3)
//        suit.pushNotifications(with: ["user_id":3,"title":"dend","title_body":"dwf","body":["example1":"dafdf"]])
        //suit.chatsLogin(with: [:])
//        suit.chatsSearch(with: ["name":"ahmed"])
        IQKeyboardManager.shared.enable = true
        window?.backgroundColor = .white
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        let controller = UINavigationController(rootViewController:chatsFactory().chatsController())
        controller.setNavigationBarHidden(true, animated: true)
        window?.rootViewController = controller
        window?.makeKeyAndVisible()
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
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}
import Alamofire
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
    func hitLoginAPI(with fcm:String) {
        let url = URL(string: "https://deshanddez.com/api/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        let httpBody:[String:Any] = ["email_or_mobile":"user@gmail.com","password":"123456789","fcm_token":fcm,"device_type":"ios"]
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("en", forHTTPHeaderField: "Accept-Language")
        request.setValue("ios", forHTTPHeaderField: "Accept-Platform")
        guard let body = try? JSONSerialization.data(withJSONObject: httpBody, options: []) else {
            return
        }
        //
        request.httpBody = body
        AF.request(request)
            .validate()
            .publishData(queue: .global())
            .tryMap { response throws -> [String:Any]? in
                let jsonObj = try JSONSerialization.jsonObject(with: response.data!) as? [String:Any]
                return jsonObj
            }
            .receive(on: RunLoop.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print(error)
                case .finished:
                    print("finished")
                }
            } receiveValue: { responseData in
                let data = responseData?["data"] as? [String:Any]
                if let token = data?["token"] as? String {
                    CachceManager().set(element: "Bearer \(token)", key: .authToken)
                }
//                print(String(data: responseData, encoding: .utf8))
            }.store(in: &cancellables)
    }
}
