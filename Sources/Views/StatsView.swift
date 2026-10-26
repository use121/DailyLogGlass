import SwiftUI
import SwiftData
import UIKit

struct StatsView: View {
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]

    @State private var explain: String?

    private var total: Int { entries.count }

    private var days: Set<Date> {
        Set(entries.map { Calendar.current.startOfDay(for: $0.date) })
    }

    private var streak: Int {
        let cal = Calendar.current
        var count = 0
        var day = cal.startOfDay(for: .now)

        if !days.contains(day) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        while days.contains(day) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    private var moodCounts: [Int] {
        var counts = Array(repeating: 0, count: Mood.all.count)
        for entry in entries {
            let i = min(max(entry.moodIndex, 0), Mood.all.count - 1)
            counts[i] += 1
        }
        return counts
    }

    private var maxCount: Int { max(moodCounts.max() ?? 0, 1) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    statTile(
                        value: "\(streak)",
                        unit: "天",
                        label: "连续记录",
                        tint: Color(red: 0.98, green: 0.52, blue: 0.55),
                        hint: "从今天（或昨天）往前数，连续没有断掉的天数。"
                    )
                    statTile(
                        value: "\(total)",
                        unit: "条",
                        label: "累计记录",
                        tint: Color(red: 0.36, green: 0.86, blue: 0.78),
                        hint: "所有记录的总条数，一天最多一条。"
                    )
                }

                moodChart

                Text("长按卡片可以看说明 · 长按「回顾」里的记录可以复制或删除")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .top) {
            if let explain {
                Text(explain)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func statTile(value: String, unit: String, label: String, tint: Color, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(unit)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            Text(label)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 26, tint: tint.opacity(0.18))
        .onLongPressGesture(minimumDuration: 0.4) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.spring(response: 0.3)) { explain = hint }
            Task {
                try? await Task.sleep(for: .seconds(2.4))
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.25)) {
                        if explain == hint { explain = nil }
                    }
                }
            }
        }
    }

    private var moodChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("心情分布")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            ForEach(Mood.all) { mood in
                let count = moodCounts[mood.id]
                HStack(spacing: 12) {
                    Text(mood.emoji)
                        .font(.system(size: 17))
                        .frame(width: 26)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.primary.opacity(0.08))

                            Capsule()
                                .fill(mood.tint.opacity(0.85))
                                .frame(width: max(6, geo.size.width * CGFloat(count) / CGFloat(maxCount)))
                        }
                    }
                    .frame(height: 10)

                    Text("\(count)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .frame(width: 22, alignment: .trailing)
                }
            }
        }
        .padding(22)
        .glassCard(cornerRadius: 26)
    }
}
