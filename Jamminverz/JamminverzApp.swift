//
//  JamminverzApp.swift
//  JAMVERZ
//
//  Created by jade on 7/10/25.
//

import SwiftUI
import AVFoundation

@main
struct JamminverzApp: App {
    @StateObject private var taskStore = TaskStore()
    @StateObject private var artStoreManager = ArtStoreManager.shared
    @StateObject private var paymentManager = PaymentManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskStore)
                .environmentObject(artStoreManager)
                .environmentObject(paymentManager)
                .environmentObject(themeManager)
                .frame(minWidth: 1200, minHeight: 800)
        }
        #if os(macOS)
        .windowStyle(HiddenTitleBarWindowStyle())
        .defaultSize(width: 1920, height: 1080)
        .commands {
            // Add keyboard shortcuts for macOS
            CommandGroup(replacing: .newItem) {
                Button("New Album") {
                    // TODO: Implement new album creation
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        #endif
    }
}

struct Task: Identifiable, Codable {
    let id: UUID
    var text: String
    var isCompleted: Bool
    var createdAt: Date
    var listId: String
    var mode: String
    var dueDate: Date?
    var assignedTo: String?
    var isRecurring: Bool
    var comments: [String]
    var rewardStars: Int
    var hasReminder: Bool
    var reminderMinutesBefore: Int?
    
    init(text: String, isCompleted: Bool = false, listId: String = "today", mode: String = "life") {
        self.id = UUID()
        self.text = text
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.listId = listId
        self.mode = mode
        self.dueDate = nil
        self.assignedTo = nil
        self.isRecurring = false
        self.comments = []
        self.rewardStars = 0
        self.hasReminder = false
        self.reminderMinutesBefore = nil
    }
    
    var urgencyColor: Color {
        guard let dueDate = dueDate else { return .white }
        
        let now = Date()
        let calendar = Calendar.current
        
        if dueDate < now {
            return .red // Overdue
        } else if calendar.isDateInToday(dueDate) {
            return .orange // Due today
        } else if calendar.isDate(dueDate, equalTo: now, toGranularity: .weekOfYear) {
            return .yellow // Due this week
        } else {
            return .white // No urgency
        }
    }
}

struct TaskList: Identifiable, Codable {
    let id: String
    var name: String
    var color: Color.RGBValues
    
    var swiftUIColor: Color {
        Color(red: color.red, green: color.green, blue: color.blue)
    }
}

// Music-focused system (simplified from 4-Mode)
enum ViewMode: String, CaseIterable, Codable {
    case life = "life"
    case work = "work"
    case school = "school"
    
    var displayName: String {
        return "JAde Wii" // Always show username instead of mode
    }
    
    var modeButtonColor: Color {
        return Color(red: 0.373, green: 0.275, blue: 0.569) // Rich vibrant purple
    }
    
    func getListIds() -> [String] {
        // Return three buttons: TODAY, THIS WEEK, and SCHEDULED (SOMEDAY is hidden)
        return ["today", "thisWeek", "done"]
    }
    
    func getListName(for id: String) -> String {
        switch id {
        case "today": return "TODAY"
        case "thisWeek": return "THIS WEEK"
        case "later": return "TO-DO LIST"
        case "done": return "CALENDAR"
        default: return id.uppercased()
        }
    }
    
    func getListColor(for id: String) -> Color {
        // Unified color scheme for music app
        switch id {
        case "today": return Color(red: 0.373, green: 0.275, blue: 0.569) // Rich vibrant purple
        case "thisWeek": return Color(red: 0.8, green: 0.6, blue: 1.0) // Light purple
        case "later": return Color(red: 1.0, green: 0.9, blue: 0.4) // Yellow hint
        case "done": return Color(red: 1.0, green: 0.7, blue: 0.8) // Pink hint
        default: return Color.white // White default
        }
    }
    
    func getSecondPageButtons() -> [(title: String, color: Color)] {
        // Simplified music-focused buttons with unified theme
        return [
            ("ORGANIZE", Color.white),
            ("SAMPLES", Color(red: 1.0, green: 0.9, blue: 0.4)), // Yellow hint
            ("PLAYLISTS", Color(red: 1.0, green: 0.7, blue: 0.8)), // Pink hint
            ("PROFILE", Color.purple)
        ]
    }
}

extension Color {
    struct RGBValues: Codable {
        let red: Double
        let green: Double
        let blue: Double
    }
    
    init(rgbValues: RGBValues) {
        self.init(red: rgbValues.red, green: rgbValues.green, blue: rgbValues.blue)
    }
}

class TaskStore: ObservableObject {
    // Speech synthesizer for notifications
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    func speakNotification(_ message: String) {
        let utterance = AVSpeechUtterance(string: message)
        utterance.rate = 0.5
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
    @Published var tasks: [Task] = [] {
        didSet { saveTasks() }
    }
    
    @Published var lists: [TaskList] = [] {
        didSet { saveLists() }
    }
    
    @Published var currentListId: String = "menu"
    @Published var selectedSampleForEdit: Sample?
    @Published var currentMode: ViewMode = .life {
        didSet {
            UserDefaults.standard.set(currentMode.rawValue, forKey: "currentViewMode")
            updateListsForMode()
        }
    }
    @Published var selectedCalendarDate: Date? = nil
    @Published var calendarDisplayDate: Date = Date()
    @Published var longPressedDate: Date? = nil
    @Published var repeatTaskText: String = ""
    @Published var selectedTemplate: String? = nil
    @Published var taskToEdit: Task? = nil
    @Published var isTimeBlockingEnabled: Bool = false
    @Published var isDailyScheduleEnabled: Bool = false
    @Published var workClockInTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @Published var workClockOutTime: Date = Calendar.current.date(from: DateComponents(hour: 10, minute: 0)) ?? Date()
    @Published var isWorkCalendarBlockingEnabled: Bool = false
    @Published var schoolStartTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @Published var schoolEndTime: Date = Calendar.current.date(from: DateComponents(hour: 15, minute: 0)) ?? Date()
    @Published var schoolDays: Set<Int> = [1, 2, 3, 4, 5] // Monday through Friday
    @Published var studyStartTime: Date = Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? Date()
    @Published var studyEndTime: Date = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    @Published var isStudyTimeCalendarLockEnabled: Bool = false
    @Published var studyDays: Set<Int> = [1, 2, 3, 4, 5] // Monday through Friday (0=Sunday, 6=Saturday)
    
    private let userDefaults = UserDefaults.standard
    private let tasksKey = "todomaiTasks"
    private let listsKey = "todomaiLists"
    
    init() {
        // Load saved mode IMMEDIATELY to prevent flash
        if let savedMode = userDefaults.string(forKey: "currentViewMode"),
           let mode = ViewMode(rawValue: savedMode) {
            currentMode = mode
        }
        
        // Ensure no task is being edited on startup
        taskToEdit = nil
        
        // Minimal initialization for faster startup
        updateListsForMode() // Set up lists immediately
        
        // TEMPORARY: Force clear all test data
        userDefaults.removeObject(forKey: tasksKey)
        userDefaults.synchronize()
        
        // Add realistic dummy tasks for demonstration
        addDemoTasks()
        
        // Defer heavy operations
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Load saved tasks in production mode
            self.loadTasks()
            
            // Filter out any tasks with [TEST] in them
            self.tasks = self.tasks.filter { task in
                !task.text.contains("[TEST]")
            }
            
            // Save the cleaned tasks
            if !self.tasks.isEmpty {
                self.saveTasks()
            }
        }
    }
    
    private func updateListsForMode() {
        let listIds = currentMode.getListIds()
        lists = listIds.map { id in
            let name = currentMode.getListName(for: id)
            // Color is determined by id in the switch below
            
            // Convert SwiftUI Color to RGB values - use the mode's color logic
            let color = currentMode.getListColor(for: id)
            
            // Convert SwiftUI Color to RGB values
            let rgbValues: Color.RGBValues
            if color == .blue {
                rgbValues = Color.RGBValues(red: 0.0, green: 0.478, blue: 1.0)
            } else if color == .red {
                rgbValues = Color.RGBValues(red: 1.0, green: 0.0, blue: 0.0)
            } else if color == .green {
                rgbValues = Color.RGBValues(red: 0.0, green: 0.8, blue: 0.0)
            } else if color == .orange {
                rgbValues = Color.RGBValues(red: 1.0, green: 0.6, blue: 0.0)
            } else if color == .purple {
                rgbValues = Color.RGBValues(red: 0.6, green: 0.0, blue: 1.0)
            } else if color == .white {
                rgbValues = Color.RGBValues(red: 1.0, green: 1.0, blue: 1.0)
            } else if color == Color(red: 0.859, green: 0.835, blue: 0.145) {
                rgbValues = Color.RGBValues(red: 0.859, green: 0.835, blue: 0.145) // Yellow
            } else {
                // Extract RGB from the color - this handles custom colors
                rgbValues = Color.RGBValues(red: 0.5, green: 0.5, blue: 0.5) // Gray fallback
            }
            
            return TaskList(id: id, name: name, color: rgbValues)
        }
    }
    
    var currentList: TaskList? {
        lists.first { $0.id == currentListId }
    }
    
    var currentTasks: [Task] {
        tasks.filter { $0.listId == currentListId && $0.mode == currentMode.rawValue && !$0.isCompleted }
    }
    
    var completedTasks: [Task] {
        tasks.filter { $0.listId == currentListId && $0.mode == currentMode.rawValue && $0.isCompleted }
    }
    
    func processVoiceInput(_ text: String) {
        let lowercased = text.lowercased()
        let validListIds = currentMode.getListIds()
        
        // Smart parsing for list detection based on current mode
        if lowercased.contains("today") && validListIds.contains("today") {
            currentListId = "today"
            addTask(cleanTaskText(text, listName: "today"))
        } else if currentMode == .life && (lowercased.contains("later") || lowercased.contains("someday")) {
            currentListId = "later"
            addTask(cleanTaskText(text, listName: "someday"))
        } else if currentMode == .life && lowercased.contains("done") {
            currentListId = "done"
            addTask(cleanTaskText(text, listName: "done"))
        } else if currentMode == .work && lowercased.contains("week") {
            currentListId = "week"
            addTask(cleanTaskText(text, listName: "week"))
        } else if currentMode == .work && lowercased.contains("month") {
            currentListId = "month"
            addTask(cleanTaskText(text, listName: "month"))
        } else if currentMode == .school && lowercased.contains("assignments") {
            currentListId = "assignments"
            addTask(cleanTaskText(text, listName: "assignments"))
        } else if currentMode == .school && lowercased.contains("exams") {
            currentListId = "exams"
            addTask(cleanTaskText(text, listName: "exams"))
        } else {
            // Add to current list
            addTask(text)
        }
    }
    
    private func cleanTaskText(_ text: String, listName: String) -> String {
        var cleaned = text
        let phrasesToRemove = [
            "add ", "to \(listName)", "to my \(listName) list", 
            "to the \(listName) list", "to \(listName) list"
        ]
        
        for phrase in phrasesToRemove {
            cleaned = cleaned.replacingOccurrences(of: phrase, with: "", options: .caseInsensitive)
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func addTask(_ text: String) {
        var taskText = text
        var dueDate: Date? = nil
        
        // Parse time from text
        let timePatterns = [
            // Match "at 3:30", "at 3:30pm", "at 15:30"
            #"at\s+(\d{1,2}):(\d{2})\s*(am|pm)?"#,
            // Match "3:30pm", "15:30", "3:30 pm" - must be word boundary to avoid matching in middle
            #"\b(\d{1,2}):(\d{2})\s*(am|pm)?"#,
            // Match "at 3pm", "at 3 pm"
            #"at\s+(\d{1,2})\s*(am|pm)"#,
            // Match "3pm", "3 pm"
            #"\b(\d{1,2})\s*(am|pm)"#
        ]
        
        for pattern in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = text as NSString
                if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsString.length)) {
                    // Remove the time part from the task text
                    taskText = nsString.replacingCharacters(in: match.range, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Parse the time
                    let calendar = Calendar.current
                    var components = calendar.dateComponents([.year, .month, .day], from: Date())
                    
                    if match.numberOfRanges >= 3 {
                        // Has hour and minute
                        if let hourRange = Range(match.range(at: 1), in: text),
                           let hour = Int(text[hourRange]) {
                            components.hour = hour
                            
                            if match.numberOfRanges >= 3,
                               let minuteRange = Range(match.range(at: 2), in: text),
                               let minute = Int(text[minuteRange]) {
                                components.minute = minute
                            } else {
                                components.minute = 0
                            }
                            
                            // Check for AM/PM
                            if match.numberOfRanges >= 4 {
                                let lastGroup = match.numberOfRanges - 1
                                if let ampmRange = Range(match.range(at: lastGroup), in: text) {
                                    let ampm = text[ampmRange].lowercased()
                                    if ampm == "pm" && components.hour! < 12 {
                                        components.hour! += 12
                                    } else if ampm == "am" && components.hour! == 12 {
                                        components.hour = 0
                                    }
                                }
                            }
                        }
                    } else if match.numberOfRanges >= 2 {
                        // Just hour with AM/PM
                        if let hourRange = Range(match.range(at: 1), in: text),
                           let hour = Int(text[hourRange]) {
                            components.hour = hour
                            components.minute = 0
                            
                            if let ampmRange = Range(match.range(at: 2), in: text) {
                                let ampm = text[ampmRange].lowercased()
                                if ampm == "pm" && hour < 12 {
                                    components.hour! += 12
                                } else if ampm == "am" && hour == 12 {
                                    components.hour = 0
                                }
                            }
                        }
                    }
                    
                    dueDate = calendar.date(from: components)
                    break
                }
            }
        }
        
        var task = Task(text: taskText, listId: currentListId, mode: currentMode.rawValue)
        
        // If no specific time was parsed but task is for "today", set due date to today
        if dueDate == nil && currentListId == "today" {
            dueDate = Date()
        }
        
        task.dueDate = dueDate
        tasks.insert(task, at: 0)
    }
    
    func addList(_ name: String) {
        let colors: [Color.RGBValues] = [
            Color.RGBValues(red: 1.0, green: 0.95, blue: 0.95),
            Color.RGBValues(red: 0.95, green: 0.95, blue: 1.0),
            Color.RGBValues(red: 0.95, green: 1.0, blue: 0.95),
            Color.RGBValues(red: 1.0, green: 1.0, blue: 0.95),
            Color.RGBValues(red: 1.0, green: 0.95, blue: 1.0),
            Color.RGBValues(red: 0.95, green: 1.0, blue: 1.0)
        ]
        
        let colorIndex = lists.count % colors.count
        let newList = TaskList(id: UUID().uuidString, name: name, color: colors[colorIndex])
        lists.append(newList)
    }
    
    func deleteTask(at offsets: IndexSet) {
        let tasksToDelete = offsets.map { currentTasks[$0] }
        tasks.removeAll { task in
            tasksToDelete.contains { $0.id == task.id }
        }
    }
    
    func toggleTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            if tasks[index].isCompleted {
                // Say "Task completed" using text-to-speech
                let utterance = AVSpeechUtterance(string: "Task completed")
                utterance.rate = 0.5
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                
                let synthesizer = AVSpeechSynthesizer()
                synthesizer.speak(utterance)
            }
        }
    }
    
    func clearCompleted() {
        tasks.removeAll { $0.isCompleted && $0.listId == currentListId }
    }
    
    func moveTaskToToday(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].listId = "today"
        }
    }
    
    func cycleThroughModes() {
        let allModes = ViewMode.allCases
        if let currentIndex = allModes.firstIndex(of: currentMode) {
            let nextIndex = (currentIndex + 1) % allModes.count
            currentMode = allModes[nextIndex]
        }
    }
    
    func navigateToNextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: calendarDisplayDate) {
            calendarDisplayDate = newDate
        }
    }
    
    func navigateToPreviousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: calendarDisplayDate) {
            calendarDisplayDate = newDate
        }
    }
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encoded, forKey: tasksKey)
        }
    }
    
    private func saveLists() {
        if let encoded = try? JSONEncoder().encode(lists) {
            userDefaults.set(encoded, forKey: listsKey)
        }
    }
    
    private func loadTasks() {
        if let data = userDefaults.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decoded
        }
    }
    
    private func loadData() {
        loadTasks()
        
        if let data = userDefaults.data(forKey: listsKey),
           let decoded = try? JSONDecoder().decode([TaskList].self, from: data) {
            lists = decoded
        }
    }
    
    func removeTestPrefixes() {
        // Remove [TEST] prefix from all task names
        var tasksUpdated = false
        for i in 0..<tasks.count {
            if tasks[i].text.hasPrefix("[TEST] ") {
                tasks[i].text = String(tasks[i].text.dropFirst(7))
                tasksUpdated = true
            }
        }
        // Save the cleaned tasks if any were updated
        if tasksUpdated {
            saveTasks()
        }
    }
    
    func clearAllTestData() {
        // Clear all tasks that have [TEST] in their text
        tasks = tasks.filter { !$0.text.contains("[TEST]") }
        // Also remove the prefix from remaining tasks
        removeTestPrefixes()
        saveTasks()
    }
    
    private func addDemoTasks() {
        let calendar = Calendar.current
        let today = Date()
        
        // TODAY tasks
        tasks.append(Task(text: "Morning meditation 15 minutes", listId: "today", mode: "life"))
        tasks.append(Task(text: "Review quarterly budget report", listId: "today", mode: "work"))
        tasks.append(Task(text: "Grocery shopping for dinner party", listId: "today", mode: "life"))
        tasks.append(Task(text: "Call dentist to schedule appointment", listId: "today", mode: "life"))
        tasks.append(Task(text: "Finish Chapter 5 reading assignment", listId: "today", mode: "school"))
        
        // THIS WEEK tasks
        tasks.append(Task(text: "Prepare presentation for Monday meeting", listId: "thisWeek", mode: "work"))
        tasks.append(Task(text: "Submit expense reports", listId: "thisWeek", mode: "work"))
        tasks.append(Task(text: "Book flights for summer vacation", listId: "thisWeek", mode: "life"))
        tasks.append(Task(text: "Complete online certification course", listId: "thisWeek", mode: "work"))
        tasks.append(Task(text: "Organize garage storage", listId: "thisWeek", mode: "life"))
        
        // TO-DO LIST (later) tasks
        tasks.append(Task(text: "Learn Spanish on Duolingo", listId: "later", mode: "life"))
        tasks.append(Task(text: "Read 'Atomic Habits' book", listId: "later", mode: "life"))
        tasks.append(Task(text: "Plan weekend hiking trip", listId: "later", mode: "life"))
        tasks.append(Task(text: "Research new investment opportunities", listId: "later", mode: "work"))
        tasks.append(Task(text: "Update LinkedIn profile", listId: "later", mode: "work"))
        tasks.append(Task(text: "Start personal blog", listId: "later", mode: "life"))
        tasks.append(Task(text: "Learn to cook Thai cuisine", listId: "later", mode: "life"))
        tasks.append(Task(text: "Organize photo library", listId: "later", mode: "life"))
        
        // Calendar tasks with specific dates
        if let date1 = calendar.date(from: DateComponents(year: 2025, month: 7, day: 23)) {
            var task = Task(text: "Team building workshop", listId: "calendar_2025-07-23", mode: "work")
            task.dueDate = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date1)
            tasks.append(task)
        }
        
        if let date2 = calendar.date(from: DateComponents(year: 2025, month: 7, day: 25)) {
            var task = Task(text: "Doctor's appointment", listId: "calendar_2025-07-25", mode: "life")
            task.dueDate = calendar.date(bySettingHour: 10, minute: 30, second: 0, of: date2)
            task.hasReminder = true
            task.reminderMinutesBefore = 60
            tasks.append(task)
        }
        
        if let date3 = calendar.date(from: DateComponents(year: 2025, month: 7, day: 28)) {
            var task = Task(text: "Project deadline - Marketing campaign", listId: "calendar_2025-07-28_deadline", mode: "work")
            task.dueDate = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: date3)
            tasks.append(task)
        }
        
        if let date4 = calendar.date(from: DateComponents(year: 2025, month: 8, day: 1)) {
            var task = Task(text: "Rent payment due", listId: "calendar_2025-08-01_deadline", mode: "life")
            task.dueDate = date4
            tasks.append(task)
        }
        
        if let date5 = calendar.date(from: DateComponents(year: 2025, month: 8, day: 5)) {
            var task = Task(text: "Birthday party for Sarah", listId: "calendar_2025-08-05", mode: "life")
            task.dueDate = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date5)
            tasks.append(task)
        }
        
        // Recurring tasks
        var weeklyTask = Task(text: "Weekly team sync Every Monday", listId: "calendar_2025-07-21_recurring", mode: "work")
        weeklyTask.dueDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today)
        weeklyTask.isRecurring = true
        tasks.append(weeklyTask)
        
        var gymTask = Task(text: "Gym workout Every Tuesday", listId: "calendar_2025-07-22_recurring", mode: "life")
        gymTask.dueDate = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today)
        gymTask.isRecurring = true
        tasks.append(gymTask)
        
        var yogaTask = Task(text: "Yoga class Every Thursday", listId: "calendar_2025-07-24_recurring", mode: "life")
        yogaTask.dueDate = calendar.date(bySettingHour: 18, minute: 30, second: 0, of: today)
        yogaTask.isRecurring = true
        tasks.append(yogaTask)
        
        // School mode tasks
        if currentMode == .school {
            tasks.append(Task(text: "Math homework - Chapter 7", listId: "assignments", mode: "school"))
            tasks.append(Task(text: "Biology lab report", listId: "assignments", mode: "school"))
            tasks.append(Task(text: "History essay on Civil War", listId: "assignments", mode: "school"))
            tasks.append(Task(text: "Chemistry midterm", listId: "exams", mode: "school"))
            tasks.append(Task(text: "English literature final", listId: "exams", mode: "school"))
        }
        
        // Work mode specific
        if currentMode == .work {
            tasks.append(Task(text: "Q3 revenue projections", listId: "projects", mode: "work"))
            tasks.append(Task(text: "Client proposal for ABC Corp", listId: "deadlines", mode: "work"))
            tasks.append(Task(text: "Performance review preparations", listId: "schedule", mode: "work"))
            tasks.append(Task(text: "New product feature brainstorm", listId: "ideas", mode: "work"))
        }
        
        // ROUTINES
        tasks.append(Task(text: "Morning skincare routine", listId: "routines", mode: "life"))
        tasks.append(Task(text: "Evening meditation", listId: "routines", mode: "life"))
        tasks.append(Task(text: "Daily journal writing", listId: "routines", mode: "life"))
        tasks.append(Task(text: "Water plants", listId: "routines", mode: "life"))
        
        // APPOINTMENTS
        var appointment1 = Task(text: "Hair salon appointment", listId: "appointments", mode: "life")
        appointment1.dueDate = calendar.date(from: DateComponents(year: 2025, month: 7, day: 26, hour: 15, minute: 0))
        tasks.append(appointment1)
        
        var appointment2 = Task(text: "Car service", listId: "appointments", mode: "life")
        appointment2.dueDate = calendar.date(from: DateComponents(year: 2025, month: 8, day: 3, hour: 9, minute: 0))
        tasks.append(appointment2)
        
        var appointment3 = Task(text: "Annual health checkup", listId: "appointments", mode: "life")
        appointment3.dueDate = calendar.date(from: DateComponents(year: 2025, month: 8, day: 10, hour: 11, minute: 30))
        appointment3.hasReminder = true
        appointment3.reminderMinutesBefore = 120
        tasks.append(appointment3)
    }
}