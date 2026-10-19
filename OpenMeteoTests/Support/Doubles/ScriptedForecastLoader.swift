//
//  ScriptedForecastLoader.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import Synchronization

final class ScriptedForecastLoader: ForecastLoading {
    struct Step: Sendable {
        let outcome: ForecastLoadOutcome?
        let gate: AsyncGate?

        init(_ outcome: ForecastLoadOutcome?, after gate: AsyncGate? = nil) {
            self.outcome = outcome
            self.gate = gate
        }
    }

    private struct Script {
        var steps: [Step]
        var requestedCities: [City] = []
    }

    private let script: Mutex<Script>

    init(steps: [Step]) {
        script = Mutex(Script(steps: steps))
    }

    var requestedCities: [City] {
        script.withLock { $0.requestedCities }
    }

    func load(_ city: City) async -> ForecastLoadOutcome? {
        let step = script.withLock { script in
            script.requestedCities.append(city)
            return script.steps.isEmpty ? nil : script.steps.removeFirst()
        }
        await step?.gate?.wait()
        return step?.outcome
    }
}
