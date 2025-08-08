import SwiftUI

struct ContentView: View {
    @StateObject private var timerService = TimerService()
    
    var body: some View {
        TabView {
            MainTimerView()
                .environmentObject(timerService)
                .tabItem {
                    Image(systemName: "timer")
                    Text("Timer")
                }
            
            HistoryView()
                .environmentObject(timerService)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("History")
                }
            
            SettingsView()
                .environmentObject(timerService)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}