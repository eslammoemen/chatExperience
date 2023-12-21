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
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var cancellables = Set<AnyCancellable>()
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        PublicFonts.Register()
        //        MOLH.shared.activate()
        //        MOLH.setLanguageTo("ar")
        //        MOLH.reset()
        //
        let repository = IntegrationRepo()
        let suit = IntegrationUsecase(repository: repository)
//        suit.createCall(params: ["type":"audio","users_id[]":"8"])
//        suit.addPeopleToCall(params: ["call_id":4,"users_id[]":10])
//        suit.getuser(with: 3)
//        suit.pushNotifications(with: ["user_id":3,"title":"dend","title_body":"dwf","body":["example1":"dafdf"]])
        //suit.chatsLogin(with: [:])
//        suit.chatsSearch(with: ["name":"ahmed"])
        Messaging.messaging().delegate = self
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
extension SceneDelegate:MessagingDelegate{
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//        if let token = fcmToken {
            //                refreshToken(with: token)
            self.hitLoginAPI(with:fcmToken ?? "someToken")
//        }
        print("token \(fcmToken)")
    }
}
import Alamofire
extension SceneDelegate {
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
        let httpBody:[String:Any] = ["email_or_mobile":"eslam@gmail.com","password":"123456","fcm_token":fcm,"device_type":"ios"]
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
            .tryMap { response throws -> authUseCase in
                print(String(data: response.data!, encoding: .utf8))
                let decoeed = try JSONDecoder().decode(staticApiResponse<userData>.self, from: response.data!)
                if let token = decoeed.data?.token {
                    CachceManager.shared.set(element: "Bearer \(token)", key: .authToken)
                }
                if let profile = decoeed.data?.user?.profile {
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

                return authUseCase(loginModel: decoeed.data?.user)
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

public struct authUseCase:Codable {
    public let id: Int?
    public let name, username, email: String?
    public let mobile, title, brief: String?
    public var image:String?
    init(loginModel:User?) {
        self.id = loginModel?.id
        self.name = loginModel?.name
        self.username = loginModel?.username
        self.email = loginModel?.email
        self.mobile = loginModel?.mobile
        self.title = loginModel?.title
        self.brief = loginModel?.brief
        self.image = loginModel?.profile
        //
    }
}


public struct userData: Codable {
    let token: String?
    let user: User?
}

// MARK: - User
struct User: Codable {
    let id: Int?
    let userType, name, username, email: String?
    let mobile, title, brief, deviceType: String?
    let fcmToken, gender, birthDate: String?
    let emailVerified, mobileVerified, accountVerified: Bool?
    let language: String?
    let following, followers: Int?
    let isMyAccount: Bool?
    let profile, cover: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userType = "user_type"
        case name, username, email, mobile, title, brief
        case deviceType = "device_type"
        case fcmToken = "fcm_token"
        case gender
        case birthDate = "birth_date"
        case emailVerified = "email_verified"
        case mobileVerified = "mobile_verified"
        case accountVerified = "account_verified"
        case language, following, followers
        case isMyAccount = "is_my_account"
        case profile, cover
    }
}
