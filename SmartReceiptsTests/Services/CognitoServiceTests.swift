//
//  CognitoServiceTests.swift
//  SmartReceiptsTests
//
//  Created by Bogdan Evsenev on 24/09/2017.
//  Copyright © 2017 Will Baumann. All rights reserved.
//

@testable import SmartReceipts
import XCTest
import RxSwift
import RxBlocking

fileprivate let TIME_OUT: RxTimeInterval = 10

class CognitoServiceTests: XCTestCase {
    let service = CognitoService()
    let authSerivce = AuthService.shared
    let bag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        _ = try? authSerivce.login(credentials: TEST_CREDENTIALS)
            .toBlocking(timeout: TIME_OUT)
            .single()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCognitoUserSync() {
        let user = try! authSerivce.getUser()
            .toBlocking(timeout: TIME_OUT)
            .single()!
        
        let token = service.token().result
        let identityId = service.identityId
        
        XCTAssertNotNil(token)
        XCTAssertNotNil(user)
        XCTAssertTrue(token!.isEqual(to: user.cognitoToken!))
        XCTAssertEqual(identityId, user.identityId)
    }
    
    func testCognitoTokenUnauth() {
        _ = try? authSerivce.logout().toBlocking(timeout: TIME_OUT).single()
        let token = service.token().result
        let identityId = service.identityId
        
        XCTAssertNil(token)
        XCTAssertNil(identityId)
    }
}
