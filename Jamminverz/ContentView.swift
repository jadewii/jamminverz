import SwiftUI

struct ContentView: View {
    @StateObject private var taskStore = TaskStore()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var currentTab = "menu"
    @State private var isRouletteMode = false
    @State private var showRandomModeSelection = false
    @State private var isInYearMode = false
    @State private var selectedPriorityTask: Task? = nil
    @State private var showTimerSelection = false
    
    var body: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Use adaptive layout for iPad
            ContentView_Adaptive()
                .environmentObject(themeManager)
        } else {
            // iPhone layout
            iPhoneLayout
        }
        #else
        // macOS layout
        ContentView_Adaptive()
        #endif
    }
    
    var iPhoneLayout: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Main navigation switch - Radio is now the main page
                switch currentTab {
                case "menu":
                    RadioView(taskStore: taskStore, currentTab: $currentTab)
                    
                case "today":
                    TodayView(taskStore: taskStore, currentTab: $currentTab)
                    
                case "thisWeek":
                    ThisWeekView(taskStore: taskStore, currentTab: $currentTab)
                    
                case "calendar":
                    CalendarView_iOS(taskStore: taskStore, currentTab: $currentTab, isInYearMode: $isInYearMode)
                    
                case "dayView":
                    DayView(taskStore: taskStore, currentTab: $currentTab)
                    
                case "setRepeatTask":
                    SetRepeatTaskView(taskStore: taskStore, currentTab: $currentTab)
                    
                case "editTask":
                    EditTaskView(taskStore: taskStore, currentTab: $currentTab)
                    
                case "repeatFrequency":
                    RepeatFrequencyView(taskStore: taskStore, currentTab: $currentTab)
                    
                case "getItDone":
                    GetItDoneView(
                        taskStore: taskStore,
                        currentTab: $currentTab,
                        selectedPriorityTask: $selectedPriorityTask,
                        showTimerSelection: $showTimerSelection,
                        isRouletteMode: $isRouletteMode
                    )
                    
                case "settings":
                    SettingsView()
                        .environmentObject(taskStore)
                    
                // Handle all list views using ListsView
                case "later", "week", "month", "assignments", "exams", 
                     "routine", "goals", "plans", "bills",
                     "projects", "schedule", "ideas", "deadlines",
                     "homework", "study", "notes", "tests",
                     "routines", "appointments":
                    ListsView(
                        taskStore: taskStore,
                        currentTab: $currentTab,
                        isProcessing: .constant(false),
                        listId: currentTab,
                        listName: getListName(for: currentTab),
                        backgroundColor: getListColor(for: currentTab)
                    )
                    
                default:
                    RadioView(taskStore: taskStore, currentTab: $currentTab)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    // Simple swipe detection - matches watchOS logic
                    if currentTab == "menu" {
                        if value.translation.width < -50 {
                            currentTab = "getItDone"
                        }
                    } else if currentTab == "calendar" {
                        // Calendar handles its own swipes for month navigation
                        // Don't navigate away from calendar on swipe
                    }
                }
        )
    }
    
    func getListName(for id: String) -> String {
        switch id {
        case "routine": return "ROUTINE"
        case "goals": return "GOALS"
        case "plans": return "PLANS"
        case "bills": return "BILLS"
        case "projects": return "PROJECTS"
        case "schedule": return "SCHEDULE"
        case "ideas": return "IDEAS"
        case "deadlines": return "DEADLINES"
        case "homework": return "HOMEWORK"
        case "study": return "STUDY"
        case "notes": return "NOTES"
        case "tests": return "TESTS"
        case "routines": return "ROUTINES"
        case "appointments": return "APPOINTMENTS"
        case "settings": return "SETTINGS"
        default: return taskStore.currentMode.getListName(for: id)
        }
    }
    
    func getListColor(for id: String) -> Color {
        switch id {
        case "routine": return Color(red: 0.4, green: 0.8, blue: 0.4)
        case "goals": return Color(red: 1.0, green: 0.6, blue: 0.8)
        case "plans": return Color(red: 0.8, green: 0.6, blue: 1.0)
        case "bills": return Color(red: 1.0, green: 0.7, blue: 0.3)
        case "projects": return Color(red: 0.4, green: 0.6, blue: 1.0)
        case "schedule": return Color(red: 0.4, green: 0.8, blue: 0.4)
        case "ideas": return Color(red: 1.0, green: 0.9, blue: 0.4)
        case "deadlines": return Color(red: 1.0, green: 0.4, blue: 0.4)
        case "homework": return Color(red: 0.8, green: 0.6, blue: 1.0)
        case "study": return Color(red: 0.6, green: 0.8, blue: 1.0)
        case "notes": return Color(red: 1.0, green: 0.9, blue: 0.4)
        case "tests": return Color(red: 1.0, green: 0.4, blue: 0.4)
        case "routines": return Color(red: 0.8, green: 0.8, blue: 1.0)
        case "appointments": return Color(red: 0.8, green: 0.6, blue: 1.0)
        case "settings": return Color(red: 0.6, green: 0.6, blue: 0.6)
        default: return taskStore.currentMode.getListColor(for: id)
        }
    }
}

