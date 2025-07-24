import SwiftUI

struct ThisWeekView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    
    private let daysOfWeek = ["M", "T", "W", "T", "F", "S", "S"]
    private let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Light blue background (#7aaff5) - exactly like watchOS
                Color(red: 0.478, green: 0.686, blue: 0.961)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Title - tappable to go back to menu - exactly like watchOS
                    Text("THIS WEEK")
                        .font(.system(size: 24, weight: .regular)) // Larger for iOS
                        .foregroundColor(.black)
                        .padding(.top, 20) // Push it up
                        .padding(.bottom, 24) // More padding for iOS
                        .contentShape(Rectangle()) // Make entire area tappable
                        .onTapGesture {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            currentTab = "menu"
                        }
                    
                    // 7 day buttons with better spacing - exactly like watchOS
                    VStack(spacing: 16) { // More spacing for iOS
                        ForEach(0..<7) { dayIndex in
                            DayButton_iOS(
                                dayLetter: daysOfWeek[dayIndex],
                                dayName: dayNames[dayIndex],
                                dayIndex: dayIndex,
                                taskStore: taskStore,
                                currentTab: $currentTab
                            )
                        }
                    }
                    .padding(.horizontal, 36) // More padding for iOS
                    
                    Spacer() // This will create the dead space at the bottom
                }
            }
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width > 50 {
                        // Swipe right - go back to main menu - exactly like watchOS
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        currentTab = "menu"
                    }
                    // Swipe left to go to calendar - navigation pattern like watchOS
                    else if value.translation.width < -50 {
                        currentTab = "calendar"
                    }
                }
        )
    }
}

struct DayButton_iOS: View {
    let dayLetter: String
    let dayName: String
    let dayIndex: Int
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    
    private func cleanTaskText(_ text: String) -> String {
        // Remove "Every [day]" pattern since day is already shown
        let patterns = [
            #"\s*\(Every \w+day\)"#,  // Matches "(Every Monday)"
            #"\s*Every \w+day"#,      // Matches "Every Monday"
            #"\s*Every \d+\w+"#       // Matches "Every 16th"
        ]
        
        var cleanedText = text
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: cleanedText.utf16.count)
                cleanedText = regex.stringByReplacingMatches(in: cleanedText, options: [], range: range, withTemplate: "")
            }
        }
        
        return cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Get the date for this day (Monday-based week)
    private var targetDate: Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday = 2
        let now = Date()
        
        // Get the start of the week (Monday)
        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday + 5) % 7 // Convert to Monday-based (0=Mon, 6=Sun)
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: now)!
        
        // Add the day index to get the target date
        return calendar.date(byAdding: .day, value: dayIndex, to: monday) ?? now
    }
    
    // Check if this day has tasks
    private var tasksForDay: [Task] {
        let calendar = Calendar.current
        
        return taskStore.tasks.filter { task in
            guard !task.isCompleted,
                  task.mode == taskStore.currentMode.rawValue else { return false }
            
            // EXCLUDE LATER TASKS - they should never appear on weekly calendar
            if task.listId == "later" {
                return false
            }
            
            // Check if task is due on this specific date
            if let dueDate = task.dueDate {
                if calendar.isDate(dueDate, inSameDayAs: targetDate) {
                    return true
                }
            }
            
            // Check for recurring tasks
            if task.isRecurring || task.text.lowercased().contains("every") {
                // Weekly recurring - check the actual day name in the text
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "EEEE" // Full weekday name
                let currentDayName = dateFormatter.string(from: targetDate).lowercased()
                
                // Check if the task text contains the current day name
                return task.text.lowercased().contains(currentDayName)
            }
            
            return false
        }
    }
    
    private var taskColors: [Color] {
        var colors: [Color] = []
        
        // Check for each task type and add its color
        let hasDeadline = tasksForDay.contains { task in
            task.text.lowercased().contains("deadline") || 
            task.text.lowercased().contains("due") ||
            task.text.lowercased().contains("appointment")
        }
        let hasRecurring = tasksForDay.contains { task in 
            task.isRecurring || 
            task.text.lowercased().contains("every") ||
            task.text.lowercased().contains("daily") ||
            task.text.lowercased().contains("weekly") ||
            task.text.lowercased().contains("monthly")
        }
        let hasPlan = tasksForDay.contains { task in
            task.text.lowercased().contains("plan") ||
            task.text.lowercased().contains("meeting") ||
            task.text.lowercased().contains("review") ||
            task.text.lowercased().contains("session")
        }
        let hasRegular = tasksForDay.contains { task in
            let text = task.text.lowercased()
            return !task.isRecurring &&
                   !text.contains("deadline") &&
                   !text.contains("due") &&
                   !text.contains("appointment") &&
                   !text.contains("every") &&
                   !text.contains("daily") &&
                   !text.contains("weekly") &&
                   !text.contains("monthly") &&
                   !text.contains("plan") &&
                   !text.contains("meeting") &&
                   !text.contains("review") &&
                   !text.contains("session")
        }
        
        if hasDeadline {
            colors.append(Color(red: 1.0, green: 0.6, blue: 0.7)) // Pastel pink
        }
        if hasRecurring {
            colors.append(Color(red: 0.6, green: 0.85, blue: 0.7)) // Mint green
        }
        if hasPlan {
            colors.append(Color(red: 0.6, green: 0.4, blue: 1.0)) // Purple
        }
        if hasRegular {
            colors.append(taskStore.currentMode.modeButtonColor) // Mode color
        }
        
        return colors
    }
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            // Navigate to weekday view for this day - would need to implement in iOS
            taskStore.selectedCalendarDate = targetDate
            // For now, just navigate to calendar since iOS doesn't have weekDayView yet
            currentTab = "calendar"
        }) {
            HStack(spacing: 12) { // More spacing for iOS
                // Day letter on the left
                Text(dayLetter)
                    .font(.system(size: 20, weight: .heavy)) // Larger for iOS
                    .foregroundColor(.black)
                    .frame(width: 24) // Larger for iOS
                
                // Circle with task color
                Circle()
                    .fill(tasksForDay.isEmpty ? Color.gray.opacity(0.3) : taskColors.first ?? taskStore.currentMode.modeButtonColor)
                    .frame(width: 24, height: 24) // Larger for iOS
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 3) // Thicker for iOS
                    )
                
                // Task text or empty if no tasks
                Text(tasksForDay.first.map { cleanTaskText($0.text) } ?? "")
                    .font(.system(size: 16, weight: .bold)) // Larger for iOS
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 0)
            .padding(.trailing, 10) // More padding for iOS
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ThisWeekView(taskStore: TaskStore(), currentTab: .constant("thisWeek"))
}