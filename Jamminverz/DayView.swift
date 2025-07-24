//
//  DayView.swift
//  Todomai-iOS
//
//  Adaptive iOS version of watchOS DayView
//

import SwiftUI

struct DayView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    var fromWeek: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()
    
    private var selectedDate: Date {
        taskStore.selectedCalendarDate ?? Date()
    }
    
    private var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedDate, equalTo: Date(), toGranularity: .month)
    }
    
    // Get month color from the calendar's color scheme
    private func getMonthColor(for date: Date) -> Color {
        let month = Calendar.current.component(.month, from: date)
        let isCurrentMonth = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
        
        // Current month is always black
        if isCurrentMonth {
            return .black
        }
        
        // Each month gets a vibrant but muted color (matching CalendarView)
        switch month {
        case 1: return Color(red: 0.25, green: 0.5, blue: 1.0)    // January - Vibrant Blue
        case 2: return Color(red: 1.0, green: 0.25, blue: 0.6)    // February - Vibrant Pink
        case 3: return Color(red: 0.25, green: 0.75, blue: 1.0)   // March - Vibrant Sky Blue
        case 4: return Color(red: 1.0, green: 0.75, blue: 0.25)   // April - Vibrant Gold
        case 5: return Color(red: 0.59, green: 0.25, blue: 1.0)   // May - Vibrant Purple
        case 6: return Color(red: 0.859, green: 0.835, blue: 0.145) // June - LATER button yellow
        case 7: return Color(red: 1.0, green: 0.4, blue: 0.35)    // July - Vibrant Coral
        case 8: return Color(red: 1.0, green: 0.55, blue: 0.25)   // August - Vibrant Orange
        case 9: return Color(red: 0.75, green: 0.25, blue: 0.25)  // September - Vibrant Maroon
        case 10: return Color(red: 1.0, green: 0.25, blue: 0.5)   // October - Vibrant Rose
        case 11: return Color(red: 0.5, green: 0.25, blue: 0.75)  // November - Vibrant Indigo
        case 12: return Color(red: 0.25, green: 0.75, blue: 0.4)  // December - Vibrant Green
        default: return .gray
        }
    }
    
    // Get darker shade of month color for date buttons
    private func getDarkerMonthColor(for date: Date) -> Color {
        let month = Calendar.current.component(.month, from: date)
        let isCurrentMonth = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
        
        // Current month stays dark gray
        if isCurrentMonth {
            return Color(red: 0.2, green: 0.2, blue: 0.2)
        }
        
        // Return darker versions of each month color (multiply RGB by 0.7)
        switch month {
        case 1: return Color(red: 0.175, green: 0.35, blue: 0.7)    // January - Darker Blue
        case 2: return Color(red: 0.7, green: 0.175, blue: 0.42)    // February - Darker Pink
        case 3: return Color(red: 0.175, green: 0.525, blue: 0.7)   // March - Darker Sky Blue
        case 4: return Color(red: 0.7, green: 0.525, blue: 0.175)   // April - Darker Gold
        case 5: return Color(red: 0.413, green: 0.175, blue: 0.7)   // May - Darker Purple
        case 6: return Color(red: 0.601, green: 0.585, blue: 0.102) // June - Darker Yellow
        case 7: return Color(red: 0.7, green: 0.28, blue: 0.245)    // July - Darker Coral
        case 8: return Color(red: 0.7, green: 0.385, blue: 0.175)   // August - Darker Orange
        case 9: return Color(red: 0.525, green: 0.175, blue: 0.175) // September - Darker Maroon
        case 10: return Color(red: 0.7, green: 0.175, blue: 0.35)   // October - Darker Rose
        case 11: return Color(red: 0.35, green: 0.175, blue: 0.525) // November - Darker Indigo
        case 12: return Color(red: 0.175, green: 0.525, blue: 0.28) // December - Darker Green
        default: return .gray
        }
    }
    
    private var backgroundColor: Color {
        isCurrentMonth ? .white : getDarkerMonthColor(for: selectedDate)
    }
    
    private var foregroundColor: Color {
        isCurrentMonth ? .black : .white
    }
    
    private var secondaryColor: Color {
        isCurrentMonth ? .gray : .white.opacity(0.6)
    }
    
    private var tasksForDay: [Task] {
        taskStore.tasks.filter { task in
            guard !task.isCompleted,
                  task.mode == taskStore.currentMode.rawValue else { return false }
            
            // EXCLUDE LATER TASKS - they should never appear on any calendar day
            if task.listId == "later" {
                return false
            }
            
            let calendar = Calendar.current
            
            // For today, include tasks from "today" list
            if calendar.isDateInToday(selectedDate) && task.listId == "today" {
                return true
            }
            
            // Check if this is a calendar event for this specific date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: selectedDate)
            if task.listId.hasPrefix("calendar_\(dateString)") {
                return true
            }
            
            // Check for recurring tasks
            if task.isRecurring || task.text.lowercased().contains("every") {
                if let dueDate = task.dueDate {
                    // Check if it's a monthly recurring task
                    if task.text.contains("Every") && (task.text.contains("th") || task.text.contains("st") || task.text.contains("nd") || task.text.contains("rd")) {
                        // Monthly recurring - check if day of month matches
                        let taskDay = calendar.component(.day, from: dueDate)
                        let currentDay = calendar.component(.day, from: selectedDate)
                        return taskDay == currentDay
                    } else if task.text.lowercased().contains("every") {
                        // Weekly recurring - check the actual day name in the text
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "EEEE" // Full weekday name
                        let currentDayName = dateFormatter.string(from: selectedDate).lowercased()
                        
                        // Check if the task text contains the current day name
                        return task.text.lowercased().contains(currentDayName)
                    }
                }
            }
            
            // Check if task is due on this specific date
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: selectedDate)
            }
            
            // Don't include tasks just because they were created on this date
            // Only include tasks that are explicitly scheduled for this date
            return false
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header - adaptive for iOS/iPad/macOS
                    VStack(spacing: 4) {
                        Text(dateFormatter.string(from: selectedDate).uppercased())
                            .font(.system(size: geometry.size.width > 600 ? 28 : 22, weight: .heavy))
                            .foregroundColor(foregroundColor)
                        
                        Text("\(tasksForDay.count) TASKS")
                            .font(.system(size: geometry.size.width > 600 ? 16 : 12))
                            .foregroundColor(secondaryColor)
                    }
                    .padding(.horizontal)
                    .padding(.top, geometry.safeAreaInsets.top + 20)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Navigate back
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        currentTab = fromWeek ? "thisWeek" : "calendar"
                    }
                    
                    if tasksForDay.isEmpty {
                        // Empty state - adaptive sizing
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Text("NO TASKS")
                                .font(.system(size: geometry.size.width > 600 ? 24 : 18, weight: .heavy))
                                .foregroundColor(secondaryColor)
                            
                            Text("Add a task for this day")
                                .font(.system(size: geometry.size.width > 600 ? 18 : 14))
                                .foregroundColor(secondaryColor.opacity(0.6))
                            
                            // Add task button - adaptive size
                            Button(action: {
                                // Navigate to task creation
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                taskStore.longPressedDate = selectedDate
                                currentTab = "setRepeatTask"
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(foregroundColor)
                                        .frame(width: geometry.size.width > 600 ? 80 : 60,
                                               height: geometry.size.width > 600 ? 80 : 60)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: geometry.size.width > 600 ? 36 : 28))
                                        .foregroundColor(backgroundColor)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Spacer()
                    } else {
                        // Task list with adaptive layout
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(tasksForDay) { task in
                                    TaskRowView_iOS(
                                        task: task,
                                        isCurrentMonth: isCurrentMonth,
                                        foregroundColor: foregroundColor,
                                        taskStore: taskStore,
                                        currentTab: $currentTab,
                                        geometry: geometry
                                    )
                                }
                                
                                // Add button at bottom of list
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        // Navigate to task creation
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                        taskStore.longPressedDate = selectedDate
                                        currentTab = "setRepeatTask"
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(foregroundColor)
                                                .frame(width: geometry.size.width > 600 ? 60 : 50,
                                                       height: geometry.size.width > 600 ? 60 : 50)
                                            
                                            Image(systemName: "plus")
                                                .font(.system(size: geometry.size.width > 600 ? 28 : 24))
                                                .foregroundColor(backgroundColor)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.top, 20)
                                    .padding(.bottom, 40)
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, geometry.size.width > 600 ? 40 : 20)
                            .padding(.top, 20)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width > 50 {
                        // Swipe right - go back
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        currentTab = fromWeek ? "thisWeek" : "calendar"
                    }
                }
        )
    }
}

