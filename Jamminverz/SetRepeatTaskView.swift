//
//  SetRepeatTaskView.swift
//  Todomai-iOS
//
//  Adaptive iOS version for task creation
//

import SwiftUI

struct SetRepeatTaskView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @State private var showingTextInput = false
    @State private var inputText = ""
    @State private var taskType: TaskType = .regular
    
    enum TaskType {
        case plan, repeatTask, deadline, regular
        
        var color: Color {
            switch self {
            case .plan:
                return Color(red: 0.6, green: 0.4, blue: 1.0) // Purple
            case .repeatTask:
                return Color(red: 0.6, green: 0.85, blue: 0.7) // Mint green
            case .deadline:
                return Color(red: 1.0, green: 0.6, blue: 0.7) // Pastel pink
            case .regular:
                return Color.orange.opacity(0.7)
            }
        }
        
        var listIdSuffix: String {
            switch self {
            case .plan: return "_plan"
            case .repeatTask: return "_recurring"
            case .deadline: return "_deadline"
            case .regular: return ""
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: geometry.safeAreaInsets.top + 40)
                    
                    // Task type buttons - adaptive sizing
                    VStack(spacing: geometry.size.width > 600 ? 20 : 12) {
                        // PLAN button
                        TaskTypeButton(
                            title: "PLAN",
                            color: TaskType.plan.color,
                            geometry: geometry
                        ) {
                            taskType = .plan
                            showingTextInput = true
                        }
                        
                        // REPEAT TASK button
                        TaskTypeButton(
                            title: "REPEAT TASK",
                            color: TaskType.repeatTask.color,
                            geometry: geometry
                        ) {
                            taskType = .repeatTask
                            currentTab = "repeatFrequency"
                        }
                        
                        // DEADLINE/APPOINTMENT button
                        TaskTypeButton(
                            title: taskStore.currentMode == .life ? "APPOINTMENT" : "DEADLINE",
                            color: TaskType.deadline.color,
                            geometry: geometry
                        ) {
                            taskType = .deadline
                            showingTextInput = true
                        }
                        
                        // CANCEL button
                        TaskTypeButton(
                            title: "CANCEL",
                            color: .gray,
                            geometry: geometry
                        ) {
                            taskStore.longPressedDate = nil
                            currentTab = "calendar"
                        }
                    }
                    .padding(.horizontal, geometry.size.width > 600 ? 60 : 30)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingTextInput) {
            TaskInputSheet(
                taskStore: taskStore,
                taskType: taskType,
                currentTab: $currentTab,
                isPresented: $showingTextInput
            )
        }
    }
}

struct TaskTypeButton: View {
    let title: String
    let color: Color
    let geometry: GeometryProxy
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            ZStack {
                color
                Rectangle()
                    .stroke(Color.white, lineWidth: geometry.size.width > 600 ? 4 : 3)
            }
            .frame(height: geometry.size.width > 600 ? 60 : 50)
            .overlay(
                Text(title)
                    .font(.system(size: geometry.size.width > 600 ? 20 : 16, weight: .heavy))
                    .foregroundColor(.white)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TaskInputSheet: View {
    @ObservedObject var taskStore: TaskStore
    let taskType: SetRepeatTaskView.TaskType
    @Binding var currentTab: String
    @Binding var isPresented: Bool
    
    @State private var taskText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 20) {
                    // Task type indicator
                    HStack {
                        Rectangle()
                            .fill(taskType.color)
                            .frame(width: 6, height: 40)
                        
                        Text(taskType == .plan ? "New Plan" :
                             taskType == .deadline ? "New Deadline/Appointment" :
                             "New Task")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Text input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What would you like to add?")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter task description", text: $taskText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                            .focused($isTextFieldFocused)
                            .onAppear {
                                isTextFieldFocused = true
                            }
                    }
                    .padding(.horizontal)
                    
                    // Date/time selection for deadlines
                    if taskType == .deadline, let selectedDate = taskStore.longPressedDate {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(taskType.color)
                                Text(selectedDate, style: .date)
                                    .font(.body)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        Button("Add Task") {
                            createTask()
                        }
                        .disabled(taskText.isEmpty)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(taskText.isEmpty ? Color.gray : taskType.color)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func createTask() {
        guard !taskText.isEmpty,
              let selectedDate = taskStore.longPressedDate else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        var task = Task(
            text: taskText,
            listId: "calendar_\(dateString)\(taskType.listIdSuffix)",
            mode: taskStore.currentMode.rawValue
        )
        task.dueDate = selectedDate
        
        if taskType == .repeatTask {
            task.isRecurring = true
        }
        
        taskStore.tasks.insert(task, at: 0)
        
        // Provide feedback and dismiss
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isPresented = false
        currentTab = "dayView"
    }
}

#Preview {
    SetRepeatTaskView(taskStore: TaskStore(), currentTab: .constant("setRepeatTask"))
}