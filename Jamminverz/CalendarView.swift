//
//  CalendarView.swift
//  Todomai-iOS
//
//  iOS version adapted from watchOS CalendarView

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var currentTab = "calendar"
    @State private var isInYearMode = false
    @State private var selectedDate: Date? = nil
    
    private var displayDate: Date {
        taskStore.calendarDisplayDate
    }
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    // Month colors for year mode (same as watchOS)
    private func getMonthColor(for date: Date) -> Color {
        let month = calendar.component(.month, from: date)
        
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
    
    // Get darker shade of month color for date buttons (same as watchOS)
    private func getDarkerMonthColor(for date: Date) -> Color {
        let isCurrentMonth = calendar.isDate(date, equalTo: Date(), toGranularity: .month)
        
        // Current month stays white
        if isCurrentMonth {
            return .white
        }
        
        // Other months get their colors
        let month = calendar.component(.month, from: date)
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
    
    // Calculate number of calendar rows
    private var calendarRowCount: Int {
        let range = calendar.range(of: .day, in: .month, for: displayDate)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayDate))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        let totalDays = firstWeekday + range.count
        return Int(ceil(Double(totalDays) / 7.0))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - colored for all months (same as watchOS)
                getDarkerMonthColor(for: displayDate)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 40) // iOS needs more top spacing
                    
                    // Header with month/year (same as watchOS)
                    Text(dateFormatter.string(from: displayDate).uppercased())
                        .font(.system(size: 24, weight: .heavy)) // Larger for iOS
                        .foregroundColor(calendar.isDate(displayDate, equalTo: Date(), toGranularity: .month) ? .black : .white)
                        .padding(.top, 4)
                        .padding(.bottom, 16) // More padding for iOS
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Navigate back to menu (same as watchOS)
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            // This would need to be handled by parent view navigation
                        }
                    
                    // Calendar grid (same logic as watchOS)
                    CalendarGridView(
                        currentDate: displayDate,
                        taskStore: taskStore,
                        selectedDate: $selectedDate,
                        isInYearMode: !calendar.isDate(displayDate, equalTo: Date(), toGranularity: .month)
                    )
                    .padding(.horizontal, 16) // More padding for iOS
                    
                    Spacer(minLength: 0) // Allow it to shrink if needed
                    
                    // Mode switcher button - centered with dynamic positioning (same as watchOS)
                    HStack {
                        Spacer()
                        
                        // Mode button - navigate to menu
                        Circle()
                            .fill(calendar.isDate(displayDate, equalTo: Date(), toGranularity: .month) ? Color.black : Color.white)
                            .frame(width: 56, height: 56) // Larger for iOS
                            .overlay(
                                Circle()
                                    .stroke((calendar.isDate(displayDate, equalTo: Date(), toGranularity: .month) ? Color.black : Color.white).opacity(0.7), lineWidth: 3)
                            )
                            .onTapGesture {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                // This would need to be handled by parent view navigation
                            }
                        
                        Spacer()
                    }
                    // Dynamic bottom padding based on calendar rows (same logic as watchOS)
                    .padding(.bottom, calendarRowCount == 5 ? 40 : 16) // More padding for iOS
                }
            }
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width > 50 {
                        // Swipe right -> previous month
                        taskStore.navigateToPreviousMonth()
                    } else if value.translation.width < -50 {
                        // Swipe left -> next month
                        taskStore.navigateToNextMonth()
                    }
                }
        )
        .onChange(of: selectedDate) { oldValue, newDate in
            if let date = newDate {
                // Navigate to day view for selected date (same as watchOS)
                taskStore.selectedCalendarDate = date
                // This would need to be handled by parent view navigation
                // currentTab = "dayView"
            }
        }
        .onChange(of: taskStore.longPressedDate) { oldValue, newDate in
            if newDate != nil {
                // Navigate to repeat task menu for long pressed date (same as watchOS)
                // This would need to be handled by parent view navigation
                // currentTab = "setRepeatTask"
            }
        }
    }
}

struct CalendarGridView: View {
    let currentDate: Date
    @ObservedObject var taskStore: TaskStore
    @Binding var selectedDate: Date?
    let isInYearMode: Bool
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    // Pre-compute tasks for all days to avoid repeated filtering (same as watchOS)
    private var tasksPerDay: [String: [Task]] {
        var taskMap: [String: [Task]] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // First pass: collect all tasks (same logic as watchOS)
        for task in taskStore.tasks where !task.isCompleted && task.mode == taskStore.currentMode.rawValue {
            // SKIP LATER TASKS - they should never appear on calendar
            if task.listId == "later" {
                continue
            }
            
            // Handle today's tasks
            if task.listId == "today" {
                let todayKey = dateFormatter.string(from: Date())
                taskMap[todayKey, default: []].append(task)
            }
            // Handle calendar-specific tasks
            else if task.listId.hasPrefix("calendar_") {
                // Extract date part from listId (format: calendar_YYYY-MM-DD or calendar_YYYY-MM-DD_type)
                let components = task.listId.components(separatedBy: "_")
                if components.count >= 2 {
                    let dateString = components[1] // Get the date part
                    taskMap[dateString, default: []].append(task)
                }
            }
            // Handle recurring tasks
            else if task.isRecurring || task.text.lowercased().contains("every") {
                // This needs special handling - add to all matching days
                let dates = generateDates()
                for date in dates {
                    if shouldShowRecurringTask(task, on: date) {
                        let dateKey = dateFormatter.string(from: date)
                        taskMap[dateKey, default: []].append(task)
                    }
                }
            }
        }
        
        return taskMap
    }
    
