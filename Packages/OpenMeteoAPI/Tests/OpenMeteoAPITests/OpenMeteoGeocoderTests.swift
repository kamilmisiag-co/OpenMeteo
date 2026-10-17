//
//  OpenMeteoGeocoderTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import Networking
import NetworkingMocks
import OpenMeteoAPI
import Synchronization
import Testing
import Utils

@Suite("Open-Meteo geocoder")
struct OpenMeteoGeocoderTests {
    private final class RecordingGeocodingRequests: GeocodingRequestMaking {
        private let received = Mutex<[String]>([])
        private let endpoint: GeocodingEndpoint

        init(endpoint: GeocodingEndpoint) {
            self.endpoint = endpoint
        }

        var receivedNames: [String] {
            received.withLock { $0 }
        }

        func request(forName name: String) -> GeocodingEndpoint {
            received.withLock { $0.append(name) }
            return endpoint
        }
    }

    private final class RecordingCityMapper: CityMapping {
        private let rejectedIDs: Set<Int>
        private let received = Mutex<[GeocodingResultDTO]>([])

        init(rejecting rejectedIDs: Set<Int> = []) {
            self.rejectedIDs = rejectedIDs
        }

        var receivedResults: [GeocodingResultDTO] {
            received.withLock { $0 }
        }

        func city(from result: GeocodingResultDTO) -> City? {
            received.withLock { $0.append(result) }
            return rejectedIDs.contains(result.id) ? nil : Self.city(for: result)
        }

        static func city(for result: GeocodingResultDTO) -> City {
            City(
                id: result.id, name: "Stubbed \(result.name)", region: nil, country: "Stubland", countryCode: nil,
                latitude: result.latitude, longitude: result.longitude, timeZoneIdentifier: nil
            )
        }
    }

    private static let factoryEndpoint = GeocodingEndpoint(name: "Lisboa", resultLimit: 37, languageCode: "pt")

    @Test(
        "The searched name goes to the injected request factory and the client sends exactly the request it made",
        arguments: ["Lisbon", "São Paulo", ""]
    )
    func requestFromFactory(name: String) async throws {
        let requests = RecordingGeocodingRequests(endpoint: Self.factoryEndpoint)
        let client = try Self.client(returning: .geocodingNoMatches)
        _ = try await geocoder(client: client, requests: requests, mapper: RecordingCityMapper()).cities(named: name)

        #expect(requests.receivedNames == [name])
        let endpoints = await client.endpoints
        #expect(endpoints.count == 1)
        let sent = try #require(endpoints.first as? GeocodingEndpoint)
        #expect(sent.name == Self.factoryEndpoint.name)
        #expect(sent.resultLimit == Self.factoryEndpoint.resultLimit)
        #expect(sent.languageCode == Self.factoryEndpoint.languageCode)
        #expect(sent.queryItems == Self.factoryEndpoint.queryItems)
    }

    @Test("Each search asks the injected request factory for a new request")
    func requestPerSearch() async throws {
        let requests = RecordingGeocodingRequests(endpoint: Self.factoryEndpoint)
        let client = try Self.client(returning: .geocodingNoMatches)
        let subject = geocoder(client: client, requests: requests, mapper: RecordingCityMapper())
        _ = try await subject.cities(named: "Lisbon")
        _ = try await subject.cities(named: "Porto")

        #expect(requests.receivedNames == ["Lisbon", "Porto"])
        #expect(await client.endpoints.count == 2)
    }

    @Test("Every result goes through the injected mapper and the cities keep the API order")
    func injectedMapper() async throws {
        let response = try Fixtures.decode(GeocodingResponseDTO.self, from: .geocodingLisbon)
        let client = try Self.client(returning: .geocodingLisbon)
        let mapper = RecordingCityMapper()
        let cities = try await geocoder(client: client, mapper: mapper).cities(named: "Lisbon")

        #expect(mapper.receivedResults == response.results)
        #expect(mapper.receivedResults.map(\.id) == Fixtures.geocodedLisbonCities.map(\.id))
        #expect(cities == response.results.map(RecordingCityMapper.city(for:)))
    }

