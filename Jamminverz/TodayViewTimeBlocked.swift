import SwiftUI

// MARK: - Time Block Model
struct TimeBlock: Identifiable {
    let id = UUID()
    var taskId: String
    var startTime: Date
    var duration: Int // in minutes
    var color: Color
}

// MARK: - Enhanced Today View with Time Blocking
struct TodayViewTimeBlocked: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @State private var timeBlocks: [TimeBlock] = []
    @State private var draggedTask: Task? = nil
    
    let hours = Array(6...22) // 6am to 10pm
    let hourHeight: CGFloat = 80
    
    var todayTasks: [Task] {
        taskStore.tasks.filter { task in
            task.listId == "today" && 
            task.mode == taskStore.currentMode.rawValue && 
            !task.isCompleted &&
            !timeBlocks.contains(where: { $0.taskId == task.id.uuidString })
        }
    }
    
    var scheduledTasks: [Task] {
        taskStore.tasks.filter { task in
            timeBlocks.contains(where: { $0.taskId == task.id.uuidString })
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // White background
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Timeline view
                    timelineView
                }
                
                // Floating mic button
                floatingMicButton
            }
        }
        .onAppear {
            loadDemoTimeBlocks()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            Text(getDayName())
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(.black)
            
            Text(getCurrentDate())
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
        .padding(.bottom, 20)
        .background(Color.white)
    }
    
    // MARK: - Need Scheduling View
    private var needSchedulingView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Text("NEED SCHEDULING")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.black.opacity(0.6))
                
                Text("(\(todayTasks.count))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black.opacity(0.4))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            
            // Horizontal scroll of tasks
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(todayTasks) { task in
                        TaskCard(task: task, taskStore: taskStore)
                            .onDrag {
                                self.draggedTask = task
                                return NSItemProvider(object: task.id.uuidString as NSString)
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        .frame(height: 140)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No scheduled tasks")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Drag tasks from above to schedule them")
                .font(.system(size: 16))
                .foregroundColor(.gray.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    
    // MARK: - Timeline View
    private var timelineView: some View {
        Group {
            if timeBlocks.isEmpty && todayTasks.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        // Hour grid
                        VStack(spacing: 0) {
                            ForEach(hours, id: \.self) { hour in
                                HourRow(hour: hour, hourHeight: hourHeight)
                                    .onDrop(of: [.text], delegate: TimeSlotDropDelegate(
                                        hour: hour,
                                        timeBlocks: $timeBlocks,
                                        draggedTask: $draggedTask,
                                        taskStore: taskStore
                                    ))
                            }
                        }
                        
                        // Time blocks overlay
                        ForEach(timeBlocks) { block in
                            if let task = taskStore.tasks.first(where: { $0.id.uuidString == block.taskId }) {
                                TimeBlockView(
                                    block: block,
                                    task: task,
                                    hourHeight: hourHeight,
                                    onDelete: {
                                        withAnimation {
                                            timeBlocks.removeAll { $0.id == block.id }
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    // MARK: - Floating Mic Button
    private var floatingMicButton: some View {
        EmptyView() // Removed - tasks should be added in TO-DO LIST
    }
    
    // MARK: - Helper Methods
    private func getDayName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date()).uppercased()
    }
    
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    private func loadDemoTimeBlocks() {
        let calendar = Calendar.current
        let today = Date()
        let dayOfWeek = calendar.component(.weekday, from: today)
        
        // Add recurring tasks based on day of week
        // Sunday = 1, Monday = 2, Tuesday = 3, etc.
        
        // Every day - Morning routine
        if let morningRoutine = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today) {
            addTimeBlock("Morning routine", at: morningRoutine, duration: 30, color: Color(red: 0.4, green: 0.8, blue: 1.0))
        }
        
        // Tuesday (3) - Yoga at 11am
        if dayOfWeek == 3 {
            if let yogaTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: today) {
                addTimeBlock("Yoga class", at: yogaTime, duration: 60, color: Color(red: 0.6, green: 0.8, blue: 0.4))
            }
        }
        
        // Monday, Wednesday, Friday - Gym at 6:30am
        if [2, 4, 6].contains(dayOfWeek) {
            if let gymTime = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: today) {
                addTimeBlock("Gym workout", at: gymTime, duration: 60, color: Color.orange)
            }
        }
        
        // Weekdays - Work block
        if dayOfWeek >= 2 && dayOfWeek <= 6 {
            if let workStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) {
                addTimeBlock("Work - Deep focus", at: workStart, duration: 120, color: Color(red: 0.4, green: 0.6, blue: 1.0))
            }
            
            if let lunchTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today) {
                addTimeBlock("Lunch break", at: lunchTime, duration: 60, color: Color(red: 0.8, green: 0.8, blue: 0.8))
            }
            
            if let afternoonWork = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today) {
                addTimeBlock("Work - Meetings", at: afternoonWork, duration: 120, color: Color(red: 0.4, green: 0.6, blue: 1.0))
            }
        }
        
        // Thursday - Team standup at 10am
        if dayOfWeek == 5 {
            if let standupTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today) {
                addTimeBlock("Team standup", at: standupTime, duration: 30, color: Color(red: 0.8, green: 0.6, blue: 1.0))
            }
        }
    }
    
    private func addTimeBlock(_ title: String, at startTime: Date, duration: Int, color: Color) {
        // Create a temporary task for the time block
        let taskId = UUID().uuidString
        let block = TimeBlock(
            taskId: taskId,
            startTime: startTime,
            duration: duration,
            color: color
        )
        
        // Add the task to the store temporarily
        let task = Task(text: title, listId: "scheduled", mode: taskStore.currentMode.rawValue)
        taskStore.tasks.append(task)
        
        // Update block with real task ID
        var updatedBlock = block
        updatedBlock.taskId = task.id.uuidString
        timeBlocks.append(updatedBlock)
    }
    
    // Accept drops from external sources (TO-DO LIST)
    func acceptDrop(info: DropInfo) -> Bool {
        // This will handle drops from TO-DO LIST
        return true
    }
}