struct TaskRowView_iOS: View {
    let task: Task
    let isCurrentMonth: Bool
    let foregroundColor: Color
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    let geometry: GeometryProxy
    
    @State private var offset: CGFloat = 0
    @State private var showDeleteConfirmation = false
    
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
    
    private func getTaskColor(for listId: String) -> Color {
        // Calendar events with specific types
        if listId.starts(with: "calendar_") {
            if listId.contains("_deadline") {
                return Color(red: 1.0, green: 0.6, blue: 0.7) // Pastel red for deadlines
            } else if listId.contains("_recurring") {
                return Color(red: 0.6, green: 0.85, blue: 0.7) // Pastel green for recurring
            } else if listId.contains("_plan") {
                return Color(red: 0.6, green: 0.4, blue: 1.0) // Purple for plans
            } else {
                return Color.orange.opacity(0.7) // Default orange for regular calendar events
            }
        }
        
        // Use mode colors for other tasks
        return taskStore.currentMode.modeButtonColor
    }
    
    private func getTaskCategoryName(for listId: String) -> String {
        // Don't show category for calendar events
        if listId.starts(with: "calendar_") {
            return ""
        }
        
        // Return the appropriate category name
        return taskStore.currentMode.getListName(for: listId).uppercased()
    }
    
    var body: some View {
        ZStack {
            // Delete background - only show when swiped
            if offset < 0 {
                HStack {
                    Spacer()
                    Text("DELETE?")
                        .font(.system(size: geometry.size.width > 600 ? 18 : 14, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.red)
                .cornerRadius(12)
            }
            
            // Task content - adaptive layout
            HStack(spacing: geometry.size.width > 600 ? 16 : 12) {
                // Task category indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(getTaskColor(for: task.listId))
                    .frame(width: geometry.size.width > 600 ? 6 : 4,
                           height: geometry.size.width > 600 ? 50 : 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Extract the recurring day if present
                    let (displayText, recurringDay) = extractRecurringInfo(from: task.text)
                    
                    Text(displayText)
                        .font(.system(size: geometry.size.width > 600 ? 18 : 16))
                        .foregroundColor(foregroundColor)
                        .lineLimit(2)
                    
                    // Show time if task has a dueDate with time, otherwise show category
                    if let dueDate = task.dueDate {
                        let timeText = formatTime(dueDate)
                        if !timeText.isEmpty {
                            // For recurring tasks, show day with time
                            if let day = recurringDay {
                                Text("\(day) \(timeText)")
                                    .font(.system(size: geometry.size.width > 600 ? 14 : 12))
                                    .foregroundColor(getTaskColor(for: task.listId))
                            } else {
                                Text(timeText)
                                    .font(.system(size: geometry.size.width > 600 ? 14 : 12))
                                    .foregroundColor(getTaskColor(for: task.listId))
                            }
                        } else if !task.listId.starts(with: "calendar_") {
                            // Show category if no time and not a calendar event
                            Text(getTaskCategoryName(for: task.listId))
                                .font(.system(size: geometry.size.width > 600 ? 14 : 12))
                                .foregroundColor(getTaskColor(for: task.listId))
                        }
                    } else if !task.listId.starts(with: "calendar_") {
                        // Show category for regular tasks without time
                        Text(getTaskCategoryName(for: task.listId))
                            .font(.system(size: geometry.size.width > 600 ? 14 : 12))
                            .foregroundColor(getTaskColor(for: task.listId))
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, geometry.size.width > 600 ? 20 : 16)
            .padding(.vertical, geometry.size.width > 600 ? 12 : 8)
            .background(isCurrentMonth ? Color.gray.opacity(0.1) : Color.white.opacity(0.15))
            .cornerRadius(12)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -100)
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < -50 {
                            // Show delete confirmation
                            offset = -100
                            showDeleteConfirmation = true
                        } else {
                            // Reset position
                            offset = 0
                            showDeleteConfirmation = false
                        }
                    }
            )
            .onTapGesture {
                if showDeleteConfirmation {
                    // Delete the task
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    taskStore.tasks.removeAll { $0.id == task.id }
                } else {
                    // Edit the task
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    taskStore.taskToEdit = task
                    currentTab = "editTask"
                }
            }
        }
    }
}

#Preview {
    DayView(taskStore: TaskStore(), currentTab: .constant("dayView"))
}