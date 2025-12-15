//
//  ModelResponseEventsStreamInterpreterTests.swift
//  OpenAI
//
//  Created by Oleksii Nezhyborets on 10.04.2025.
//

import XCTest
@testable import OpenAI

@MainActor
final class ModelResponseEventsStreamInterpreterTests: XCTestCase {
    private let interpreter = ModelResponseEventsStreamInterpreter()

    func testParseApiError() async throws {
        let expectation = XCTestExpectation(description: "API Error callback received")
        var receivedError: Error?

        interpreter.setCallbackClosures { result in
            // This closure is for successful results, which we don't expect here
            XCTFail("Unexpected successful result received")
        } onError: { apiError in
            Task {
                await MainActor.run {
                    receivedError = apiError
                    expectation.fulfill() // Fulfill the expectation when the error is received
                }
            }
        }

        interpreter.processData(
            MockServerSentEvent.chatCompletionError()
        )

        // Wait for the expectation to be fulfilled, with a timeout
        await fulfillment(of: [expectation], timeout: 1.0)

        // Assert that an error was received and that it is of the expected type
        XCTAssertNotNil(receivedError, "Expected an error to be received, but got nil.")
        XCTAssertTrue(receivedError is APIErrorResponse, "Expected received error to be of type APIErrorResponse.")
    }

    func testParsesOutputTextDeltaUsingPayloadType() async throws {
        let expectation = XCTestExpectation(description: "OutputText delta event received")
        var receivedEvent: ResponseStreamEvent?

        interpreter.setCallbackClosures { event in
            Task {
                await MainActor.run {
                    receivedEvent = event
                    expectation.fulfill()
                }
            }
        } onError: { error in
            XCTFail("Unexpected error received: \(error)")
        }

        interpreter.processData(
            MockServerSentEvent.responseStreamEvent(
                itemId: "msg_1",
                payloadType: "response.output_text.delta",
                outputIndex: 0,
                contentIndex: 0,
                delta: "Hi",
                sequenceNumber: 1
            )
        )

        await fulfillment(of: [expectation], timeout: 1.0)

        guard let receivedEvent else {
            XCTFail("No event received")
            return
        }

        switch receivedEvent {
        case .outputText(.delta(let deltaEvent)):
            XCTAssertEqual(deltaEvent.itemId, "msg_1")
            XCTAssertEqual(deltaEvent.outputIndex, 0)
            XCTAssertEqual(deltaEvent.contentIndex, 0)
            XCTAssertEqual(deltaEvent.delta, "Hi")
            XCTAssertEqual(deltaEvent.sequenceNumber, 1)
        default:
            XCTFail("Expected .outputText(.delta), got \(receivedEvent)")
        }
    }

    func testParsesResponseIncompleteWithIncompleteDetails() async throws {
        let expectation = XCTestExpectation(description: "Response incomplete event received")
        var receivedEvent: ResponseStreamEvent?

        interpreter.setCallbackClosures { event in
            Task {
                await MainActor.run {
                    receivedEvent = event
                    expectation.fulfill()
                }
            }
        } onError: { error in
            XCTFail("Unexpected error received: \(error)")
        }

        interpreter.processData(
            MockServerSentEvent.responseIncompleteEvent(
                responseId: "resp_456",
                incompleteReason: "max_output_tokens",
                sequenceNumber: 2
            )
        )

        await fulfillment(of: [expectation], timeout: 1.0)

        guard let receivedEvent else {
            XCTFail("No event received")
            return
        }

        switch receivedEvent {
        case .incomplete(let incompleteDetails):
            XCTAssertNotNil(incompleteDetails, "Expected incompleteDetails to be non-nil")
            XCTAssertEqual(incompleteDetails?.reason, .maxOutputTokens, "Expected reason to be max_output_tokens")
        default:
            XCTFail("Expected .incomplete(IncompleteDetails), got \(receivedEvent)")
        }
    }

    func testParsesResponseIncompleteWithContentFilterReason() async throws {
        let expectation = XCTestExpectation(description: "Response incomplete event with content_filter reason received")
        var receivedEvent: ResponseStreamEvent?

        interpreter.setCallbackClosures { event in
            Task {
                await MainActor.run {
                    receivedEvent = event
                    expectation.fulfill()
                }
            }
        } onError: { error in
            XCTFail("Unexpected error received: \(error)")
        }

        interpreter.processData(
            MockServerSentEvent.responseIncompleteEvent(
                responseId: "resp_789",
                incompleteReason: "content_filter",
                sequenceNumber: 3
            )
        )

        await fulfillment(of: [expectation], timeout: 1.0)

        guard let receivedEvent else {
            XCTFail("No event received")
            return
        }

        switch receivedEvent {
        case .incomplete(let incompleteDetails):
            XCTAssertNotNil(incompleteDetails, "Expected incompleteDetails to be non-nil")
            XCTAssertEqual(incompleteDetails?.reason, .contentFilter, "Expected reason to be content_filter")
        default:
            XCTFail("Expected .incomplete(IncompleteDetails), got \(receivedEvent)")
        }
    }

    func testParsesResponseIncompleteWithNilIncompleteDetails() async throws {
        let expectation = XCTestExpectation(description: "Response incomplete event with nil incompleteDetails received")
        var receivedEvent: ResponseStreamEvent?

        interpreter.setCallbackClosures { event in
            Task {
                await MainActor.run {
                    receivedEvent = event
                    expectation.fulfill()
                }
            }
        } onError: { error in
            XCTFail("Unexpected error received: \(error)")
        }

        let json = """
        {"type":"response.incomplete","incomplete_details":null}
        """
        let data = "data: \(json)\n\n".data(using: .utf8)!
        interpreter.processData(data)

        await fulfillment(of: [expectation], timeout: 1.0)

        guard let receivedEvent else {
            XCTFail("No event received")
            return
        }

        switch receivedEvent {
        case .incomplete(let incompleteDetails):
            XCTAssertNil(incompleteDetails, "Expected incompleteDetails to be nil")
        default:
            XCTFail("Expected .incomplete(IncompleteDetails), got \(receivedEvent)")
        }
    }
}
