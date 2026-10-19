//
//  LoggingNetworkObserver.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import OSLog
import Utils

public protocol NetworkObserver: Sendable {
    func willSend(_ request: URLRequest)
    func didReceive(_ response: HTTPResponse, for request: URLRequest)
    func didFail(with error: any Error, for request: URLRequest)
}

extension NetworkObserver {
    public func willSend(_ request: URLRequest) {}
    public func didReceive(_ response: HTTPResponse, for request: URLRequest) {}
    public func didFail(with error: any Error, for request: URLRequest) {}
}

public struct LoggingNetworkObserver: NetworkObserver {
    private let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func willSend(_ request: URLRequest) {
        logger.debug("\(request.httpMethod ?? "", privacy: .public) \(path(of: request), privacy: .public)")
    }

    public func didReceive(_ response: HTTPResponse, for request: URLRequest) {
        logger.debug("\(response.statusCode, privacy: .public) \(path(of: request), privacy: .public) \(response.body.count, privacy: .public) bytes")
    }

    public func didFail(with error: any Error, for request: URLRequest) {
        if error.isCancellation {
            logger.debug("\(path(of: request), privacy: .public) cancelled")
        } else if let networkError = error as? NetworkError, case .unacceptableStatusCode(let response) = networkError {
            logger.error("\(response.statusCode, privacy: .public) \(path(of: request), privacy: .public) \(response.body.count, privacy: .public) bytes")
        } else {
            logger.error("\(path(of: request), privacy: .public) \(String(describing: error), privacy: .private)")
        }
    }

    private func path(of request: URLRequest) -> String {
        request.url?.path() ?? ""
    }
}
