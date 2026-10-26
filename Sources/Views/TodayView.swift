import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]

    @State private var moodIndex: Int = 2
    @State private var title: String = ""
    @State private var note: String = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var justSaved: Bool = false
    @State private var hintMood: Mood?
    @State private var showClearToast: Bool = false
    @Namespace private var glassNS

    private var todayEntry: Entry? {
        entries.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                moodRow
                photoCard
                editorCard
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .onAppear(perform: loadToday)
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                await MainActor.run {
                    withAnimation(.spring(response: 0.35)) {
                        photoData = data
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            if let mood = hintMood {
                hintBubble(mood)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if showClearToast {
                toast("草稿已清空")
                    .transition(.opacity)
            }
        }
    }

    // MARK: - 头部

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Date.now.formatted(.dateTime.year().month().day().weekday(.wide)))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            Text(todayEntry == nil ? "今天过得怎么样？" : "今天已经记过了")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("给这一天留一句话。")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .glassCard(cornerRadius: 28)
        .onLongPressGesture(minimumDuration: 0.5) {
            copyTodayToClipboard()
        }
    }

    // MARK: - 心情

    private var moodRow: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(Mood.all) { mood in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                            moodIndex = mood.id
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(mood.emoji)
                                .font(.system(size: 24))
                            Text(mood.label)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(moodIndex == mood.id ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(
                        moodIndex == mood.id
                            ? .regular.tint(mood.tint.opacity(0.55)).interactive()
                            : .regular,
                        in: .rect(cornerRadius: 22)
                    )
                    .glassEffectID(mood.id, in: glassNS)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.45)
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                withAnimation(.spring(response: 0.3)) {
                                    hintMood = mood
                                }
                                Task {
                                    try? await Task.sleep(for: .seconds(2.2))
                                    await MainActor.run {
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            if hintMood?.id == mood.id { hintMood = nil }
                                        }
                                    }
                                }
                            }
                    )
                }
            }
        }
    }

    // MARK: - 照片

    private var photoCard: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            ZStack {
                if let photoData, let image = UIImage(data: photoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(alignment: .bottomTrailing) {
                            Text("更换")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .glassEffect(.regular, in: .capsule)
                                .padding(12)
                        }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 26, weight: .light))
                        Text("加一张今天的照片")
                            .font(.system(size: 13, design: .rounded))
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 110)
                    .glassCard(cornerRadius: 24)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 编辑

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("给今天起个标题", text: $title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .textFieldStyle(.plain)
                .foregroundStyle(.primary)

            Rectangle()
                .fill(.primary.opacity(0.12))
                .frame(height: 0.8)

            TextField("写点什么…", text: $note, axis: .vertical)
                .font(.system(size: 15, design: .rounded))
                .lineLimit(5...12)
                .textFieldStyle(.plain)
                .foregroundStyle(.primary.opacity(0.9))
        }
        .padding(22)
        .glassCard(cornerRadius: 26)
    }

    // MARK: - 保存

    private var saveButton: some View {
        Button {
            save()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: justSaved ? "checkmark.circle.fill" : "sparkles")
                Text(justSaved ? "已保存" : "记下来")
            }
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.glassProminent)
        .tint(justSaved ? .green : .primary)
        .foregroundStyle(justSaved ? Color.white : Color(uiColor: .systemBackground))
        .disabled(title.isEmpty && note.isEmpty && photoData == nil)
        .animation(.spring(response: 0.3), value: justSaved)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.6)
                .onEnded { _ in
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    withAnimation(.spring(response: 0.3)) {
                        title = ""
                        note = ""
                        photoData = nil
                        photoItem = nil
                        showClearToast = true
                    }
                    Task {
                        try? await Task.sleep(for: .seconds(1.6))
                        await MainActor.run {
                            withAnimation(.easeOut(duration: 0.25)) { showClearToast = false }
                        }
                    }
                }
        )
    }

    // MARK: - 浮层

    private func hintBubble(_ mood: Mood) -> some View {
        Text(mood.hint)
            .font(.system(size: 13, design: .rounded))
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(.regular.tint(mood.tint.opacity(0.35)), in: .capsule)
            .padding(.top, 8)
    }

    private func toast(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: .capsule)
            .padding(.top, 8)
    }

    // MARK: - 逻辑

    private func loadToday() {
        guard let entry = todayEntry else { return }
        moodIndex = entry.moodIndex
        title = entry.title
        note = entry.note
        photoData = entry.photoData
    }

    private func save() {
        if let entry = todayEntry {
            entry.moodIndex = moodIndex
            entry.title = title
            entry.note = note
            entry.photoData = photoData
        } else {
            let entry = Entry(
                date: .now,
                moodIndex: moodIndex,
                title: title,
                note: note,
                photoData: photoData
            )
            context.insert(entry)
        }

        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation(.spring(response: 0.3)) {
            justSaved = true
        }

        Task {
            try? await Task.sleep(for: .seconds(1.6))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    justSaved = false
                }
            }
        }
    }

    private func copyTodayToClipboard() {
        var parts: [String] = []
        let day = Date.now.formatted(.dateTime.year().month().day())
        parts.append(day)
        if !title.isEmpty { parts.append(title) }
        if !note.isEmpty { parts.append(note) }
        if parts.count == 1 { parts.append("（今天还没有记录）") }

        UIPasteboard.general.string = parts.joined(separator: "\n")
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(.spring(response: 0.3)) { showClearToast = true }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) { showClearToast = false }
            }
        }
    }
}
