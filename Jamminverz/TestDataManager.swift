//
//  TestDataManager.swift
//  Todomai Watch App
//
//  Created by Claude on 7/14/25.
//

import Foundation
import SwiftUI

class TestDataManager {
    // IMPORTANT: Toggle this to false to disable all test data
    // When false, no test data will be created and the app will use real user data only
    static let isTestModeEnabled = false
    
    static func populateTestData(for taskStore: TaskStore) {
        guard isTestModeEnabled else { return }
        
        // Clear ALL tasks to ensure no duplicates
        taskStore.tasks.removeAll()
        
        // Clear any persisted data
        UserDefaults.standard.removeObject(forKey: "todomaiTasks")
        
        let calendar = Calendar.current
        let now = Date()
        
        // LIFE MODE TEST DATA
        populateLifeModeData(taskStore: taskStore, calendar: calendar, now: now)
        
        // WORK MODE TEST DATA
        populateWorkModeData(taskStore: taskStore, calendar: calendar, now: now)
        
        // SCHOOL MODE TEST DATA
        populateSchoolModeData(taskStore: taskStore, calendar: calendar, now: now)
        
        // ADD MULTI-TYPE TASKS FOR TESTING SPLIT SQUARES
        addMultiTypeTestData(taskStore: taskStore, calendar: calendar, now: now)
        
        print("Total tasks created: \(taskStore.tasks.count)")
        print("Life tasks: \(taskStore.tasks.filter { $0.mode == "life" }.count)")
        print("Work tasks: \(taskStore.tasks.filter { $0.mode == "work" }.count)")
        print("School tasks: \(taskStore.tasks.filter { $0.mode == "school" }.count)")
    }
    
