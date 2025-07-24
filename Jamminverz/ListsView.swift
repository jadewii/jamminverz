import SwiftUI

struct ListsView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @Binding var isProcessing: Bool
    let listId: String
    let listName: String
    let backgroundColor: Color
    
    @State private var getItDoneMode = false
    @State private var selectedTask: Task? = nil
    @State private var showTimerSelection = false
    @State private var selectedTimerMinutes: Int? = nil
    @State private var showTimerReady = false
    @State private var isAddingTask = false
    @State private var newTaskText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var tasks: [Task] {
        taskStore.tasks.filter { $0.listId == listId && $0.mode == taskStore.currentMode.rawValue && !$0.isCompleted }
    }
    
    var body: some View {
        ZStack {
            // List-specific background color
            backgroundColor.ignoresSafeArea()
            
            if showTimerSelection, let _ = selectedTask {
                // Timer selection overlay (to be implemented)
                Color.black.opacity(0.8).ignoresSafeArea()
                Text("Timer Selection Coming Soon")
                    .foregroundColor(.white)
            } else {
                ZStack {
                    VStack(spacing: 0) {
                        // Page title - tap to go back
                        Text(listName)
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(.black.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Navigate back to menu
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                currentTab = "menu"
                            }
                        
                        ScrollView {
                            VStack(spacing: 0) {
                                // Task list
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(tasks) { task in
                                        TaskRow(
                                            task: task,
                                            taskStore: taskStore,
                                            getItDoneMode: getItDoneMode,
                                            onSelect: {
                                                if getItDoneMode {
                                                    // Show timer selection
                                                    selectedTask = task
                                                    showTimerSelection = true
                                                }
                                            }
                                        )
                                    }
                                    
                                    // Placeholder for new task
                                    HStack(alignment: .top, spacing: 16) {
                                        // Microphone button
                                        Button(action: {
                                            startVoiceInput()
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.black)
                                                    .frame(width: 32, height: 32)
                                                
                                                Image(systemName: "mic.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        if isAddingTask {
                                            TextField("New task", text: $newTaskText, onCommit: {
                                                if !newTaskText.isEmpty {
                                                    taskStore.addTask(newTaskText)
                                                    newTaskText = ""
                                                    isAddingTask = false
                                                }
                                            })
                                            .font(.system(size: 18))
                                            .foregroundColor(.black)
                                            .focused($isTextFieldFocused)
                                            .onAppear {
                                                isTextFieldFocused = true
                                            }
                                        } else {
                                            Text("Add new task...")
                                                .foregroundColor(.black.opacity(0.5))
                                                .font(.system(size: 18))
                                                .italic()
                                                .onTapGesture {
                                                    isAddingTask = true
                                                }
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 20)
                            }
                        }
                    }
                    
                    // Bottom buttons
                    VStack {
                        Spacer()
                        HStack(alignment: .center) {
                            // GET IT DONE! button - positioned in bottom left
                            HStack(spacing: 8) {
                                Button(action: {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    getItDoneMode.toggle()
                                }) {
                                    Circle()
                                        .fill(getItDoneMode ? Color.black : Color.clear)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black, lineWidth: 3)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text("move to today")
                                    .font(.system(size: 16))
                                    .foregroundColor(getItDoneMode ? .black : .black.opacity(0.6))
                            }
                            .padding(.leading, 24)
                            
                            Spacer()
                            
                            // Microphone button positioned in bottom right
                            Button(action: {
                                // Start voice input
                                startVoiceInput()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 64, height: 64)
                                    
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.trailing, 24)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Swipe right to go back to main menu
                    if value.translation.width > 50 {
                        currentTab = "menu"
                    }
                }
        )
    }
    
    private func startVoiceInput() {
        // iOS voice input implementation will go here
        print("Voice input requested for list: \(listId)")
    }
}

struct TaskRow: View {
    let task: Task
    let taskStore: TaskStore
    let getItDoneMode: Bool
    let onSelect: () -> Void
    
    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        // If it's midnight (12:00 AM), don't show time
        if hour == 0 && minute == 0 {
            return ""
        }
        
        // Format time without AM/PM
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return String(format: "%d:%02d", displayHour, minute)
    }
    
    private func extractRecurringInfo(from text: String) -> (displayText: String, recurringDay: String?) {
        // Check for "Every [day]" pattern
        let patterns = [
            #"\s*\(Every (\w+day)\)"#,  // Matches "(Every Monday)"
            #"\s*Every (\w+day)"#        // Matches "Every Monday"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.utf16.count)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    // Extract the day
                    if let dayRange = Range(match.range(at: 1), in: text) {
                        let day = String(text[dayRange]).capitalized
                        // Remove the "Every [day]" part from the text
                        let cleanText = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        return (cleanText, day)
                    }
                }
            }
        }
        
        // No recurring pattern found
        return (text, nil)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Button(action: {
                if getItDoneMode {
                    // Trigger timer selection
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    onSelect()
                } else {
                    // Toggle task completion
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    taskStore.toggleTask(task)
                }
            }) {
                if task.isCompleted {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 32, height: 32)
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    }
                } else {
                    Circle()
                        .fill(getItDoneMode ? Color.white : Color.clear)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 3)
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                // Extract the recurring day if present
                let (displayText, recurringDay) = extractRecurringInfo(from: task.text)
                
                Text(displayText)
                    .foregroundColor(.black)
                    .font(.system(size: 18))
                    .multilineTextAlignment(.leading)
                
                // Show time if task has a dueDate with time
                if let dueDate = task.dueDate {
                    let timeText = formatTime(dueDate)
                    if !timeText.isEmpty {
                        // For recurring tasks, show day with time
                        if let day = recurringDay {
                            Text("\(day) \(timeText)")
                                .font(.system(size: 13))
                                .foregroundColor(taskStore.currentMode.modeButtonColor)
                        } else {
                            Text(timeText)
                                .font(.system(size: 13))
                                .foregroundColor(taskStore.currentMode.modeButtonColor)
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
}