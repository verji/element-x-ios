//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

class ServerConfirmationScreenViewStateTests: XCTestCase {
    func testLoginMessageString() {
        let matrixDotOrgLogin = ServerConfirmationScreenViewState(homeserverAddress: LoginHomeserver.mockMatrixDotOrg.address,
                                                                  authenticationFlow: .login)
        XCTAssertEqual(matrixDotOrgLogin.message, L10n.screenServerConfirmationMessageLoginMatrixDotOrg, "matrix.org should have a custom message.")
        
        let elementDotIoLogin = ServerConfirmationScreenViewState(homeserverAddress: "element.io",
                                                                  authenticationFlow: .login)
        XCTAssertEqual(elementDotIoLogin.message, L10n.screenServerConfirmationMessageLoginElementDotIo, "element.io should have a custom message.")
        
        let otherLogin = ServerConfirmationScreenViewState(homeserverAddress: LoginHomeserver.mockOIDC.address,
                                                           authenticationFlow: .login)
        XCTAssertTrue(otherLogin.message.isEmpty, "Other servers should not show a message.")
    }
    
    func testRegisterMessageString() {
        let matrixDotOrgLogin = ServerConfirmationScreenViewState(homeserverAddress: LoginHomeserver.mockMatrixDotOrg.address,
                                                                  authenticationFlow: .register)
        XCTAssertEqual(matrixDotOrgLogin.message, L10n.screenServerConfirmationMessageRegister, "The registration message should always be the same.")
        
        let otherLogin = ServerConfirmationScreenViewState(homeserverAddress: LoginHomeserver.mockOIDC.address,
                                                           authenticationFlow: .register)
        XCTAssertEqual(otherLogin.message, L10n.screenServerConfirmationMessageRegister, "The registration message should always be the same.")
    }
}
