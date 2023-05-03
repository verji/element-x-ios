//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import SwiftUI

struct InviteUsersScreenCoordinatorParameters {
    let navigationStackCoordinator: NavigationStackCoordinator?
    let userSession: UserSessionProtocol
    let userDiscoveryService: UserDiscoveryServiceProtocol
    let createRoomParameters: CreateRoomVolatileParameters?
}

enum InviteUsersScreenCoordinatorAction {
    case close
}

final class InviteUsersScreenCoordinator: CoordinatorProtocol {
    private let parameters: InviteUsersScreenCoordinatorParameters
    private let viewModel: InviteUsersScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<InviteUsersScreenCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    var actions: AnyPublisher<InviteUsersScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: InviteUsersScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = InviteUsersScreenViewModel(userSession: parameters.userSession, userDiscoveryService: parameters.userDiscoveryService)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                
                self.actionsSubject.send(.close)
            case .proceed(let users):
                self.openCreateRoomScreenWith(users)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(InviteUsersScreen(context: viewModel.context))
    }
    
    private func openCreateRoomScreenWith(_ users: [UserProfile]) {
        guard let createRoomParameters = parameters.createRoomParameters else { return }
        createRoomParameters.selectedUsers = users
        let paramenters = CreateRoomCoordinatorParameters(userSession: parameters.userSession, createRoomParameters: createRoomParameters)
        let coordinator = CreateRoomCoordinator(parameters: paramenters)
        coordinator.actions.sink { [weak self] result in
            switch result {
            case .deselectUser(let user):
                self?.viewModel.context.send(viewAction: .deselectUser(user))
            default:
                break
            }
        }
        .store(in: &cancellables)
        parameters.navigationStackCoordinator?.push(coordinator)
    }
}