    @Test("Results the injected mapper rejects are dropped and the remaining cities keep the API order")
    func rejectedResultsDropped() async throws {
        let response = try Fixtures.decode(GeocodingResponseDTO.self, from: .geocodingLisbon)
        let client = try Self.client(returning: .geocodingLisbon)
        let rejected: Set<Int> = [2_267_057, 4_584_541, 5_124_527]
        let mapper = RecordingCityMapper(rejecting: rejected)
        let cities = try await geocoder(client: client, mapper: mapper).cities(named: "Lisbon")

        #expect(mapper.receivedResults == response.results)
        #expect(cities.map(\.id) == [5_160_951, 5_060_162, 4_969_622, 4_864_990, 5_088_728, 4_360_737, 4_331_040])
        #expect(cities == response.results.filter { !rejected.contains($0.id) }.map(RecordingCityMapper.city(for:)))
    }

    @Test("The real city mapper drops a result with a blank name and keeps the others in order")
    func realMapperDropsBlankName() async throws {
        let response = try Fixtures.decode(GeocodingResponseDTO.self, json: #"""
        {"results": [
            {"id": 1, "name": "Alpha", "latitude": 1.0, "longitude": 2.0, "country_code": "PT", "country": "Portugal"},
            {"id": 2, "name": "  ", "latitude": 3.0, "longitude": 4.0, "country_code": "PT", "country": "Portugal"},
            {"id": 3, "name": "Gamma", "latitude": 5.0, "longitude": 6.0, "country_code": "PT", "country": "Portugal"}
        ]}
        """#)
        let client = MockHTTPClient { _ in response }
        let cities = try await geocoder(client: client, mapper: Fixtures.cityMapper()).cities(named: "Alpha")
        #expect(cities.map(\.id) == [1, 3])
        #expect(cities.map(\.name) == ["Alpha", "Gamma"])
    }

    @Test("The real city mapper turns the Lisbon results into cities")
    func realMapper() async throws {
        let client = try Self.client(returning: .geocodingLisbon)
        let cities = try await geocoder(client: client, mapper: Fixtures.cityMapper()).cities(named: "Lisbon")
        #expect(cities == Fixtures.geocodedLisbonCities)
    }

    @Test("A search without matches returns no cities and never calls the mapper")
    func noMatches() async throws {
        let client = try Self.client(returning: .geocodingNoMatches)
        let mapper = RecordingCityMapper()
        let cities = try await geocoder(client: client, mapper: mapper).cities(named: "Xyzzyqwv")
        #expect(cities.isEmpty)
        #expect(mapper.receivedResults.isEmpty)
    }

    @Test("A connectivity failure from the client reaches the caller unchanged")
    func connectivityFailure() async {
        let mapper = RecordingCityMapper()
        let client = MockHTTPClient { _ in throw NetworkError.transport(URLError(.notConnectedToInternet)) }
        let error = await #expect(throws: NetworkError.self) {
            try await geocoder(client: client, mapper: mapper).cities(named: "Lisbon")
        }
        #expect(Fixtures.urlErrorCode(of: error) == .notConnectedToInternet)
        #expect(error?.isConnectivity == true)
        #expect(mapper.receivedResults.isEmpty)
    }

    @Test("An unacceptable status from the client reaches the caller with the original response")
    func unacceptableStatus() async throws {
        let response = try Fixtures.response(.geocodingErrorCountZero, status: 400)
        let mapper = RecordingCityMapper()
        let client = MockHTTPClient { _ in throw NetworkError.unacceptableStatusCode(response) }
        let error = await #expect(throws: NetworkError.self) {
            try await geocoder(client: client, mapper: mapper).cities(named: "Lisbon")
        }
        #expect(Fixtures.statusResponse(of: error) == response)
        #expect(mapper.receivedResults.isEmpty)
    }

    @Test("Cancellation from the client is passed through as cancellation")
    func cancellation() async {
        let mapper = RecordingCityMapper()
        let client = MockHTTPClient { _ in throw CancellationError() }
        await #expect(throws: CancellationError.self) {
            try await geocoder(client: client, mapper: mapper).cities(named: "Lisbon")
        }
        #expect(mapper.receivedResults.isEmpty)
    }

    private func geocoder(
        client: any HTTPClient,
        requests: any GeocodingRequestMaking = RecordingGeocodingRequests(endpoint: Self.factoryEndpoint),
        mapper: any CityMapping
    ) -> OpenMeteoGeocoder {
        OpenMeteoGeocoder(client: client, requests: requests, mapper: mapper)
    }

    private static func client(returning file: Fixtures.File) throws -> MockHTTPClient {
        let response = try Fixtures.decode(GeocodingResponseDTO.self, from: file)
        return MockHTTPClient { _ in response }
    }
}
