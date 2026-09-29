//
//  newStudyUnitTests.swift
//  newStudyUnitTests
//
//  Created by xp on 2026/8/10.
//

import Testing
@testable import newStudy

@MainActor
struct newStudyUnitTests {

    @Test func mqttMessageStoresTopicPayloadAndQoS() {
        let message = MQTTMessage(topic: "test/topic", payload: "hello", qos: 1)

        #expect(message.topic == "test/topic")
        #expect(message.payload == "hello")
        #expect(message.qos == 1)
       
    }

    @Test func mqttManagerDisconnectReportsStatus() {
        var lastStatus: String?
        MQTTManager.shared.onStatusChanged = { lastStatus = $0 }

        MQTTManager.shared.disconnect()

        #expect(lastStatus == "已断开连接")

        MQTTManager.shared.onStatusChanged = nil
        MQTTManager.shared.onMessageReceived = nil
    }

}
