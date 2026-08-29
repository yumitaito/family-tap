//
//  JapanCalendar.swift
//  FamilyTap
//
//  DAILY判定 helpers (spec section 31/32): DB stores UTC, but "today" for a
//  DAILY button always means Asia/Tokyo's calendar day, not UTC's.
//

import Foundation

enum JapanCalendar {
    static let timeZone = TimeZone(identifier: "Asia/Tokyo")!

    /// [start of today, start of tomorrow) in Asia/Tokyo, as absolute
    /// instants — safe to compare directly against UTC `created_at` values.
    static func todayRange(now: Date = Date()) -> (start: Date, end: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
        return (startOfToday, startOfTomorrow)
    }

    /// "07:12" in Asia/Tokyo, for showing when a DAILY button was reported.
    static func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    /// "今日" / "昨日" / "8月5日" grouping label for HISTORY-001 (spec
    /// section 15), based on Asia/Tokyo calendar days.
    static func dayLabel(for date: Date, now: Date = Date()) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let startOfToday = calendar.startOfDay(for: now)
        let startOfEntryDay = calendar.startOfDay(for: date)
        let daysAgo = calendar.dateComponents([.day], from: startOfEntryDay, to: startOfToday).day ?? 0

        switch daysAgo {
        case 0:
            return "今日"
        case 1:
            return "昨日"
        default:
            let formatter = DateFormatter()
            formatter.timeZone = timeZone
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
    }
}
