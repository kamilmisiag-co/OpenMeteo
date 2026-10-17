//
//  RecordingNetworkObserver.swift
//  NetworkingMocks
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Networking
import Synchronization

public final class RecordingNetworkObserver: NetworkObserver {
    public enum Event: Hashable, Sendable {
        case willSend(URLRequest)
        case didReceive(statusCode: Int, URLRequest)
        case didFail(error: String, URLRequest)
    }

    private let recorded = Mutex<[Event]>([])

    public init() {}

    public var events: [Event] {
        recorded.withLock { $0 }
    }

    public func willSend(_ request: URLRequest) {
        recorded.withLock { $0.append(.willSend(request)) }
    }

    public func didReceive(_ response: HTTPResponse, for request: URLRequest) {
        recorded.withLock { $0.append(.didReceive(statusCode: response.statusCode, request)) }
    }

    public func didFail(with error: any Error, for request: URLRequest) {
        recorded.withLock { $0.append(.didFail(error: String(describing: error), request)) }
    }
}
