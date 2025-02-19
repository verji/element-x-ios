//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct WaitlistScreenCoordinatorParameters {
    /// The credentials for the login.
    let credentials: WaitlistScreenCredentials
    /// The service used to authenticate the user.
    let authenticationService: AuthenticationServiceProtocol
    /// The service locator for the screen.
    var userIndicatorController: UserIndicatorControllerProtocol = ServiceLocator.shared.userIndicatorController
}

enum WaitlistScreenCoordinatorAction {
    /// Login was successful after a retry attempt.
    case signedIn(UserSessionProtocol)
    /// The user would like to try sign in another way.
    case cancel
}

final class WaitlistScreenCoordinator: CoordinatorProtocol {
    private let parameters: WaitlistScreenCoordinatorParameters
    private var viewModel: WaitlistScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<WaitlistScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private var refreshCancellable: AnyCancellable?
    
    var actions: AnyPublisher<WaitlistScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: WaitlistScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = WaitlistScreenViewModel(homeserver: parameters.credentials.homeserver)
        
        refreshCancellable = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.refresh()
            }
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .cancel:
                actionsSubject.send(.cancel)
            case .continue(let userSession):
                actionsSubject.send(.signedIn(userSession))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(WaitlistScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    /// Refresh the screen by retrying login to see if the waitlist has opened up.
    private func refresh() {
        guard parameters.credentials.homeserver == parameters.authenticationService.homeserver.value else {
            MXLog.warning("Homeserver configuration changed.")
            actionsSubject.send(.cancel)
            return
        }
        
        showRefreshIndicator()
        
        Task {
            switch await parameters.authenticationService.login(username: parameters.credentials.username,
                                                                password: parameters.credentials.password,
                                                                initialDeviceName: parameters.credentials.initialDeviceName,
                                                                deviceID: parameters.credentials.deviceID) {
            case .success(let userSession):
                hideRefreshIndicator()
                refreshCancellable = nil
                viewModel.update(userSession: userSession)
            case .failure(.isOnWaitlist):
                hideRefreshIndicator() // Nothing to do, still waiting for availability.
            case .failure(.invalidCredentials):
                hideRefreshIndicator()
                actionsSubject.send(.cancel)
            case .failure:
                hideRefreshIndicator()
                showFailureIndicator()
            }
        }
    }
    
    private static let refreshIndicatorID = "WaitlistCoordinatorRefresh"
    private static let failureIndicatorID = "WaitlistCoordinatorFailure"
    
    private func showRefreshIndicator() {
        parameters.userIndicatorController.submitIndicator(UserIndicator(id: Self.refreshIndicatorID,
                                                                         type: .modal,
                                                                         title: L10n.commonRefreshing,
                                                                         persistent: true))
    }
    
    private func hideRefreshIndicator() {
        parameters.userIndicatorController.retractIndicatorWithId(Self.refreshIndicatorID)
    }
    
    private func showFailureIndicator() {
        parameters.userIndicatorController.submitIndicator(UserIndicator(id: Self.failureIndicatorID,
                                                                         type: .toast,
                                                                         title: L10n.errorUnknown,
                                                                         iconName: "xmark"))
    }
}