// MARK: - Task Card
struct TaskCard: View {
    let task: Task
    let taskStore: TaskStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                Spacer()
            }
            
            Text(task.text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
                .lineLimit(2)
                .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(12)
        .frame(width: 160, height: 90)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.black, lineWidth: 2)
        )
    }
}

// MARK: - Hour Row
struct HourRow: View {
    let hour: Int
    let hourHeight: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            // Hour label
            Text("\(hour):00")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 60, alignment: .trailing)
                .padding(.trailing, 12)
            
            // Hour line
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .frame(height: hourHeight)
        .background(Color.white.opacity(0.01)) // Invisible but makes it droppable
    }
}

// MARK: - Time Block View
struct TimeBlockView: View {
    let block: TimeBlock
    let task: Task
    let hourHeight: CGFloat
    let onDelete: () -> Void
    
    var offset: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: block.startTime)
        let minute = calendar.component(.minute, from: block.startTime)
        let hourOffset = CGFloat(hour - 6) * hourHeight
        let minuteOffset = CGFloat(minute) / 60.0 * hourHeight
        return hourOffset + minuteOffset
    }
    
    var height: CGFloat {
        CGFloat(block.duration) / 60.0 * hourHeight
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Time block
            VStack(alignment: .leading, spacing: 4) {
                Text(task.text)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text("\(block.duration) min")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: height, alignment: .topLeading)
            .background(block.color)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 2)
            )
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black))
            }
            .offset(x: 8, y: -8)
        }
        .offset(x: 72, y: offset)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Drop Delegate
struct TimeSlotDropDelegate: DropDelegate {
    let hour: Int
    @Binding var timeBlocks: [TimeBlock]
    @Binding var draggedTask: Task?
    let taskStore: TaskStore
    
    func performDrop(info: DropInfo) -> Bool {
        guard let task = draggedTask else { return false }
        
        let calendar = Calendar.current
        let today = Date()
        
        if let scheduledTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: today) {
            let newBlock = TimeBlock(
                taskId: task.id.uuidString,
                startTime: scheduledTime,
                duration: 30, // Default 30 minutes
                color: getColorForTask(task)
            )
            
            withAnimation {
                timeBlocks.append(newBlock)
            }
            
            draggedTask = nil
            return true
        }
        
        return false
    }
    
    private func getColorForTask(_ task: Task) -> Color {
        // Assign colors based on task or use mode colors
        switch taskStore.currentMode {
        case .life:
            return Color(red: 0.4, green: 0.8, blue: 1.0)
        case .work:
            return Color.orange
        case .school:
            return Color(red: 0.6, green: 0.4, blue: 1.0)
        }
    }
}