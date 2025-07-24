//
//  EditTaskView.swift
//  Todomai-iOS
//
//  Edit existing tasks with adaptive layout
//

import SwiftUI

struct EditTaskView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    
    @State private var editedText: String = ""
    @State private var editedDueDate: Date = Date()
    @State private var hasTime: Bool = false
    @State private var showDeleteConfirmation = false
    @FocusState private var isTextFieldFocused: Bool
    
    private var task: Task? {
        taskStore.taskToEdit
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color based on task type
                getBackgroundColor()
                    .ignoresSafeArea()
                
                if let task = task {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("EDIT TASK")
                                .font(.system(size: geometry.size.width > 600 ? 28 : 22, weight: .heavy))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Delete button
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: geometry.size.width > 600 ? 24 : 20))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, geometry.size.width > 600 ? 40 : 20)
                        .padding(.top, geometry.safeAreaInsets.top + 20)
                        .padding(.bottom, 20)
                        
                        // Content
                        VStack(spacing: 20) {
                            // Task text input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Task Description")
                                    .font(.system(size: geometry.size.width > 600 ? 18 : 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                TextField("", text: $editedText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: geometry.size.width > 600 ? 20 : 16))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(10)
                                    .focused($isTextFieldFocused)
                            }
                            
                            // Time picker for certain task types
                            if task.listId.contains("calendar_") || task.isRecurring {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Time")
                                            .font(.system(size: geometry.size.width > 600 ? 18 : 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: $hasTime)
                                            .labelsHidden()
                                    }
                                    
                                    if hasTime {
                                        DatePicker("", selection: $editedDueDate, displayedComponents: .hourAndMinute)
                                            .datePickerStyle(WheelDatePickerStyle())
                                            .labelsHidden()
                                            .colorScheme(.dark)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Action buttons
                            HStack(spacing: 16) {
                                // Cancel button
                                Button(action: {
                                    cancelEdit()
                                }) {
                                    Text("CANCEL")
                                        .font(.system(size: geometry.size.width > 600 ? 18 : 16, weight: .heavy))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: geometry.size.width > 600 ? 60 : 50)
                                        .background(Color.white.opacity(0.3))
                                        .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Save button
                                Button(action: {
                                    saveChanges()
                                }) {
                                    Text("SAVE")
                                        .font(.system(size: geometry.size.width > 600 ? 18 : 16, weight: .heavy))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: geometry.size.width > 600 ? 60 : 50)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(editedText.isEmpty)
                            }
                        }
                        .padding(.horizontal, geometry.size.width > 600 ? 40 : 20)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                    }
                } else {
                    // No task to edit
                    VStack(spacing: 20) {
                        Text("NO TASK SELECTED")
                            .font(.system(size: geometry.size.width > 600 ? 24 : 18, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Button(action: {
                            currentTab = "menu"
                        }) {
                            Text("GO BACK")
                                .font(.system(size: geometry.size.width > 600 ? 18 : 16, weight: .heavy))
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupInitialValues()
            isTextFieldFocused = true
        }
        .alert("Delete Task?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func getBackgroundColor() -> Color {
        guard let task = task else { return Color.gray }
        
        if task.listId.contains("_deadline") {
            return Color(red: 0.8, green: 0.4, blue: 0.5) // Darker pastel pink
        } else if task.listId.contains("_recurring") || task.isRecurring {
            return Color(red: 0.4, green: 0.65, blue: 0.5) // Darker mint green
        } else if task.listId.contains("_plan") {
            return Color(red: 0.4, green: 0.3, blue: 0.7) // Darker purple
        } else {
            return taskStore.currentMode.modeButtonColor.opacity(0.8)
        }
    }
    
    private func setupInitialValues() {
        guard let task = task else { return }
        editedText = task.text
        
        if let dueDate = task.dueDate {
            editedDueDate = dueDate
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: dueDate)
            let minute = calendar.component(.minute, from: dueDate)
            hasTime = !(hour == 0 && minute == 0)
        } else {
            hasTime = false
        }
    }
    
    private func saveChanges() {
        guard let task = task,
              let index = taskStore.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        var updatedTask = task
        updatedTask.text = editedText
        
        if hasTime {
            updatedTask.dueDate = editedDueDate
        } else if let oldDueDate = task.dueDate {
            // Keep the date but set time to midnight
            let calendar = Calendar.current
            updatedTask.dueDate = calendar.startOfDay(for: oldDueDate)
        }
        
        taskStore.tasks[index] = updatedTask
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        navigateBack()
    }
    
    private func deleteTask() {
        guard let task = task else { return }
        
        taskStore.tasks.removeAll { $0.id == task.id }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        navigateBack()
    }
    
    private func cancelEdit() {
        navigateBack()
    }
    
    private func navigateBack() {
        taskStore.taskToEdit = nil
        
        // Navigate back to appropriate view
        if currentTab == "editTask" {
            if let task = task {
                if Calendar.current.isDateInToday(task.createdAt) && task.listId == "today" {
                    currentTab = "today"
                } else if task.listId.hasPrefix("calendar_") {
                    currentTab = "dayView"
                } else {
                    currentTab = task.listId
                }
            } else {
                currentTab = "menu"
            }
        }
    }
}

#Preview {
    EditTaskView(taskStore: TaskStore(), currentTab: .constant("editTask"))
}