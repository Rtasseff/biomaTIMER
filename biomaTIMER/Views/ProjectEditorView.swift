import SwiftUI

struct ProjectEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var timerService: TimerService
    @State private var projectName = ""
    @State private var selectedColor = "#007AFF"
    
    let availableColors = [
        "#007AFF", "#34C759", "#FF3B30", "#FF9500",
        "#FFCC00", "#AF52DE", "#FF2D92", "#5AC8FA",
        "#32D74B", "#FF453A", "#FF9F0A", "#30B0C7"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project Name")
                        .font(.headline)
                    
                    TextField("Enter project name", text: $projectName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 15) {
                        ForEach(availableColors, id: \.self) { colorHex in
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == colorHex ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = colorHex
                                }
                        }
                    }
                }
                
                Spacer()
                
                Button("Save Project") {
                    if !projectName.isEmpty {
                        timerService.addProject(name: projectName, colorHex: selectedColor)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(projectName.isEmpty)
            }
            .padding()
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProjectEditorView()
        .environmentObject(TimerService(context: PersistenceController.preview.container.viewContext))
}