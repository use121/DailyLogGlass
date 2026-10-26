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

    @State private var showPhotoPicker = false
    @State private var justSaved = false
    @State private var hintMood: Mood?
    @State private var toastText: String?

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
                hintCaption
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .onAppear(perform: loadToday)
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                await MainActor.run {
                    withAnimation(.spring(response: 0.35)) { photoData = data }
                }
            }
        }
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                if let mood = hintMood {
                    bubble(mood.hint, tint: mood.tint.opacity(0.35))
                }
                if let toastText {
                    bubble(toastText, tint: .clear)
                }
            }
            .padding(.top, 8)
            .allowsHitTesting(false)
        }
    }

    // MARK: - 头部（只有长按，没有点击，不存在冲突）

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
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.5) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            copyTodayToClipboard()
        }
    }

    // MARK: - 心情（点击与长按交给两套独立手势，不再用 Button）

    private var moodRow: some View {
        HStack(spacing: 10) {
            ForEach(Mood.all) { mood in
                moodCell(mood)
            }
        }
    }

    private func moodCell(_ mood: Mood) -> some View {
        let selected = moodIndex == mood.id

        return VStack(spacing: 6) {
            Text(mood.emoji)
                .font(.system(size: 24))
            Text(mood.label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(selected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
        .glassEffect(
            .regular.tint(selected ? mood.tint.opacity(0.55) : Color.clear),
            in: .rect(cornerRadius: 22)
        )
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                moodIndex = mood.id
            }
        }
        .onLongPressGesture(minimumDuration: 0.45) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.spring(response: 0.3)) { hintMood = mood }
            Task {
                try? await Task.sleep(for: .seconds(2.2))
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.25)) {
                        if hintMood?.id == mood.id { hintMood = nil }
                    }
                }
            }
        }
    }

    // MARK: - 照片（普通按钮 + 模态弹出，命中区域不会被撑开）

    private var photoCard: some View {
        Button {
            showPhotoPicker = true
        } label: {
            Group {
                if let photoData, let image = UIImage(data: photoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 编辑卡片（长按清空）

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
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.6) {
            clearDraft()
        }
    }

    // MARK: - 保存（纯点击，不挂任何手势）

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
    }

    private var hintCaption: some View {
        Text("长按心情看提示 · 长按头部复制 · 长按编辑区清空草稿")
            .font(.system(size: 11, design: .rounded))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
    }

    // MARK: - 浮层

    private func bubble(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 13, design: .rounded))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(.regular.tint(tint), in: .rect(cornerRadius: 16))
            .padding(.horizontal, 24)
            .transition(.move(edge: .top).combined(with: .opacity))
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

        withAnimation(.spring(response: 0.3)) { justSaved = true }

        Task {
            try? await Task.sleep(for: .seconds(1.6))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) { justSaved = false }
            }
        }
    }

    private func clearDraft() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        withAnimation(.spring(response: 0.3)) {
            title = ""
            note = ""
            photoData = nil
            photoItem = nil
        }
        showToast("草稿已清空")
    }

    private func copyTodayToClipboard() {
        var parts: [String] = [Date.now.formatted(.dateTime.year().month().day())]
        if !title.isEmpty { parts.append(title) }
        if !note.isEmpty { parts.append(note) }
        if parts.count == 1 { parts.append("（今天还没有记录）") }

        UIPasteboard.general.string = parts.joined(separator: "\n")
        showToast("已复制到剪贴板")
    }

    private func showToast(_ text: String) {
        withAnimation(.spring(response: 0.3)) { toastText = text }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) { toastText = nil }
            }
        }
    }
}
