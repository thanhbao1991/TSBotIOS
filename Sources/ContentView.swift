import SwiftUI

struct ContentView: View {
    @StateObject private var vm = BotViewModel()
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            StatusTabView()
                .tabItem { Label("Trạng thái", systemImage: "person.crop.circle") }
            ControlTabView()
                .tabItem { Label("Điều khiển", systemImage: "gamecontroller") }
            SettingsView()
                .tabItem { Label("Cài đặt", systemImage: "gearshape") }
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