struct MenuView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @Binding var isRouletteMode: Bool
    @Binding var showRandomModeSelection: Bool
    @State private var isProcessing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Show username instead of mode - JAde Wii
                    Text("JAde Wii")
                        .font(.system(size: 24, weight: .regular)) // Larger for iOS
                        .foregroundColor(.white)
                        .padding(.top, 40) // More padding for iOS
                    
                    Spacer()
                    
                    VStack(spacing: 20) { // More spacing for iOS
                        ForEach(taskStore.currentMode.getListIds(), id: \.self) { listId in
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                if listId == "done" {
                                    taskStore.calendarDisplayDate = Date()
                                    currentTab = "calendar"
                                } else {
                                    taskStore.currentListId = listId
                                    currentTab = listId
                                }
                            }) {
                                Text(taskStore.currentMode.getListName(for: listId))
                                    .font(.system(size: 18, weight: .heavy)) // Larger for iOS
                                    .frame(maxWidth: .infinity, minHeight: 50) // Taller for iOS
                                    .foregroundColor(.black)
                                    .background(
                                        ZStack {
                                            Color.white
                                            Rectangle()
                                                .stroke(Color.purple, lineWidth: 6) // Purple border
                                        }
                                        .clipped()
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .animation(nil, value: currentTab)
                        }
                    }
                    .padding(.horizontal, 40) // More padding for iOS
                    
                    Spacer()
                    
                    // Music/settings button - purple theme
                    ZStack {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 80, height: 80) // Larger for iOS
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                    }
                    .onTapGesture {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        currentTab = "getItDone"
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        taskStore.cycleThroughModes()
                    }
                    .padding(.bottom, 60) // More padding for iOS
                }
            }
        }
    }
}

struct GetItDoneView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @Binding var selectedPriorityTask: Task?
    @Binding var showTimerSelection: Bool
    @Binding var isRouletteMode: Bool
    
    var getItDoneButtons: [(title: String, color: Color, action: String)] {
        switch taskStore.currentMode {
        case .life:
            return [
                ("ROUTINE", Color(red: 0.4, green: 0.8, blue: 0.4), "routine"),
                ("GOALS", Color(red: 1.0, green: 0.6, blue: 0.8), "goals"),
                ("PLANS", Color(red: 0.8, green: 0.6, blue: 1.0), "plans"),
                ("BILLS", Color(red: 1.0, green: 0.7, blue: 0.3), "bills"),
                ("MODES", Color(red: 0.8, green: 0.8, blue: 0.8), "modes"),
                ("RANDOM", Color.black, "random")
            ]
        case .work:
            return [
                ("PROJECTS", Color(red: 0.4, green: 0.6, blue: 1.0), "projects"),
                ("SCHEDULE", Color(red: 0.4, green: 0.8, blue: 0.4), "schedule"),
                ("IDEAS", Color(red: 1.0, green: 0.9, blue: 0.4), "ideas"),
                ("DEADLINES", Color(red: 1.0, green: 0.4, blue: 0.4), "deadlines"),
                ("MODES", Color(red: 0.8, green: 0.8, blue: 0.8), "modes"),
                ("PRIORITY", Color.black, "priority")
            ]
        case .school:
            return [
                ("HOMEWORK", Color(red: 0.8, green: 0.6, blue: 1.0), "homework"),
                ("STUDY", Color(red: 0.6, green: 0.8, blue: 1.0), "study"),
                ("NOTES", Color(red: 1.0, green: 0.9, blue: 0.4), "notes"),
                ("TESTS", Color(red: 1.0, green: 0.4, blue: 0.4), "tests"),
                ("MODES", Color(red: 0.8, green: 0.8, blue: 0.8), "modes"),
                ("TIMER", Color.black, "timer")
            ]
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Title - exactly like watchOS
                    Text("GET IT DONE!")
                        .font(.system(size: 24, weight: .regular)) // Larger for iOS
                        .foregroundColor(.black)
                        .padding(.top, 40) // More padding for iOS
                    
                    Spacer()
                    
                    VStack(spacing: 20) { // More spacing for iOS
                        ForEach(getItDoneButtons, id: \.title) { button in
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                switch button.action {
                                case "modes":
                                    taskStore.cycleThroughModes()
                                case "random":
                                    isRouletteMode = true
                                    // TODO: Implement random task selection
                                case "priority":
                                    // TODO: Implement priority mode
                                    break
                                case "timer":
                                    showTimerSelection = true
                                    // TODO: Implement timer selection
                                default:
                                    // Navigate to the respective list
                                    taskStore.currentListId = button.action
                                    currentTab = button.action
                                }
                            }) {
                                Text(button.title)
                                    .font(.system(size: 16, weight: .heavy))
                                    .frame(maxWidth: .infinity, minHeight: 50) // Taller for iOS
                                    .foregroundColor(button.title == "RANDOM" || button.title == "PRIORITY" || button.title == "TIMER" ? .white : .black)
                                    .background(
                                        ZStack {
                                            button.color
                                            Rectangle()
                                                .stroke(Color.black, lineWidth: 6) // THICK BLACK BORDER - exactly like watchOS
                                        }
                                        .clipped()
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .animation(nil, value: currentTab)
                        }
                    }
                    .padding(.horizontal, 40) // More padding for iOS
                    
                    Spacer()
                    
                    // Back button
                    Button("← BACK TO MENU") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        currentTab = "menu"
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.bottom, 60) // More padding for iOS
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width > 50 {
                        // Swipe right to go back - exactly like watchOS
                        currentTab = "menu"
                    }
                }
        )
    }
}