    private func shouldShowRecurringTask(_ task: Task, on date: Date) -> Bool {
        guard let dueDate = task.dueDate else { return false }
        
        // Monthly recurring (same logic as watchOS)
        if task.text.contains("Every") && (task.text.contains("th") || task.text.contains("st") || task.text.contains("nd") || task.text.contains("rd")) {
            let taskDay = calendar.component(.day, from: dueDate)
            let currentDay = calendar.component(.day, from: date)
            return taskDay == currentDay
        }
        // Weekly recurring
        else if task.text.lowercased().contains("every") {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE" // Full weekday name
            let currentDayName = dateFormatter.string(from: date).lowercased()
            return task.text.lowercased().contains(currentDayName)
        }
        
        return false
    }
    
    var body: some View {
        VStack(spacing: 4) { // Slightly more spacing for iOS
            // Day headers (same as watchOS)
            HStack(spacing: 4) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 14)) // Larger for iOS
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar dates (same logic as watchOS)
            let dates = generateDates()
            let taskMap = tasksPerDay
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(dates.indices, id: \.self) { index in
                    let date = dates[index]
                    let dateKey = CalendarDayView.dateFormatter.string(from: date)
                    CalendarDayView(
                        date: date,
                        isCurrentMonth: isCurrentMonth(date),
                        taskStore: taskStore,
                        selectedDate: $selectedDate,
                        isInYearMode: isInYearMode,
                        displayDate: currentDate,
                        precomputedTasks: taskMap[dateKey] ?? []
                    )
                }
            }
        }
    }
    
    private func generateDates() -> [Date] {
        var dates: [Date] = []
        
        let range = calendar.range(of: .day, in: .month, for: currentDate)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        
        // Add previous month's trailing days (same logic as watchOS)
        if firstWeekday > 0 {
            for i in (1...firstWeekday).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: firstOfMonth) {
                    dates.append(date)
                }
            }
        }
        
        // Add current month's days
        for i in 0..<range.count {
            if let date = calendar.date(byAdding: .day, value: i, to: firstOfMonth) {
                dates.append(date)
            }
        }
        
        // Add next month's leading days
        while dates.count % 7 != 0 {
            if let lastDate = dates.last,
               let date = calendar.date(byAdding: .day, value: 1, to: lastDate) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    private func isCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: currentDate, toGranularity: .month)
    }
}

struct CalendarDayView: View {
    let date: Date
    let isCurrentMonth: Bool
    @ObservedObject var taskStore: TaskStore
    @Binding var selectedDate: Date?
    let isInYearMode: Bool
    let displayDate: Date
    let precomputedTasks: [Task]
    
    private let calendar = Calendar.current
    
    // Create DateFormatter once as static (same as watchOS)
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private var dayText: String {
        "\(calendar.component(.day, from: date))"
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    // Get background view for date buttons (same logic as watchOS)
    private func getDateButtonBackground() -> some View {
        let colors = taskColors
        
        if colors.isEmpty {
            // No tasks
            if isToday && !isInYearMode && isCurrentMonth {
                // TODAY WITH NO TASKS - GREEN BACKGROUND (same as watchOS)
                return AnyView(
                    RoundedRectangle(cornerRadius: 8) // Slightly larger radius for iOS
                        .fill(Color.green)
                )
            } else {
                // Other days without tasks - gray
                return AnyView(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isCurrentMonth ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                )
            }
        } else if colors.count == 1 {
            // Single color - just fill the whole square
            return AnyView(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colors[0])
            )
        } else if colors.count == 2 {
            // Two colors - split vertically
            return AnyView(
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(colors[0])
                    Rectangle()
                        .fill(colors[1])
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            )
        } else if colors.count >= 3 {
            // Three or more colors - split vertically into thirds
            return AnyView(
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(colors[0])
                    Rectangle()
                        .fill(colors[1])
                    Rectangle()
                        .fill(colors[2])
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            )
        } else {
            // Fallback - shouldn't reach here
            return AnyView(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
            )
        }
    }
    
