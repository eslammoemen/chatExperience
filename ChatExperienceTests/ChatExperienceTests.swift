//
//  ChatExperienceTests.swift
//  ChatExperienceTests
//
//  Created by Eslam Mohamed on 17/12/2023.
//

import XCTest
@testable import chatsModule

final class ChatExperienceTests: XCTestCase {
    var repository:IntegrationRepoProtocol!
    var suit:IntegrationUsecaseProtocol!

    override func setUpWithError() throws {
       repository = IntegrationRepo()
        suit = IntegrationUsecase(repository: repository)
        suit.delegate = self
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
       let userSettigs = suit.getuser(with: 3)
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testDidRecieveChatUserModel(model:chatUserUseCase) {
        XCTAssertNotNil(model.about)
    }

}
extension ChatExperienceTests :IntegrationUsecaseDelegateProtocol {
    func didRecieveChatUserModel(model: chatsModule.chatUserUseCase) {
       testDidRecieveChatUserModel(model: model)
    }
    
    
}
