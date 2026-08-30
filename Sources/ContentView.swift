import SwiftUI

struct ContentView: View {
    @StateObject private var vm = BotViewModel()
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            StatusTabView()
                .tabItem { Label("Trạng thái", systemImage: "person.crop.circle") }
            AiTimTabView()
                .tabItem { Label("AI Tìm", systemImage: "figure.walk") }
            DiscordTabView()
                .tabItem { Label("Discord", systemImage: "bubble.left.and.bubble.right") }
            LogView()
                .tabItem { Label("Log", systemImage: "doc.text") }
        }
        .environmentObject(vm)
        .task { await vm.refresh() }
        .onReceive(timer) { _ in Task { await vm.refresh() } }
    }
}

#Preview {
    ContentView()
}
