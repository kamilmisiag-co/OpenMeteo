//
//  ScriptedDaySelector.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import Synchronization

final class ScriptedDaySelector: DaySelecting {
    struct Call: Hashable, Sendable {
        let day: Int?
        let current: Int?
        let dayCount: Int
    }

    private struct Script {
        var selections: [Int?]
        var calls: [Call] = []
    }

    private let script: Mutex<Script>

    init(selections: [Int?] = []) {
        script = Mutex(Script(selections: selections))
    }

    var calls: [Call] {
        script.withLock { $0.calls }
    }

    func selection(afterChoosing day: Int?, current: Int?, dayCount: Int) -> Int? {
        script.withLock { script in
            script.calls.append(Call(day: day, current: current, dayCount: dayCount))
            return script.selections.isEmpty ? current : script.selections.removeFirst()
        }
    }
}
