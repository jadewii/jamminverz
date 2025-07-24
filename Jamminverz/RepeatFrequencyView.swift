//
//  RepeatFrequencyView.swift
//  Todomai-iOS
//
//  Select frequency for recurring tasks
//

import SwiftUI

struct RepeatFrequencyView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @State private var selectedFrequency: Frequency? = nil
    @State private var showingTaskInput = false
    @State private var taskText = ""
    @State private var selectedTime = Date()
    @State private var selectedDays: Set<String> = []
    @FocusState private var isTextFieldFocused: Bool
    
    enum Frequency {
        case daily
        case weekly(days: Set<String>)
        case monthly(day: Int)
        
        var displayName: String {
            switch self {
            case .daily:
                return "EVERY DAY"
            case .weekly(let days):
                if days.count == 1, let day = days.first {
                    return "EVERY \(day.uppercased())"
                } else {
                    return "WEEKLY"
                }
            case .monthly(let day):
                return "EVERY \(ordinalDay(day)) OF MONTH"
            }
        }
        
        private func ordinalDay(_ day: Int) -> String {
            let suffix: String
            switch day {
            case 1, 21, 31: suffix = "ST"
            case 2, 22: suffix = "ND"
            case 3, 23: suffix = "RD"
            default: suffix = "TH"
            }
            return "\(day)\(suffix)"
        }
    }
    
    private let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.4, green: 0.65, blue: 0.5) // Mint green background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    Text("REPEAT FREQUENCY")
                        .font(.system(size: geometry.size.width > 600 ? 28 : 22, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.top, geometry.safeAreaInsets.top + 20)
                        .padding(.bottom, 30)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Navigate back
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            currentTab = "setRepeatTask"
                        }
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Daily option
                            FrequencyButton(
                                title: "EVERY DAY",
                                isSelected: isSelected(.daily),
                                geometry: geometry
                            ) {
                                selectedFrequency = .daily
                                showingTaskInput = true
                            }
                            
                            // Weekly options
                            VStack(spacing: 12) {
                                Text("WEEKLY")
                                    .font(.system(size: geometry.size.width > 600 ? 18 : 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(daysOfWeek, id: \.self) { day in
                                        FrequencyButton(
                                            title: day.uppercased(),
                                            isSelected: isSelected(.weekly(days: [day])),
                                            geometry: geometry
                                        ) {
                                            selectedFrequency = .weekly(days: [day])
                                            showingTaskInput = true
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, geometry.size.width > 600 ? 40 : 20)
                            
                            // Monthly option (based on selected date)
                            if let selectedDate = taskStore.longPressedDate {
                                let day = Calendar.current.component(.day, from: selectedDate)
                                FrequencyButton(
                                    title: Frequency.monthly(day: day).displayName,
                                    isSelected: isSelected(.monthly(day: day)),
                                    geometry: geometry
                                ) {
                                    selectedFrequency = .monthly(day: day)
                                    showingTaskInput = true
                                }
                            }
                            
                            // Cancel button
                            FrequencyButton(
                                title: "CANCEL",
                                isSelected: false,
                                geometry: geometry,
                                color: .gray
                            ) {
                                taskStore.longPressedDate = nil
                                currentTab = "calendar"
                            }
                        }
                        .padding(.horizontal, geometry.size.width > 600 ? 60 : 30)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingTaskInput) {
            RepeatTaskInputSheet(
                taskStore: taskStore,
                frequency: selectedFrequency ?? .daily,
                currentTab: $currentTab,
                isPresented: $showingTaskInput
            )
        }
    }
    
    private func isSelected(_ frequency: Frequency) -> Bool {
        guard let selected = selectedFrequency else { return false }
        
        switch (selected, frequency) {
        case (.daily, .daily):
            return true
        case (.weekly(let days1), .weekly(let days2)):
            return days1 == days2
        case (.monthly(let day1), .monthly(let day2)):
            return day1 == day2
        default:
            return false
        }
    }
}

struct FrequencyButton: View {
    let title: String
    let isSelected: Bool
    let geometry: GeometryProxy
    var color: Color = Color.white
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            ZStack {
                color.opacity(isSelected ? 1.0 : 0.3)
                Rectangle()
                    .stroke(Color.white, lineWidth: geometry.size.width > 600 ? 4 : 3)
            }
            .frame(height: geometry.size.width > 600 ? 60 : 50)
            .overlay(
                Text(title)
                    .font(.system(size: geometry.size.width > 600 ? 18 : 14, weight: .heavy))
                    .foregroundColor(isSelected ? .black : .white)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RepeatTaskInputSheet: View {
    @ObservedObject var taskStore: TaskStore
    let frequency: RepeatFrequencyView.Frequency
    @Binding var currentTab: String
    @Binding var isPresented: Bool
    
    @State private var taskText = ""
    @State private var selectedTime = Date()
    @State private var hasTime = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Rectangle()
                            .fill(Color(red: 0.6, green: 0.85, blue: 0.7))
                            .frame(width: 6, height: 40)
                        
                        Text("New Recurring Task")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Frequency display
                    HStack {
                        Image(systemName: "repeat")
                            .foregroundColor(Color(red: 0.6, green: 0.85, blue: 0.7))
                        Text(frequency.displayName)
                            .font(.body)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Task input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What would you like to do?")
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
                    
                    // Time selection
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Time")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $hasTime)
                                .labelsHidden()
                        }
                        
                        if hasTime {
                            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                        }
                    }
                    .padding(.horizontal)
                    
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
                        
                        Button("Create Task") {
                            createRecurringTask()
                        }
                        .disabled(taskText.isEmpty)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(taskText.isEmpty ? Color.gray : Color(red: 0.6, green: 0.85, blue: 0.7))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func createRecurringTask() {
        guard !taskText.isEmpty else { return }
        
        var taskTextWithFrequency = taskText
        
        // Add frequency info to task text
        switch frequency {
        case .daily:
            taskTextWithFrequency += " (Every day)"
        case .weekly(let days):
            if let day = days.first {
                taskTextWithFrequency += " (Every \(day))"
            }
        case .monthly(let day):
            let suffix: String
            switch day {
            case 1, 21, 31: suffix = "st"
            case 2, 22: suffix = "nd"
            case 3, 23: suffix = "rd"
            default: suffix = "th"
            }
            taskTextWithFrequency += " (Every \(day)\(suffix))"
        }
        
        var task = Task(
            text: taskTextWithFrequency,
            listId: "today", // Recurring tasks typically go to today list
            mode: taskStore.currentMode.rawValue
        )
        task.isRecurring = true
        
        if hasTime {
            task.dueDate = selectedTime
            // Note: recurringTime is stored in dueDate for recurring tasks
        }
        
        // Note: We store recurring info in the task text for now
        // since Task model doesn't have recurringDays property
        
        taskStore.tasks.insert(task, at: 0)
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isPresented = false
        currentTab = "today"
    }
}

#Preview {
    RepeatFrequencyView(taskStore: TaskStore(), currentTab: .constant("repeatFrequency"))
}