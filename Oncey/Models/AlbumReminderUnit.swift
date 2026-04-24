import Foundation

enum AlbumReminderUnit: String, CaseIterable, Identifiable, Codable, Sendable {
    case day
    case week
    case month
    case year

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .day:
            return .day
        case .week:
            return .weekOfYear
        case .month:
            return .month
        case .year:
            return .year
        }
    }
}