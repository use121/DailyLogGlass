import SwiftUI

/// 年度回顾卡片。刻意不用 glassEffect —— ImageRenderer 渲染玻璃/材质会出问题，
/// 这里用纯渐变 + 实色，保证导出的图片和屏幕上一致。
struct ShareCardView: View {
    let year: Int
    let entries: [Entry]
    let longestStreak: Int

    private var sorted: [Entry] {
        entries.sorted { $0.date < $1.date }
    }

    private var topMood: Mood {
        guard !entries.isEmpty else { return Mood.mood(2) }
        var counts = Array(repeating: 0, count: Mood.all.count)
        for e in entries {
            let i = min(max(e.moodIndex, 0), Mood.all.count - 1)
            counts[i] += 1
        }
        let maxIndex = counts.enumerated().max { $0.element < $1.element }?.offset ?? 2
        return Mood.mood(maxIndex)
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 5), count: 14)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.16),
                    Color(red: 0.18, green: 0.09, blue: 0.30),
                    Color(red: 0.06, green: 0.12, blue: 0.26)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 0) {
                Text("\(year)")
                    .font(.system(size: 76, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 4)

                Text("DAILY LOG")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(.white.opacity(0.45))

                Spacer(minLength: 12)

                LazyVGrid(columns: gridColumns, spacing: 5) {
                    ForEach(sorted.prefix(140)) { entry in
                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .fill(Mood.mood(entry.moodIndex).tint.opacity(0.9))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }

                Spacer(minLength: 16)

                HStack(spacing: 28) {
                    statBlock(value: "\(entries.count)", label: "记录天数")
                    statBlock(value: "\(longestStreak)", label: "最长连续")
                    HStack(spacing: 5) {
                        Text(topMood.emoji).font(.system(size: 16))
                        Text("主导心情")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
            .padding(30)
        }
        .frame(width: 360, height: 480)
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
        }
    }
}
