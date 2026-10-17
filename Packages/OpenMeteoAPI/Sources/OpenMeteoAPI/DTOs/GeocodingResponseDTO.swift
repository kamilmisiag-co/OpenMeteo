//
//  GeocodingResponseDTO.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct GeocodingResponseDTO: Decodable, Hashable, Sendable {
    private struct LossyResult: Decodable {
        let value: GeocodingResultDTO?

        init(from decoder: any Decoder) throws {
            value = try? GeocodingResultDTO(from: decoder)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case results
    }

    public let results: [GeocodingResultDTO]

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let candidates = try container.decodeIfPresent([LossyResult].self, forKey: .results) ?? []
        let decoded = candidates.compactMap(\.value)
        guard decoded.isEmpty, !candidates.isEmpty else {
            results = decoded
            return
        }
        throw DecodingError.dataCorruptedError(
            forKey: .results,
            in: container,
            debugDescription: "None of the \(candidates.count) results could be decoded."
        )
    }
}