    // MARK: - LIFE Mode Data
    private static func populateLifeModeData(taskStore: TaskStore, calendar: Calendar, now: Date) {
        // TODAY - Maximum 4 tasks
        let lifeTodayTasks = [
            "Call dentist for appointment",
            "Buy groceries - milk, eggs, bread",
            "Walk Luna before sunset",
            "Pay electricity bill"
        ]
        
        for taskText in lifeTodayTasks {
            taskStore.tasks.append(Task(text: taskText, listId: "today", mode: "life"))
        }
        
        // LATER - Maximum 4 tasks
        let lifeLaterTasks = [
            "Organize photo albums",
            "Research vacation spots",
            "Learn guitar basics",
            "Plan Sarah's birthday"
        ]
        
        for taskText in lifeLaterTasks {
            taskStore.tasks.append(Task(text: taskText, listId: "later", mode: "life"))
        }
        
        // SCHEDULED - Spread across calendar
        // Tomorrow - 2 tasks
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            let yogaTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: tomorrow)!
            var yogaTask = Task(text: "Yoga class", listId: "done", mode: "life")
            yogaTask.dueDate = yogaTime
            taskStore.tasks.append(yogaTask)
        }
        
        // Next Thursday - Dinner
        if let nextThursday = getNextWeekday(5, from: now, calendar: calendar) {
            let dinnerTime = calendar.date(bySettingHour: 19, minute: 30, second: 0, of: nextThursday)!
            var dinnerTask = Task(text: "Dinner with Johnny", listId: "done", mode: "life")
            dinnerTask.dueDate = dinnerTime
            taskStore.tasks.append(dinnerTask)
        }
        
        // Next week - Dentist
        if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now) {
            let dentistTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: nextWeek)!
            var dentistTask = Task(text: "Dentist cleaning", listId: "done", mode: "life")
            dentistTask.dueDate = dentistTime
            taskStore.tasks.append(dentistTask)
        }
        
        // Next month - Annual checkup
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) {
            let checkupTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: nextMonth)!
            var checkupTask = Task(text: "Annual physical", listId: "done", mode: "life")
            checkupTask.dueDate = checkupTime
            taskStore.tasks.append(checkupTask)
        }
        
        // Add tasks in past months for calendar testing
        if let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) {
            // Task from last month
            let pastMeetingTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: lastMonth)!
            var pastMeetingTask = Task(text: "Team planning session", listId: "today", mode: "life")
            pastMeetingTask.dueDate = pastMeetingTime
            taskStore.tasks.append(pastMeetingTask)
            
            // Another task in last month
            if let midLastMonth = calendar.date(byAdding: .day, value: 15, to: calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonth))!) {
                let birthdayTime = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: midLastMonth)!
                var birthdayTask = Task(text: "Mom's birthday party", listId: "today", mode: "life")
                birthdayTask.dueDate = birthdayTime
                taskStore.tasks.append(birthdayTask)
            }
        }
        
        // Add tasks in future months
        if let twoMonthsAhead = calendar.date(byAdding: .month, value: 2, to: now) {
            let vacationTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: twoMonthsAhead)!
            var vacationTask = Task(text: "Hawaii vacation starts", listId: "later", mode: "life")
            vacationTask.dueDate = vacationTime
            taskStore.tasks.append(vacationTask)
        }
        
        // Add recurring weekly tasks
        for weekOffset in 1...4 {
            if let futureWeek = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: now) {
                let weeklyMeetingTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: futureWeek)!
                var weeklyTask = Task(text: "Weekly team sync", listId: "today", mode: "life")
                weeklyTask.dueDate = weeklyMeetingTime
                taskStore.tasks.append(weeklyTask)
            }
        }
        
        // Add calendar events with specific times across different months
        // Go through past 6 months and future 6 months
        for monthOffset in -6...6 {
            if let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: now) {
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: targetMonth))!
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                // Add 3-5 events per month at different days
                let eventDays = [5, 10, 15, 20, 25]
                let eventCount = monthOffset == 0 ? 5 : 4 // Current month gets all 5, others get 4
                
                for i in 0..<eventCount {
                    if let eventDay = calendar.date(byAdding: .day, value: eventDays[i], to: monthStart) {
                        let dateString = dateFormatter.string(from: eventDay)
                        
                        // Create varied events based on month offset and day
                        let eventTypes = [
                            ("Lunch with ", ["Sarah", "Jake", "Emma", "Mike", "Lisa"], 12, 30),
                            ("Meeting with ", ["team", "client", "boss", "HR", "mentor"], 14, 0),
                            ("Coffee with ", ["John", "Amy", "David", "Karen", "Tom"], 9, 15),
                            ("Dinner with ", ["family", "friends", "parents", "in-laws", "cousins"], 19, 0),
                            ("Doctor ", ["checkup", "appointment", "follow-up", "consultation", "visit"], 15, 45),
                            ("Dentist ", ["cleaning", "appointment", "checkup", "consultation", "x-rays"], 10, 0),
                            ("Gym ", ["session", "training", "class", "workout", "yoga"], 7, 30),
                            ("Call with ", ["mom", "dad", "sister", "brother", "grandma"], 16, 0)
                        ]
                        
                        let eventIndex = (abs(monthOffset) + i) % eventTypes.count
                        let (prefix, options, hour, minute) = eventTypes[eventIndex]
                        let suffix = options[i % options.count]
                        
                        let eventTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: eventDay)!
                        var task = Task(text: "\(prefix)\(suffix)", listId: "calendar_\(dateString)", mode: "life")
                        task.dueDate = eventTime
                        taskStore.tasks.append(task)
                    }
                }
                
                // Also add some regular tasks (not calendar events) to show on calendar
                if monthOffset != 0 { // Don't add to current month (already has tasks)
                    // Add 2-3 regular tasks that will show on calendar
                    let regularTaskCount = 3
                    for j in 0..<regularTaskCount {
                        let dayOffset = [3, 12, 18, 24][j]
                        if let taskDay = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) {
                            let taskTime = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: taskDay)!
                            let taskTypes = [
                                ("Pay bills", "bills"),
                                ("Grocery shopping", "routine"),
                                ("Clean house", "routine"),
                                ("Work deadline", "today"),
                                ("Plan vacation", "goals"),
                                ("Birthday gift", "plans")
                            ]
                            let (text, listId) = taskTypes[(abs(monthOffset) + j) % taskTypes.count]
                            var task = Task(text: text, listId: listId, mode: "life")
                            task.dueDate = taskTime
                            taskStore.tasks.append(task)
                        }
                    }
                }
            }
        }
        
        // OVERDUE - Just 2 tasks in the past
        if let twoWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -2, to: now) {
            var overdueTask = Task(text: "Overdue car maintenance", listId: "today", mode: "life")
            overdueTask.dueDate = twoWeeksAgo
            taskStore.tasks.append(overdueTask)
        }
    }
    
    // MARK: - WORK Mode Data
    private static func populateWorkModeData(taskStore: TaskStore, calendar: Calendar, now: Date) {
        // TODAY - Maximum 4 tasks
        let workTodayTasks = [
            "Review Q4 budget",
            "Team standup 10am",
            "Send client invoice",
            "Code review PR #234"
        ]
        
        for taskText in workTodayTasks {
            taskStore.tasks.append(Task(text: taskText, listId: "today", mode: "work"))
        }
        
        // LATER - Maximum 4 tasks
        let workLaterTasks = [
            "Research CRM options",
            "Plan Q1 offsite",
            "Update handbook",
            "Performance goals draft"
        ]
        
        for taskText in workLaterTasks {
            taskStore.tasks.append(Task(text: taskText, listId: "later", mode: "work"))
        }
        
        // SCHEDULED - Spread across days
        // Tomorrow - Team meeting
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            let meetingTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: tomorrow)!
            var meetingTask = Task(text: "Team meeting", listId: "done", mode: "work")
            meetingTask.dueDate = meetingTime
            taskStore.tasks.append(meetingTask)
        }
        
        // Friday - Project deadline
        if let friday = getNextWeekday(6, from: now, calendar: calendar) {
            let deadlineTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: friday)!
            var deadlineTask = Task(text: "Project deadline", listId: "done", mode: "work")
            deadlineTask.dueDate = deadlineTime
            taskStore.tasks.append(deadlineTask)
        }
        
        // Next month - Quarterly review
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) {
            let reviewTime = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: nextMonth)!
            var reviewTask = Task(text: "Quarterly review", listId: "done", mode: "work")
            reviewTask.dueDate = reviewTime
            taskStore.tasks.append(reviewTask)
        }
        
        // Add work tasks across multiple months
        for monthOffset in -6...6 {
            if let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: now) {
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: targetMonth))!
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                // Add 2-4 work events per month
                let workEventDays = [3, 11, 17, 23]
                let eventCount = 3
                
                for i in 0..<eventCount {
                    if let eventDay = calendar.date(byAdding: .day, value: workEventDays[i], to: monthStart) {
                        let dateString = dateFormatter.string(from: eventDay)
                        
                        let workEvents = [
                            ("Sprint planning", 9, 30),
                            ("Client presentation", 11, 0),
                            ("Team standup", 10, 0),
                            ("1-on-1 with manager", 14, 30),
                            ("Product demo", 15, 0),
                            ("Code review session", 16, 0),
                            ("Design review", 13, 0),
                            ("Budget meeting", 9, 0)
                        ]
                        
                        let eventIndex = (abs(monthOffset) + i) % workEvents.count
                        let (text, hour, minute) = workEvents[eventIndex]
                        
                        let eventTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: eventDay)!
                        var task = Task(text: "\(text)", listId: "calendar_\(dateString)", mode: "work")
                        task.dueDate = eventTime
                        taskStore.tasks.append(task)
                    }
                }
            }
        }
        
        // OVERDUE - Just 1 task
        if let oneWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) {
            var overdueTask = Task(text: "Expense report due", listId: "today", mode: "work")
            overdueTask.dueDate = oneWeekAgo
            taskStore.tasks.append(overdueTask)
        }
    }
    
    // MARK: - SCHOOL Mode Data
    private static func populateSchoolModeData(taskStore: TaskStore, calendar: Calendar, now: Date) {
        // TODAY - Maximum 4 tasks
        let schoolTodayTasks = [
            "Math homework Ch.12",
            "Biology quiz study",
            "Essay introduction",
            "Read History p.145-180"
        ]
        
        for taskText in schoolTodayTasks {
            taskStore.tasks.append(Task(text: taskText, listId: "today", mode: "school"))
        }
        
        // LATER - Maximum 4 tasks
        let schoolLaterTasks = [
            "Climate research paper",
            "SAT prep",
            "Science fair project",
            "College applications"
        ]
        
        for taskText in schoolLaterTasks {
            taskStore.tasks.append(Task(text: taskText, listId: "later", mode: "school"))
        }
        
        // SCHEDULED - Spread across calendar
        // Next Monday - Quiz
        if let monday = getNextWeekday(2, from: now, calendar: calendar) {
            let quizTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: monday)!
            var quizTask = Task(text: "Chemistry quiz", listId: "done", mode: "school")
            quizTask.dueDate = quizTime
            taskStore.tasks.append(quizTask)
        }
        
        // Next week - Midterm
        if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now) {
            let examTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: nextWeek)!
            var examTask = Task(text: "Calculus midterm", listId: "done", mode: "school")
            examTask.dueDate = examTime
            taskStore.tasks.append(examTask)
        }
        
        // Two weeks - Project due
        if let twoWeeks = calendar.date(byAdding: .weekOfYear, value: 2, to: now) {
            let projectTime = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: twoWeeks)!
            var projectTask = Task(text: "CS final project", listId: "done", mode: "school")
            projectTask.dueDate = projectTime
            taskStore.tasks.append(projectTask)
        }
        
        // Add school tasks across multiple months
        for monthOffset in -6...6 {
            if let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: now) {
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: targetMonth))!
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                // Add 2-3 school events per month
                let schoolEventDays = [7, 14, 21, 28]
                let eventCount = 3
                
                for i in 0..<eventCount {
                    if let eventDay = calendar.date(byAdding: .day, value: schoolEventDays[i], to: monthStart) {
                        let dateString = dateFormatter.string(from: eventDay)
                        
                        let schoolEvents = [
                            ("Math test", 9, 0),
                            ("Biology lab", 14, 0),
                            ("History presentation", 10, 30),
                            ("English essay due", 23, 59),
                            ("Physics quiz", 11, 0),
                            ("Study group", 16, 0),
                            ("Office hours", 15, 30),
                            ("Group project meeting", 13, 0)
                        ]
                        
                        let eventIndex = (abs(monthOffset) + i) % schoolEvents.count
                        let (text, hour, minute) = schoolEvents[eventIndex]
                        
                        let eventTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: eventDay)!
                        var task = Task(text: "\(text)", listId: "calendar_\(dateString)", mode: "school")
                        task.dueDate = eventTime
                        taskStore.tasks.append(task)
                    }
                }
            }
        }
        
        // OVERDUE - Just 1 assignment
        if let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now) {
            var overdueTask = Task(text: "English essay late", listId: "today", mode: "school")
            overdueTask.dueDate = threeDaysAgo
            taskStore.tasks.append(overdueTask)
        }
    }
    
    // MARK: - Helper Functions
    private static func getNextWeekday(_ weekday: Int, from date: Date, calendar: Calendar) -> Date? {
        let components = DateComponents(weekday: weekday)
        return calendar.nextDate(after: date, matching: components, matchingPolicy: .nextTime)
    }
    
    // MARK: - Multi-Type Test Data
    private static func addMultiTypeTestData(taskStore: TaskStore, calendar: Calendar, now: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Tomorrow - Add deadline + plan tasks (2 colors)
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            let dateString = dateFormatter.string(from: tomorrow)
            
            // Deadline task
            var deadlineTask = Task(text: "Project submission", listId: "calendar_\(dateString)", mode: "life")
            deadlineTask.dueDate = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: tomorrow)!
            taskStore.tasks.append(deadlineTask)
            
            // Plan task  
            var planTask = Task(text: "Review meeting notes", listId: "calendar_\(dateString)", mode: "life")
            planTask.dueDate = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow)!
            taskStore.tasks.append(planTask)
        }
        
        // In 2 days - Add deadline + recurring (2 colors)
        if let twoDays = calendar.date(byAdding: .day, value: 2, to: now) {
            let dateString = dateFormatter.string(from: twoDays)
            
            // Deadline task
            var deadlineTask = Task(text: "Report submission", listId: "calendar_\(dateString)", mode: "life")
            deadlineTask.dueDate = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: twoDays)!
            taskStore.tasks.append(deadlineTask)
            
            // Recurring task
            var recurringTask = Task(text: "Daily standup (Every weekday)", listId: "calendar_\(dateString)", mode: "life")
            recurringTask.dueDate = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: twoDays)!
            recurringTask.isRecurring = true
            taskStore.tasks.append(recurringTask)
        }
        
        // In 3 days - Add deadline + plan + recurring (3 colors)
        if let threeDays = calendar.date(byAdding: .day, value: 3, to: now) {
            let dateString = dateFormatter.string(from: threeDays)
            
            // Deadline task
            var deadlineTask = Task(text: "Tax deadline", listId: "calendar_\(dateString)", mode: "life")
            deadlineTask.dueDate = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: threeDays)!
            taskStore.tasks.append(deadlineTask)
            
            // Plan task
            var planTask = Task(text: "Vacation planning", listId: "calendar_\(dateString)", mode: "life")
            planTask.dueDate = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: threeDays)!
            taskStore.tasks.append(planTask)
            
            // Recurring task
            var recurringTask = Task(text: "Weekly review (Every Monday)", listId: "calendar_\(dateString)", mode: "life")
            recurringTask.dueDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: threeDays)!
            recurringTask.isRecurring = true
            taskStore.tasks.append(recurringTask)
        }
        
        // Next week - Add plan + recurring (2 colors)
        if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now) {
            let dateString = dateFormatter.string(from: nextWeek)
            
            // Plan task
            var planTask = Task(text: "Strategy session", listId: "calendar_\(dateString)", mode: "life")
            planTask.dueDate = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: nextWeek)!
            taskStore.tasks.append(planTask)
            
            // Recurring task
            var recurringTask = Task(text: "Monthly report (Every 15th)", listId: "calendar_\(dateString)", mode: "life")
            recurringTask.dueDate = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: nextWeek)!
            recurringTask.isRecurring = true
            taskStore.tasks.append(recurringTask)
        }
        
        // In 5 days - Add plan + regular task (2 colors)
        if let fiveDays = calendar.date(byAdding: .day, value: 5, to: now) {
            let dateString = dateFormatter.string(from: fiveDays)
            
            // Plan task
            var planTask = Task(text: "Q2 planning session", listId: "calendar_\(dateString)", mode: "life")
            planTask.dueDate = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: fiveDays)!
            taskStore.tasks.append(planTask)
            
            // Regular task (will use mode color)
            var regularTask = Task(text: "Team lunch", listId: "calendar_\(dateString)", mode: "life")
            regularTask.dueDate = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: fiveDays)!
            taskStore.tasks.append(regularTask)
        }
        
        // In 6 days - Add deadline + regular task (2 colors)
        if let sixDays = calendar.date(byAdding: .day, value: 6, to: now) {
            let dateString = dateFormatter.string(from: sixDays)
            
            // Deadline task
            var deadlineTask = Task(text: "Invoice payment due", listId: "calendar_\(dateString)", mode: "life")
            deadlineTask.dueDate = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: sixDays)!
            taskStore.tasks.append(deadlineTask)
            
            // Regular task
            var regularTask = Task(text: "Coffee with mentor", listId: "calendar_\(dateString)", mode: "life")
            regularTask.dueDate = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: sixDays)!
            taskStore.tasks.append(regularTask)
        }
        
        // Also add some in past months for testing
        if let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) {
            if let mixedDay = calendar.date(byAdding: .day, value: 8, to: calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonth))!) {
                let dateString = dateFormatter.string(from: mixedDay)
                
                // All three types on same day
                var deadlineTask = Task(text: "Contract deadline", listId: "calendar_\(dateString)", mode: "life")
                deadlineTask.dueDate = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: mixedDay)!
                taskStore.tasks.append(deadlineTask)
                
                var planTask = Task(text: "Business plan draft", listId: "calendar_\(dateString)", mode: "life")
                planTask.dueDate = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: mixedDay)!
                taskStore.tasks.append(planTask)
                
                var recurringTask = Task(text: "Team standup (Every weekday)", listId: "calendar_\(dateString)", mode: "life")
                recurringTask.dueDate = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: mixedDay)!
                recurringTask.isRecurring = true
                taskStore.tasks.append(recurringTask)
            }
            
            // Add another day with just 2 colors in past month
            if let doubleDay = calendar.date(byAdding: .day, value: 15, to: calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonth))!) {
                let dateString = dateFormatter.string(from: doubleDay)
                
                // Recurring + regular (2 colors)
                var recurringTask = Task(text: "Gym workout (Every Tuesday)", listId: "calendar_\(dateString)", mode: "life")
                recurringTask.dueDate = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: doubleDay)!
                recurringTask.isRecurring = true
                taskStore.tasks.append(recurringTask)
                
                var regularTask = Task(text: "Dentist appointment", listId: "calendar_\(dateString)", mode: "life")
                regularTask.dueDate = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: doubleDay)!
                taskStore.tasks.append(regularTask)
            }
        }
    }
}