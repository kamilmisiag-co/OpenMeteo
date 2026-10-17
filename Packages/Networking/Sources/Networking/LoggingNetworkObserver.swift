//
//  LoggingNetworkObserver.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import OSLog
import Utils

public struct LoggingNetworkObserver: NetworkObserver {
    private let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func willSend(_ request: URLRequest) {
        logger.debug("\(request.httpMethod ?? "", privacy: .public) \(request.url?.path() ?? "", privacy: .public)")
    }

    public func didReceive(_ response: HTTPResponse, for request: URLRequest) {
        logger.debug("\(response.statusCode, privacy: .public) \(request.url?.path() ?? "", privacy: .public) \(response.body.count, privacy: .public) bytes")
    }

    public func didFail(with error: any Error, for request: URLRequest) {
        if error.isCancellation {
            logger.debug("\(request.url?.path() ?? "", privacy: .public) cancelled")
        } else if let networkError = error as? NetworkError, case .unacceptableStatusCode(let response) = networkError {
            logger.error("\(response.statusCode, privacy: .public) \(request.url?.path() ?? "", privacy: .public) \(response.body.count, privacy: .public) bytes")
        } else {
            logger.error("\(request.url?.path() ?? "", privacy: .public) \(String(describing: error), privacy: .private)")
        }
    }
}
