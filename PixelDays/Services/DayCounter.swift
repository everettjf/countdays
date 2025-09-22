import Foundation

struct DayCounter {
    private static func calendar(for timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func startOfDay(_ date: Date, in timeZone: TimeZone) -> Date {
        calendar(for: timeZone).startOfDay(for: date)
    }

    static func days(for entry: Entry, now: Date = .now) -> Int {
        switch entry.entryType {
        case .countUp:
            guard let startDate = entry.startDate else { return 0 }
            let startDay = startOfDay(startDate, in: entry.timezone)
            let userCalendar = calendar(for: TimeZone.current)
            let today = userCalendar.startOfDay(for: now)
            let components = userCalendar.dateComponents([.day], from: startDay, to: today)
            return components.day ?? 0
        case .countDown:
            guard let targetDate = entry.targetDate else { return 0 }
            let tzCalendar = calendar(for: entry.timezone)
            let normalizedTarget = tzCalendar.startOfDay(for: targetDate)

            if now >= normalizedTarget {
                let seconds = normalizedTarget.timeIntervalSince(now)
                return Int(ceil(seconds / 86_400.0))
            }

            let components = tzCalendar.dateComponents([.day], from: tzCalendar.startOfDay(for: now), to: normalizedTarget)
            return max(0, components.day ?? 0)
        }
    }

    static func days(for snapshot: EntrySnapshot, now: Date = .now) -> Int {
        switch snapshot.entryType {
        case .countUp:
            guard let start = snapshot.startDate else { return 0 }
            let startDay = startOfDay(start, in: snapshot.timezone)
            let calendar = calendar(for: TimeZone.current)
            let today = calendar.startOfDay(for: now)
            let components = calendar.dateComponents([.day], from: startDay, to: today)
            return components.day ?? 0
        case .countDown:
            guard let target = snapshot.targetDate else { return 0 }
            let calendar = calendar(for: snapshot.timezone)
            let normalizedTarget = calendar.startOfDay(for: target)
            if now >= normalizedTarget {
                let seconds = normalizedTarget.timeIntervalSince(now)
                return Int(ceil(seconds / 86_400.0))
            }
            let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: normalizedTarget)
            return max(0, components.day ?? 0)
        }
    }
}
