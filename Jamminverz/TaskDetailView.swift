import SwiftUI

struct TaskDetailView: View {
    let task: Task
    @State private var isCompleted = false
    @State private var showingEditSheet = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Task Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button(action: {
                            isCompleted.toggle()
                        }) {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isCompleted ? .green : .gray)
                                .font(.title2)
                        }
                        
                        Text(task.text)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .strikethrough(isCompleted)
                        
                        Spacer()
                    }
                    
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Task Details
                VStack(alignment: .leading, spacing: 12) {
                    Label("Due Date", systemImage: "calendar")
                        .font(.headline)
                    
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(.body)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No due date")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            // TODO: Edit task view
            Text("Edit Task View")
        }
    }
}


#Preview {
    NavigationView {
        TaskDetailView(task: Task(
            text: "Sample Task",
            listId: "today", 
            mode: "life"
        ))
    }
}