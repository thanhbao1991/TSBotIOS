import SwiftUI

struct ContentView: View {
    @State private var statuses: [BotStatus] = []
    @State private var errorMessage: String?
    @State private var busy = false
    @State private var aiTimOn = false
    @State private var moveMode = 0
    @State private var forwardLoa = false
    @State private var showSettings = false
    @State private var showLog = false

    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    private var idx: Int { Prefs.idx }
    private var current: BotStatus? { statuses.first(where: { $0.idx == idx }) }

    var body: some View {
        NavigationStack {
            mainList
                .navigationTitle("TSBot")
                .toolbar { settingsToolbar }
                .refreshable { await refresh() }
                .onReceive(timer) { _ in Task { await refresh() } }
                .task { await refresh() }
                .sheet(isPresented: $showSettings) { SettingsView() }
                .sheet(isPresented: $showLog) { LogView(idx: idx) }
                .overlay { busyOverlay }
        }
    }

    @ViewBuilder
    private var busyOverlay: some View {
        if busy { ProgressView().controlSize(.large) }
    }

    @ToolbarContentBuilder
    private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
            }
        }
    }

    private var mainList: some View {
        List {
            if let err = errorMessage {
                Section {
                    Text(err).foregroundStyle(.red).font(.footnote)
                }
            }

            statusSection
            controlSection
            aiTimSection
            discordSection

            Section {
                Button("Xem log") { showLog = true }
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        Section("Trạng thái") {
            if let s = current {
                LabeledContent("Tài khoản", value: s.username)
                LabeledContent("Online", value: s.loggedIn ? "✅ \(s.charName)" : "❌ offline")
                if s.loggedIn {
                    LabeledContent("Map", value: "\(s.mapId) (\(s.x), \(s.y))")
                    LabeledContent("Level", value: "\(s.level)")
                    LabeledContent("HP", value: "\(s.hp)/\(s.hpMax)")
                    LabeledContent("SP", value: "\(s.sp)/\(s.spMax)")
                }
            } else {
                Text("Chưa có dữ liệu — kéo để làm mới").foregroundStyle(.secondary)
            }
        }
    }

    private var controlSection: some View {
        Section("Điều khiển") {
            HStack {
                Button("Đăng nhập") { runAction { try await APIClient.login(idx: idx) } }
                    .disabled(busy || current?.loggedIn == true)
                Spacer()
                Button("Đăng xuất", role: .destructive) { runAction { try await APIClient.logout(idx: idx) } }
                    .disabled(busy || current?.loggedIn != true)
            }
        }
    }

    private var aiTimSection: some View {
        Section("AI Tìm (tự đi lại)") {
            Toggle("Bật AI Tìm", isOn: $aiTimOn)
                .onChange(of: aiTimOn) { newValue in
                    runAction { try await APIClient.setSetting(idx: idx, name: "AiTimActive", value: newValue ? "true" : "false") }
                }
            Picker("Chế độ", selection: $moveMode) {
                Text("Ngẫu nhiên").tag(0)
                Text("Truy kích").tag(1)
            }
            .pickerStyle(.segmented)
            .onChange(of: moveMode) { newValue in
                runAction { try await APIClient.setSetting(idx: idx, name: "MoveMode", value: "\(newValue)") }
            }
        }
    }

    private var discordSection: some View {
        Section("Discord") {
            Toggle("Forward chat World (loa)", isOn: $forwardLoa)
                .onChange(of: forwardLoa) { newValue in
                    runAction { try await APIClient.setForwardLoa(idx: idx, value: newValue) }
                }
        }
    }

    private func refresh() async {
        do {
            statuses = try await APIClient.fetchStatus()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func runAction(_ action: @escaping () async throws -> Void) {
        busy = true
        Task {
            do {
                try await action()
                try? await Task.sleep(nanoseconds: 500_000_000)
                await refresh()
            } catch {
                errorMessage = error.localizedDescription
            }
            busy = false
        }
    }
}

#Preview {
    ContentView()
}
