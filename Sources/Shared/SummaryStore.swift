import Foundation

/// 把当前统计摘要写进 App Group 的 UserDefaults。
/// 现在主 App 先写，将来加 Widget 时直接读这里，不用改数据结构。
struct SummaryStore {
    struct Summary: Codable {
        var total: Int
        var streak: Int
        var moodIndex: Int
        var title: String
        var hasToday: Bool
        var updatedAt: Date
    }

    static func write(_ summary: Summary) {
        guard let data = try? JSONEncoder().encode(summary) else { return }

        if let defaults = UserDefaults(suiteName: AppKeys.appGroup) {
            defaults.set(data, forKey: "summary")
        }
        // 没有 App Group 权限时退回标准存储，保证 App 本身不出错
        UserDefaults.standard.set(data, forKey: "summary")
    }
}
