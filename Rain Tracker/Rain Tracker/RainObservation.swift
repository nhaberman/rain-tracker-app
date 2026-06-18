import Foundation
import SwiftData

@Model
final class RainObservation {
    var amount: Double = 0
    var date: Date?
    init(amount: Double, date: Date = .now) {
        self.amount = amount
        self.date = date
    }
}