    private func getTextColor() -> Color {
        if isInYearMode {
            return isCurrentMonth ? .white : .white.opacity(0.3)
        } else {
            // For current month view
            if isCurrentMonth {
                // Today always gets black text
                return .black
            } else {
                return .gray
            }
        }
    }
    
    private var tasksForDay: [Task] {
        // Use precomputed tasks instead of filtering (same as watchOS)
        return precomputedTasks
    }
    
    private var hasTask: Bool {
        !tasksForDay.isEmpty
    }
    
    private var taskColors: [Color] {
        if hasTask {
            var colors: [Color] = []
            var hasDeadline = false
            var hasRecurring = false
            var hasPlan = false
            var hasRegular = false
            
            // Single pass through tasks (same logic as watchOS)
            for task in tasksForDay {
                let lowerText = task.text.lowercased()
                
                if !hasDeadline && (task.listId.contains("_deadline") || lowerText.contains("deadline") || lowerText.contains("due") || lowerText.contains("appointment")) {
                    hasDeadline = true
                }
                
                if !hasRecurring && (task.listId.contains("_recurring") || task.isRecurring || lowerText.contains("every") || lowerText.contains("daily") || lowerText.contains("weekly") || lowerText.contains("monthly")) {
                    hasRecurring = true
                }
                
                if !hasPlan && (task.listId.contains("_plan") || lowerText.contains("plan") || lowerText.contains("meeting") || lowerText.contains("review") || lowerText.contains("session")) {
                    hasPlan = true
                }
                
                if !hasRegular && !task.isRecurring && 
                   !task.listId.contains("_deadline") && !task.listId.contains("_recurring") && !task.listId.contains("_plan") &&
                   !lowerText.contains("deadline") && !lowerText.contains("due") && !lowerText.contains("appointment") &&
                   !lowerText.contains("every") && !lowerText.contains("daily") && !lowerText.contains("weekly") && !lowerText.contains("monthly") &&
                   !lowerText.contains("plan") && !lowerText.contains("meeting") && !lowerText.contains("review") && !lowerText.contains("session") {
                    hasRegular = true
                }
                
                // Early exit if we found all types
                if hasDeadline && hasRecurring && hasPlan && hasRegular {
                    break
                }
            }
            
            // Same color scheme as watchOS
            if hasDeadline {
                colors.append(Color(red: 1.0, green: 0.6, blue: 0.7)) // Deadline/Appointment tasks are pastel pink
            }
            if hasRecurring {
                colors.append(Color(red: 0.6, green: 0.85, blue: 0.7)) // Repeat tasks are mint green
            }
            if hasPlan {
                colors.append(Color(red: 0.6, green: 0.4, blue: 1.0)) // Plan tasks are purple
            }
            if hasRegular {
                colors.append(taskStore.currentMode.modeButtonColor) // Regular tasks use mode color
            }
            
            return colors
        } else {
            // For year mode (colored months), use the month color (same as watchOS)
            if isInYearMode {
                let month = calendar.component(.month, from: displayDate)
                let monthColor: Color
                switch month {
                case 1: monthColor = Color(red: 0.25, green: 0.5, blue: 1.0)
                case 2: monthColor = Color(red: 1.0, green: 0.25, blue: 0.6)
                case 3: monthColor = Color(red: 0.25, green: 0.75, blue: 1.0)
                case 4: monthColor = Color(red: 1.0, green: 0.75, blue: 0.25)
                case 5: monthColor = Color(red: 0.59, green: 0.25, blue: 1.0)
                case 6: monthColor = Color(red: 0.859, green: 0.835, blue: 0.145)
                case 7: monthColor = Color(red: 1.0, green: 0.4, blue: 0.35)
                case 8: monthColor = Color(red: 1.0, green: 0.55, blue: 0.25)
                case 9: monthColor = Color(red: 0.75, green: 0.25, blue: 0.25)
                case 10: monthColor = Color(red: 1.0, green: 0.25, blue: 0.5)
                case 11: monthColor = Color(red: 0.5, green: 0.25, blue: 0.75)
                case 12: monthColor = Color(red: 0.25, green: 0.75, blue: 0.4)
                default: monthColor = .gray
                }
                return [monthColor]
            } else {
                return [isCurrentMonth ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1)]
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            getDateButtonBackground()
                .opacity(isCurrentMonth ? 1.0 : 0.5)
            
            // Border for today (same as watchOS)
            if isToday && isCurrentMonth && !isInYearMode {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 3) // Thicker for iOS
            }
            
            // Text on top
            Text(dayText)
                .font(.system(size: 16, weight: isToday ? .bold : .regular)) // Larger for iOS
                .foregroundColor(getTextColor())
        }
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture {
            // Regular tap - navigate to day view (same as watchOS)
            selectedDate = date
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            // Long press - open repeat task menu (same as watchOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            taskStore.longPressedDate = date
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(TaskStore())
}