// Rename CalendarView to avoid conflicts
struct CalendarView_iOS: View {
    // Static method to get month background color
    static func getMonthBackgroundColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let isCurrentMonth = calendar.isDate(date, equalTo: Date(), toGranularity: .month)
        
        // Current month stays white
        if isCurrentMonth {
            return .white
        }
        
        // Other months get their darker colors
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
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @Binding var isInYearMode: Bool
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
    
    // Calculate number of calendar rows
    private var calendarRowCount: Int {
        let range = calendar.range(of: .day, in: .month, for: displayDate)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayDate))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        let totalDays = firstWeekday + range.count
        return Int(ceil(Double(totalDays) / 7.0))
    }
    
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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - colored for all months (same as watchOS)
                getDarkerMonthColor(for: displayDate)
                
                VStack(spacing: 0) {
                    // Header with month and year text
                    Text(dateFormatter.string(from: displayDate).uppercased())
                        .font(.system(size: 36, weight: .heavy)) // Same font as LIFE/WORK text
                        .foregroundColor(calendar.isDate(displayDate, equalTo: Date(), toGranularity: .month) ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40) // Move title up
                        .padding(.bottom, 180) // More space to calendar
                    
                    // Calendar grid with smaller squares
                    CalendarGridView_iOS(
                        currentDate: displayDate,
                        taskStore: taskStore,
                        selectedDate: $selectedDate,
                        isInYearMode: !calendar.isDate(displayDate, equalTo: Date(), toGranularity: .month)
                    )
                    .padding(.horizontal, {
                        #if os(iOS)
                        return UIDevice.current.userInterfaceIdiom == .pad ? 40 : 20
                        #else
                        return 40 // macOS - same padding
                        #endif
                    }()) // White border padding
                    .frame(maxHeight: geometry.size.height * 0.5) // Smaller calendar
                    .padding(.top, calendarRowCount == 6 ? 30 : 0) // Push down for 6-row calendars
                    
                    Spacer(minLength: 0) // Allow it to shrink if needed
                    
                    Spacer()
                        .frame(height: 40) // Keep bottom spacing
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
                currentTab = "dayView"
            }
        }
        .onChange(of: taskStore.longPressedDate) { oldValue, newDate in
            if newDate != nil {
                // Navigate to repeat task menu for long pressed date (same as watchOS)
                currentTab = "setRepeatTask"
            }
        }
    }
}

// Helper view to avoid conflicts
struct CalendarGridView_iOS: View {
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
                        .foregroundColor(calendar.isDate(currentDate, equalTo: Date(), toGranularity: .month) ? .gray : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar dates (same logic as watchOS)
            let dates = generateDates()
            let taskMap = tasksPerDay
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(dates.indices, id: \.self) { index in
                    let date = dates[index]
                    let dateKey = CalendarDayView_iOS.dateFormatter.string(from: date)
                    CalendarDayView_iOS(
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

struct CalendarDayView_iOS: View {
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
                    Rectangle() // Sharp corners
                        .fill(Color.green)
                )
            } else {
                // Other days without tasks - gray
                return AnyView(
                    Rectangle() // Sharp corners
                        .fill(isCurrentMonth ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                )
            }
        } else if colors.count == 1 {
            // Single color - just fill the whole square
            return AnyView(
                Rectangle()
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
                .clipped()
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
                .clipped()
            )
        } else {
            // Fallback - shouldn't reach here
            return AnyView(
                Rectangle()
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
                Rectangle()
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
    ContentView()
        .environmentObject(ThemeManager.shared)
}