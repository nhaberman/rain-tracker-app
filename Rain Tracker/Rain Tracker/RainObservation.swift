import Foundation
import SwiftData

enum TimeOfDay: String, CaseIterable, Codable {
    case night     = "Night"
    case morning   = "Morning"
    case afternoon = "Afternoon"
    case evening   = "Evening"

    static func from(date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 0..<6:  return .night
        case 6..<12: return .morning
        case 12..<18: return .afternoon
        default:     return .evening
        }
    }

    var label: String { rawValue }
}

@Model
final class RainObservation {
    var amount: Double = 0
    var date: Date?
    var timeOfDay: TimeOfDay = TimeOfDay.morning

    init(amount: Double, date: Date = .now, timeOfDay: TimeOfDay? = nil) {
        self.amount = amount
        self.date = Calendar.current.startOfDay(for: date)
        self.timeOfDay = timeOfDay ?? TimeOfDay.from(date: date)
    }
}
