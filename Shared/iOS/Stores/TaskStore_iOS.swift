//
//  TaskStore_iOS.swift
//  iOS-specific task store implementation
//
//  Extends base TaskStore with iOS-specific features
//

import SwiftUI
import Foundation

final class TaskStore: TaskStoreBase {
    @Published var repeatTaskText: String = ""
    @Published var selectedTemplate: String? = nil
    @Published var isProcessing: Bool = false
    
    override init(userDefaults: UserDefaults = .standard, tasksKey: String = "todomaiTasks", listsKey: String = "todomaiLists") {
        super.init(userDefaults: userDefaults, tasksKey: tasksKey, listsKey: listsKey)
        loadData()
    }
    
    // MARK: - iOS-specific Task Addition
    func addTask(_ text: String) {
        var processedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var targetListId = currentListId
        var taskDueDate: Date? = nil
        
        // Check for list routing in the text
        let lowercasedText = processedText.lowercased()
        for list in lists {
            let listNameLower = list.name.lowercased()
            if lowercasedText.contains(" to \(listNameLower)") ||
               lowercasedText.contains(" in \(listNameLower)") {
                targetListId = list.id
                processedText = cleanTaskText(processedText, listName: list.name)
                break
            }
        }
        
        // Parse time from text (e.g., "Meeting at 3pm", "Call at 14:30")
        let timePatterns = [
            #"at (\d{1,2}):(\d{2})"#,                    // "at 14:30"
            #"at (\d{1,2})([ap]m)"#,                     // "at 3pm"
            #"at (\d{1,2}):(\d{2})([ap]m)"#,            // "at 3:30pm"
            #"(\d{1,2}):(\d{2})"#,                       // "14:30"
            #"(\d{1,2})([ap]m)"#                         // "3pm"
        ]
        
        for pattern in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: processedText.utf16.count)
                if let match = regex.firstMatch(in: processedText, options: [], range: range) {
                    // Extract time and create date
                    var hour = 0
                    var minute = 0
                    var isPM = false
                    
                    if match.numberOfRanges >= 3 {
                        if let hourRange = Range(match.range(at: 1), in: processedText),
                           let hourInt = Int(processedText[hourRange]) {
                            hour = hourInt
                        }
                        
                        if match.numberOfRanges >= 4 {
                            // Check for minutes or am/pm
                            if let secondRange = Range(match.range(at: 2), in: processedText) {
                                let secondPart = String(processedText[secondRange])
                                if let minuteInt = Int(secondPart) {
                                    minute = minuteInt
                                } else if secondPart.lowercased() == "pm" {
                                    isPM = true
                                } else if secondPart.lowercased() == "am" {
                                    isPM = false
                                }
                            }
                            
                            // Check for am/pm in third group if present
                            if match.numberOfRanges >= 5,
                               let thirdRange = Range(match.range(at: 3), in: processedText) {
                                let thirdPart = String(processedText[thirdRange]).lowercased()
                                if thirdPart == "pm" {
                                    isPM = true
                                } else if thirdPart == "am" {
                                    isPM = false
                                }
                            }
                        }
                    }
                    
                    // Convert to 24-hour format
                    if isPM && hour < 12 {
                        hour += 12
                    } else if !isPM && hour == 12 {
                        hour = 0
                    }
                    
                    // Create date with time
                    let calendar = Calendar.current
                    var components = calendar.dateComponents([.year, .month, .day], from: Date())
                    components.hour = hour
                    components.minute = minute
                    components.second = 0
                    
                    if let date = calendar.date(from: components) {
                        taskDueDate = date
                    }
                    
                    // Remove time from task text
                    processedText = regex.stringByReplacingMatches(in: processedText, options: [], range: range, withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                }
            }
        }
        
        let task = Task(
            text: processedText,
            listId: targetListId,
            mode: currentMode.rawValue,
            dueDate: taskDueDate
        )
        
        tasks.insert(task, at: 0)
        saveTasks()
    }
    
    // MARK: - Voice Input Processing
    func processVoiceInput(_ text: String) {
        var processedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var targetListId = currentListId
        
        // Voice input routing logic
        let lowercasedText = processedText.lowercased()
        
        // Check for list names in the voice input
        for list in lists {
            let listNameLower = list.name.lowercased()
            if lowercasedText.contains(listNameLower) {
                targetListId = list.id
                // Clean the text to remove list references
                processedText = cleanTaskText(processedText, listName: list.name)
                break
            }
        }
        
        // Default routing if no specific list mentioned
        if targetListId == currentListId && currentListId == "menu" {
            targetListId = "today"
        }
        
        currentListId = targetListId
        addTask(processedText)
    }
    
    // MARK: - Template Support
    func applyTemplate(_ template: String) {
        switch template {
        case "morning":
            let morningTasks = [
                "Drink water",
                "Morning stretch",
                "Check calendar",
                "Review priorities"
            ]
            for task in morningTasks {
                addTask(task)
            }
        case "evening":
            let eveningTasks = [
                "Plan tomorrow",
                "Prepare clothes",
                "Set alarm",
                "Reflect on day"
            ]
            for task in eveningTasks {
                addTask(task)
            }
        default:
            break
        }
    }
    
    // MARK: - Testing Support
    func removeTestPrefixes() {
        for index in tasks.indices {
            tasks[index].text = tasks[index].text
                .replacingOccurrences(of: "[TEST] ", with: "")
                .replacingOccurrences(of: "[Test] ", with: "")
                .replacingOccurrences(of: "[test] ", with: "")
        }
        saveTasks()
    }
    
    func clearAllTestData() {
        tasks.removeAll { task in
            task.text.hasPrefix("[TEST]") ||
            task.text.hasPrefix("[Test]") ||
            task.text.hasPrefix("[test]")
        }
        saveTasks()
    }
}