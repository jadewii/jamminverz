import SwiftUI

struct AddTaskView: View {
    let defaultList: String
    @State private var taskText = ""
    @State private var selectedDate = Date()
    @State private var hasTime = false
    @EnvironmentObject var taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("What needs to be done?", text: $taskText, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Due Date & Time")) {
                    Toggle("Set due time", isOn: $hasTime)
                    
                    if hasTime {
                        DatePicker("Due Date & Time", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                    } else {
                        DatePicker("Due Date", selection: $selectedDate, displayedComponents: [.date])
                    }
                }
                
                Section(header: Text("List")) {
                    Text(taskStore.currentMode.getListName(for: defaultList))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addTask()
                        dismiss()
                    }
                    .disabled(taskText.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func addTask() {
        var newTask = Task(
            text: taskText,
            listId: defaultList,
            mode: taskStore.currentMode.rawValue
        )
        
        if hasTime {
            newTask.dueDate = selectedDate
        } else {
            // Set to start of day if just date is selected
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            newTask.dueDate = calendar.date(from: components)
        }
        
        taskStore.tasks.insert(newTask, at: 0)
    }
}

#Preview {
    AddTaskView(defaultList: "today")
        .environmentObject(TaskStore())
}