import Foundation
import SwiftData

@Model
final class RainObservation {
    var amount: Double
    var date: Date
    var notes: String

    init(amount: Double, date: Date = .now, notes: String = "") {
        self.amount = amount
        self.date = date
        self.notes = notes
    }
}
