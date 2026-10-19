//
//  ScriptedForecastStateUpdater.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import Synchronization

final class ScriptedForecastStateUpdater: ForecastStateUpdating {
    struct Call: Hashable, Sendable {
        let current: ForecastState
        let outcome: ForecastLoadOutcome
        let city: City
    }

    private struct Script {
        var states: [ForecastState]
        var calls: [Call] = []
    }

    private let script: Mutex<Script>

    init(states: [ForecastState] = []) {
        script = Mutex(Script(states: states))
    }

    var calls: [Call] {
        script.withLock { $0.calls }
    }

    func state(_ current: ForecastState, applying outcome: ForecastLoadOutcome, for city: City) -> ForecastState {
        script.withLock { script in
            script.calls.append(Call(current: current, outcome: outcome, city: city))
            return script.states.isEmpty ? current : script.states.removeFirst()
        }
    }
}
