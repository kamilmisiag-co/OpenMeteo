//
//  NetworkClient.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Utils

public struct NetworkClient: HTTPClient {
    private let requestBuilder: any RequestBuilding
    private let interceptors: [any RequestInterceptor]
    private let transport: any HTTPTransport
    private let validator: any ResponseValidating
    private let decoder: any ResponseDecoding
    private let retryPolicy: any RetryPolicy
    private let sleeper: any Sleeping
    private let observers: [any NetworkObserver]

    public init(
        requestBuilder: any RequestBuilding,
        interceptors: [any RequestInterceptor],
        transport: any HTTPTransport,
        validator: any ResponseValidating,
        decoder: any ResponseDecoding,
        retryPolicy: any RetryPolicy,
        sleeper: any Sleeping,
        observers: [any NetworkObserver]
    ) {
        self.requestBuilder = requestBuilder
        self.interceptors = interceptors
        self.transport = transport
        self.validator = validator
        self.decoder = decoder
        self.retryPolicy = retryPolicy
        self.sleeper = sleeper
        self.observers = observers
    }

    public func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        let baseRequest = try requestBuilder.makeRequest(for: endpoint)
        var retry = 1
        while true {
            try Task.checkCancellation()
            var attemptedRequest = baseRequest
            do {
                attemptedRequest = try await prepare(baseRequest)
                return try await perform(attemptedRequest, for: endpoint)
            } catch let error as NetworkError {
                guard let delay = retryPolicy.delay(beforeRetry: retry, of: attemptedRequest, after: error) else { throw error }
                try Task.checkCancellation()
                try await sleeper.sleep(for: delay)
                retry += 1
            }
        }
    }

    private func prepare(_ baseRequest: URLRequest) async throws -> URLRequest {
        do {
            return try await intercept(baseRequest)
        } catch {
            observers.forEach { $0.willSend(baseRequest) }
            observers.forEach { $0.didFail(with: error, for: baseRequest) }
            throw error
        }
    }

    private func intercept(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        for interceptor in interceptors {
            request = try await interceptor.intercept(request)
        }
        return request
    }

    private func perform<E: Endpoint>(_ request: URLRequest, for endpoint: E) async throws -> E.Response {
        observers.forEach { $0.willSend(request) }
        do {
            let response = try await transport.send(request)
            try validator.validate(response)
            let value = try endpoint.decode(response, using: decoder)
            observers.forEach { $0.didReceive(response, for: request) }
            return value
        } catch {
            observers.forEach { $0.didFail(with: error, for: request) }
            throw error
        }
    }
}
