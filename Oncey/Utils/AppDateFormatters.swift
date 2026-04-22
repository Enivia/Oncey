//
//  AppDateFormatters.swift
//  Oncey
//

import Foundation

enum AppDateFormatters {
    static let momentTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}