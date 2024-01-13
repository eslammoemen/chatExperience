//
//  AppDelegateChatExtension.swift
//  ChatExperience
//
//  Created by Karim on 12/31/23.
//
import Foundation
import UIKit
import FirebaseCore
import FirebaseMessaging
import FirebaseFirestore
import chatsModule
import DNDResources
import AVKit
import DNDCorePackage
import Combine
extension AppDelegate{
    func showChatNotification(userInfo: [AnyHashable : Any],root:UIViewController){
        notificationRootController = root
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        if(notification != nil){
            notificationTimer.invalidate()
            notification.layer.removeAllAnimations()
            notification.removeFromSuperview()
        }
        notification = UIView(frame: CGRect(x: 16, y: -(statusBarHeight + 86), width: root.view.frame.width-32, height: 70))
        notification.backgroundColor = .white
        notification.cornerRadius = 20
        
        let image = UIImageView(frame: CGRect(x: 16, y: 10, width: 50, height: 50))
        image.cornerRadius = 25
        image.kf.setImage(with: URL(string: userInfo["senderImage"] as! String))
        
        let name = UILabel(frame: CGRect(x: 82, y: 10, width: 200, height: 20))
        name.textColor = .black
        name.font = name.font.withSize(14)
        var recipientName = userInfo["senderName"] as! String
        if(recipientName.count>20){
            let index = recipientName.index(recipientName.startIndex, offsetBy: 20)
            recipientName = String(recipientName.prefix(upTo: index))
        }
        name.text = recipientName
        
        let messageIcon = UIImageView(frame: CGRect(x: 82, y: 30, width: 16, height: 16))
        var messageText = ""
        var messageX = 82
        
        let type = Int(userInfo["messageType"] as! String)
        if(type == 2){
            messageText="Image"
            messageIcon.image = R.image.vector()
            messageIcon.setImageColor(color: UIColor.black)
            messageX = 102
        }else if(type == 3){
            messageText="Video"
            messageIcon.image = R.image.video()
            messageIcon.setImageColor(color: UIColor.black)
            messageX = 102
        }else if(type == 4){
            messageText="Audio"
            messageIcon.image = R.image.mic_on()
            messageIcon.setImageColor(color: UIColor.black)
            messageX = 102
        }
        
        let date = UILabel(frame: CGRect(x: root.view.frame.width - 80, y: 10, width: 70, height: 20))
        date.font = date.font.withSize(16)
        date.textColor = .black
        date.numberOfLines = 1
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "hh:mm a"
        date.text = dateFormatterPrint.string(from: Date())
        
        
        let message = UILabel(frame: CGRect(x: messageX, y: 27, width: 200, height: 20))
        message.font = message.font.withSize(14)
        message.textColor = .black
        message.text = (userInfo["message"] as? String)!.count > 0 ? userInfo["message"] as? String : messageText
        message.numberOfLines = 1
        message.lineBreakMode = .byTruncatingTail
        if(type!>1){
            notification.addSubview(messageIcon)
        }
        notification.addSubview(message)
        notification.addSubview(name)
        notification.addSubview(image)
        root.view.addSubview(notification)
        
        UIView.animate(withDuration: 0.7, animations: { [self] in
            notification.frame = CGRect(x: 16, y: statusBarHeight + 16, width: root.view.frame.width-32, height: 70)
        })
        notificationTimer = Timer.scheduledTimer(timeInterval: 3.7, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        
        let tap = NotificationGestureRecognizer(target: self, action: #selector(self.tapOnNotification(_:)))
        tap.userInfo = userInfo
        tap.vc = root
        notification.addGestureRecognizer(tap)
        
    }
    @objc func fireTimer() {
        UIView.animate(withDuration: 0.7, animations: { [self] in
            notification.frame = CGRect(x: 16, y: -70, width: notificationRootController.view.frame.width-32, height: 70)
        })
    }
    
    @objc func tapOnNotification(_ sender: NotificationGestureRecognizer){
        print("here")
        let userInfo = sender.userInfo
        if((userInfo!["type"] as! String) == "Chat"){
            let vc = UIStoryboard.ChatsModule.instantiateViewController(withIdentifier:ConversationController.className) as! ConversationController
            let user:authUseCase! = CachceManager.shared.get(key: .user)
            vc.setData(myId: "\(user.id!)", myName: user.name!, myImage: user.image!, recipientId: userInfo!["senderId"] as! String, recipientName: userInfo!["senderName"] as! String, recipientImage: userInfo!["senderImage"] as! String)
            vc.modalPresentationStyle = .fullScreen
            if(sender.vc is ConversationController){
                sender.vc.dismiss(animated: false,completion: {
                    if let root = UIApplication.topViewController() {
                        root.present(vc, animated: true)
                    }
                })
            }else{
                sender.vc.present(vc,animated: true)
            }
            notification.removeFromSuperview()
        }
    }
    
    func handleCallNotification(userInfo: [AnyHashable : Any],root:UIViewController){
        if((userInfo["state"] as? String) == "0"){
            let user:authUseCase? = CachceManager.shared.get(key: .user)
            print(UserDefaults.standard.bool(forKey: "isInAnotherCall"))
            if(UserDefaults.standard.bool(forKey: "isInAnotherCall")){
                let notificationsData = AcceptRejectCallNotificationsData(recipientId: userInfo["callerId"] as? String, state: -1, type: "Call",meetingId: userInfo["meetingId"] as? String,callType: ((userInfo["videoEnabled"] as! String) == "true") ? "video" : "audio",reason: (user?.name!)!+" is in another call")
                let data = try? JSONEncoder().encode(notificationsData).toJSON()
                suit.pushNotifications(with: [
                    "user_id":Int(userInfo["callerId"] as! String)!,
                    "body":data!
                ])
            }else{
                let vc = UIStoryboard.ChatsModule.instantiateViewController(withIdentifier:AudioCallController.className) as! AudioCallController
                
                let user:authUseCase! = CachceManager.shared.get(key: .user)
                vc.setData(meetingId: userInfo["meetingId"] as! String, callerId: userInfo["callerId"] as! String, myId: "\(user.id!)", userIds: ["\(user.id!)",userInfo["callerId"] as! String], userNames: ["\(user.name!)",userInfo["callerName"] as! String], userImages: ["\(user.image!)",userInfo["callerImage"] as! String], videoEnabled: (userInfo["videoEnabled"] as! String) == "true", audioEnabled: (userInfo["audioEnabled"] as! String) == "true")
                
                root.present(vc)
            }
        }else if((userInfo["state"] as? String) == "-1"){
            if(root is AudioCallController){
                (root as! AudioCallController).incommingCallRejected(reason: userInfo["reason"] as! String)
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

class NotificationGestureRecognizer:UITapGestureRecognizer{
    var userInfo:[AnyHashable : Any]!
    var vc:UIViewController!

}

