//
//  TaskStoreBase.swift
//  Shared between iOS, watchOS, and macOS
//
//  Base task store functionality shared across platforms
//

import Foundation
import SwiftUI

// MARK: - Base Task Store Protocol
public protocol TaskStoreProtocol: ObservableObject {
    var tasks: [Task] { get set }
    var lists: [TaskList] { get set }
    var currentMode: ViewMode { get set }
    var currentListId: String { get set }
    
    func addTask(_ text: String)
    func deleteTask(at offsets: IndexSet)
    func toggleTask(_ task: Task)
    func clearCompleted()
    func cycleThroughModes()
}

// MARK: - Task Store Base Implementation
open class TaskStoreBase: ObservableObject {
    @Published public var tasks: [Task] = []
    @Published public var lists: [TaskList] = []
    @Published public var currentListId: String = "menu"
    @Published public var currentMode: ViewMode = .life
    @Published public var selectedCalendarDate: Date? = nil
    @Published public var calendarDisplayDate: Date = Date()
    @Published public var longPressedDate: Date? = nil
    @Published public var taskToEdit: Task? = nil
    
    public let userDefaults: UserDefaults
    public let tasksKey: String
    public let listsKey: String
    
    public init(userDefaults: UserDefaults = .standard, tasksKey: String = "todomaiTasks", listsKey: String = "todomaiLists") {
        self.userDefaults = userDefaults
        self.tasksKey = tasksKey
        self.listsKey = listsKey
    }
    
    // MARK: - Computed Properties
    public var currentList: TaskList? {
        lists.first { $0.id == currentListId }
    }
    
    public var currentTasks: [Task] {
        tasks.filter { $0.listId == currentListId && $0.mode == currentMode.rawValue && !$0.isCompleted }
    }
    
    public var completedTasks: [Task] {
        tasks.filter { $0.listId == currentListId && $0.mode == currentMode.rawValue && $0.isCompleted }
    }
    
    // MARK: - Task Management
    public func toggleTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
        }
    }
    
    public func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    public func deleteTask(at offsets: IndexSet) {
        let tasksToDelete = offsets.map { currentTasks[$0] }
        for task in tasksToDelete {
            deleteTask(task)
        }
    }
    
    public func clearCompleted() {
        tasks.removeAll { $0.listId == currentListId && $0.mode == currentMode.rawValue && $0.isCompleted }
        saveTasks()
    }
    
    public func moveTaskToToday(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].listId = "today"
            saveTasks()
        }
    }
    
    // MARK: - Mode Management
    public func cycleThroughModes() {
        switch currentMode {
        case .life:
            currentMode = .work
        case .work:
            currentMode = .school
        case .school:
            currentMode = .life
        }
        updateListsForMode()
    }
    
    public func updateListsForMode() {
        lists.removeAll()
        
        // Add mode-specific lists
        let modeListIds = currentMode.getListIds()
        for (index, listId) in modeListIds.enumerated() {
            let name = currentMode.getListName(for: listId)
            let color = currentMode.getListColor(for: listId).rgbValues
            lists.append(TaskList(id: listId, name: name, color: color))
        }
        
        // Add secondary page lists
        let secondaryButtons = currentMode.getSecondPageButtons()
        for button in secondaryButtons {
            let color = button.color.rgbValues
            lists.append(TaskList(id: button.listId, name: button.title, color: color))
        }
    }
    
    // MARK: - Calendar Navigation
    public func navigateToNextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: calendarDisplayDate) {
            calendarDisplayDate = newDate
        }
    }
    
    public func navigateToPreviousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: calendarDisplayDate) {
            calendarDisplayDate = newDate
        }
    }
    
    // MARK: - Data Persistence
    public func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encoded, forKey: tasksKey)
        }
    }
    
    public func saveLists() {
        if let encoded = try? JSONEncoder().encode(lists) {
            userDefaults.set(encoded, forKey: listsKey)
        }
    }
    
    public func loadTasks() {
        if let data = userDefaults.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decoded
        }
    }
    
    public func loadLists() {
        if let data = userDefaults.data(forKey: listsKey),
           let decoded = try? JSONDecoder().decode([TaskList].self, from: data) {
            lists = decoded
        }
    }
    
    public func loadData() {
        loadTasks()
        loadLists()
        
        if lists.isEmpty {
            updateListsForMode()
        }
    }
    
    // MARK: - Utility Methods
    public func cleanTaskText(_ text: String, listName: String) -> String {
        var cleanedText = text
            .replacingOccurrences(of: " to \(listName.lowercased()) list", with: "")
            .replacingOccurrences(of: " to \(listName.lowercased())", with: "")
            .replacingOccurrences(of: " in \(listName.lowercased()) list", with: "")
            .replacingOccurrences(of: " in \(listName.lowercased())", with: "")
        
        cleanedText = cleanedText.trimmingCharacters(in: .whitespaces)
        
        if !cleanedText.isEmpty {
            cleanedText = cleanedText.prefix(1).uppercased() + cleanedText.dropFirst()
        }
        
        return cleanedText
    }
}