//
//  NetworkObserver.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

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
