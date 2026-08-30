import SwiftUI

/// Nút bánh răng mở SettingsView — dùng chung trên toolbar của cả 4 tab, tách riêng file/struct để
/// tránh lặp lại kiểu ambiguous toolbar(content:) đã gặp khi nhồi hết vào 1 view lớn.
struct SettingsToolbarModifier: ViewModifier {
    @State private var showSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar { toolbarContent }
            .sheet(isPresented: $showSettings) { SettingsView() }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
            }
        }
    }
}

extension View {
    func settingsToolbar() -> some View {
        modifier(SettingsToolbarModifier())
    }
}
