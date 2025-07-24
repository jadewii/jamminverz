import SwiftUI

struct TodayView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @State private var newTaskText = ""
    @State private var showingAddTask = false
    @State private var isAddingTask = false
    @FocusState private var isTextFieldFocused: Bool
    
    var todayTasks: [Task] {
        taskStore.tasks.filter { 
            $0.listId == "today" && 
            $0.mode == taskStore.currentMode.rawValue && 
            !$0.isCompleted 
        }
    }
    
    var body: some View {
        ZStack {
            // White background for TODAY page - exactly like watchOS
            Color.white.ignoresSafeArea()
            
            ZStack {
                VStack(spacing: 0) {
                    // Page title - exactly like watchOS
                    Text(getDayName())
                        .font(.system(size: 24, weight: .medium)) // Larger for iOS
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40) // More padding for iOS
                        .padding(.bottom, 20)
                    
                    // Task list at the top with ScrollView
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(todayTasks) { task in
                                TodayTaskRow_iOS(task: task, taskStore: taskStore)
                            }
                            
                            // Placeholder for new task
                            HStack(alignment: .top, spacing: 16) {
                                // Microphone button
                                Button(action: {
                                    // Voice input would go here
                                    taskStore.addTask("Task from voice")
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
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
                    
                    Spacer()
                }
                
                // Microphone button positioned in bottom right - exactly like watchOS
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // Add a sample task for now - voice input requires more complex implementation
                            taskStore.addTask("New task from mic")
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 80, height: 80) // Larger for iOS
                                
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 32)) // Larger for iOS
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.trailing, 32) // More padding for iOS
                        .padding(.bottom, 60) // More padding for iOS
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Swipe right to go back to main menu - exactly like watchOS
                    if value.translation.width > 50 {
                        currentTab = "menu"
                    }
                    // Swipe left to go to thisWeek - navigation pattern like watchOS
                    else if value.translation.width < -50 {
                        currentTab = "thisWeek"
                    }
                }
        )
    }
    
    func getDayName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name
        return formatter.string(from: Date()).uppercased()
    }
}

struct TodayTaskRow_iOS: View {
    let task: Task
    let taskStore: TaskStore
    
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
        HStack(alignment: .top, spacing: 16) { // More spacing for iOS
            // Task completion indicator - exactly like watchOS
            ZStack {
                Circle()
                    .stroke(Color.black, lineWidth: 3) // Thicker for iOS
                    .frame(width: 32, height: 32) // Larger for iOS
                    .background(task.isCompleted ? Color.black : Color.clear)
                
                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold)) // Larger for iOS
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Extract the recurring day if present
                let (displayText, recurringDay) = extractRecurringInfo(from: task.text)
                
                Text(displayText)
                    .foregroundColor(.black)
                    .font(.system(size: 18)) // Larger for iOS
                    .multilineTextAlignment(.leading)
                
                // Show time if task has a dueDate with time
                if let dueDate = task.dueDate {
                    let timeText = formatTime(dueDate)
                    if !timeText.isEmpty {
                        // For recurring tasks, show day with time
                        if let day = recurringDay {
                            Text("\(day) \(timeText)")
                                .font(.system(size: 14)) // Larger for iOS
                                .foregroundColor(taskStore.currentMode.modeButtonColor)
                        } else {
                            Text(timeText)
                                .font(.system(size: 14)) // Larger for iOS
                                .foregroundColor(taskStore.currentMode.modeButtonColor)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .onTapGesture {
            // Toggle task completion - exactly like watchOS
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            taskStore.toggleTask(task)
        }
    }
}

#Preview {
    TodayView(taskStore: TaskStore(), currentTab: .constant("today"))
}