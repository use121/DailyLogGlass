import Foundation
import SwiftData
import SwiftUI
import UIKit

@Model
final class Entry {
    var date: Date
    var moodIndex: Int
    var title: String
    var note: String
    var createdAt: Date

    /// 照片以外部存储方式保存，避免把大文件塞进数据库行里。
    @Attribute(.externalStorage) var photoData: Data?

    init(
        date: Date = .now,
        moodIndex: Int = 2,
        title: String = "",
        note: String = "",
        photoData: Data? = nil
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.moodIndex = moodIndex
        self.title = title
        self.note = note
        self.photoData = photoData
        self.createdAt = .now
    }

    var uiImage: UIImage? {
        guard let photoData else { return nil }
        return UIImage(data: photoData)
    }
}

struct Mood: Identifiable {
    let id: Int
    let emoji: String
    let label: String
    let hint: String
    let tint: Color

    static let all: [Mood] = [
        Mood(id: 0, emoji: "😞", label: "低落",
             hint: "记录下来就好，情绪不需要被解决。",
             tint: Color(red: 0.42, green: 0.52, blue: 0.95)),
        Mood(id: 1, emoji: "😕", label: "一般",
             hint: "平平淡淡也是完整的一天。",
             tint: Color(red: 0.40, green: 0.72, blue: 0.92)),
        Mood(id: 2, emoji: "🙂", label: "还行",
             hint: "还不错，值得留一句。",
             tint: Color(red: 0.36, green: 0.86, blue: 0.78)),
        Mood(id: 3, emoji: "😄", label: "不错",
             hint: "好事发生了，写下来以后能翻到。",
             tint: Color(red: 0.98, green: 0.78, blue: 0.35)),
        Mood(id: 4, emoji: "🤩", label: "超棒",
             hint: "这种日子，值得配一张照片。",
             tint: Color(red: 0.98, green: 0.52, blue: 0.55))
    ]

    static func mood(_ index: Int) -> Mood {
        all[min(max(index, 0), all.count - 1)]
    }
}
