//
// Copyright 2024 New Vector Ltd
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

import MatrixRustSDK
import XCTest

@testable import ElementX

class SDKMessageMock: MatrixRustSDK.Message {
    init() {
        super.init(noPointer: NoPointer())
    }
    
    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError()
    }
    
    override func isThreaded() -> Bool {
        false
    }
    
    override func msgtype() -> MessageType {
        .text(content: .init(body: "Test", formatted: nil))
    }
    
    override func inReplyTo() -> InReplyToDetails? {
        nil
    }
    
    override func isEdited() -> Bool {
        false
    }
}

let messageMock = SDKMessageMock() // Crashes in the destructor

class SDKTimelineItemContent: MatrixRustSDK.TimelineItemContent {
    init() {
        super.init(noPointer: NoPointer())
    }
    
    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError()
    }
    
    override func kind() -> TimelineItemContentKind {
        .message
    }
    
    override func asMessage() -> Message? {
        let messageMock = messageMock
        
        // swiflint:disable:next force_cast
        return messageMock
    }
}

@MainActor
class RoomTimelineItemFactoryTests: XCTestCase {
    let timelineItemFactory = RoomTimelineItemFactory(userID: "@me:mock.net",
                                                      attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: ServiceLocator.shared.settings.permalinkBaseURL,
                                                                                                       mentionBuilder: MentionBuilder()),
                                                      stateEventStringBuilder: RoomStateEventStringBuilder(userID: "@me.mock.net"))
    
    func testFactory() {
        let eventTimelineItem = SDKEventTimelineItemMock()
        setupEvent(eventTimelineItem)
        
        eventTimelineItem.contentReturnValue = SDKTimelineItemContent()
        
        let eventTimelineItemProxy = EventTimelineItemProxy(item: eventTimelineItem, id: 1)
        
        let item = timelineItemFactory.buildTimelineItem(for: eventTimelineItemProxy, isDM: false)
        
        XCTAssertNotNil(item)
        XCTAssertTrue(item is TextRoomTimelineItem)
    }
    
    // MARK: - Private
    
    private func setupEvent(_ event: SDKEventTimelineItemMock) {
        event.isOwnReturnValue = true
        event.timestampReturnValue = 1
        event.isEditableReturnValue = false
        event.canBeRepliedToReturnValue = false
        event.senderProfileReturnValue = .ready(displayName: "Test", displayNameAmbiguous: false, avatarUrl: nil)
        event.senderReturnValue = "@test:mock.net"
        event.reactionsReturnValue = []
        event.readReceiptsReturnValue = [:]
    }
}
