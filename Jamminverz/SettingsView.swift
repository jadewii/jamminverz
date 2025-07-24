//
//  SettingsView.swift
//  Todomai-iOS
//
//  Settings page with custom Todomai UI style
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    Text("SETTINGS")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.top, 60)
                        .padding(.bottom, 40)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Current Mode Info
                            VStack(spacing: 12) {
                                Text("CURRENT MODE")
                                    .font(.system(size: 18, weight: .heavy))
                                    .foregroundColor(.black)
                                
                                Text(taskStore.currentMode.displayName)
                                    .font(.system(size: 24, weight: .heavy))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        ZStack {
                                            taskStore.currentMode.modeButtonColor
                                            Rectangle()
                                                .stroke(Color.black, lineWidth: 3)
                                        }
                                    )
                            }
                            .padding(.horizontal, 40)
                            
                            // Daily Schedule Settings
                            VStack(spacing: 12) {
                                Text("DAILY SCHEDULE")
                                    .font(.system(size: 18, weight: .heavy))
                                    .foregroundColor(.black)
                                    .padding(.top, 20)
                                
                                // Toggle for world clock
                                Button(action: {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    taskStore.isDailyScheduleEnabled.toggle()
                                }) {
                                    HStack {
                                        Text("SHOW DAILY SCHEDULE")
                                            .font(.system(size: 16, weight: .heavy))
                                            .foregroundColor(.black)
                                        
                                        Spacer()
                                        
                                        ZStack {
                                            Rectangle()
                                                .fill(taskStore.isDailyScheduleEnabled ? Color.green : Color.gray.opacity(0.3))
                                                .frame(width: 50, height: 30)
                                            
                                            Circle()
                                                .fill(.white)
                                                .frame(width: 26, height: 26)
                                                .offset(x: taskStore.isDailyScheduleEnabled ? 10 : -10)
                                        }
                                        .animation(.easeInOut(duration: 0.2), value: taskStore.isDailyScheduleEnabled)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .padding(.horizontal, 20)
                                    .background(
                                        ZStack {
                                            Color.white
                                            Rectangle()
                                                .stroke(Color.black, lineWidth: 3)
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if taskStore.isDailyScheduleEnabled {
                                    // Work mode settings
                                    VStack(spacing: 12) {
                                        Text("WORK HOURS")
                                            .font(.system(size: 14, weight: .heavy))
                                            .foregroundColor(.black)
                                        
                                        // Clock in/out times
                                        HStack(spacing: 16) {
                                            VStack {
                                                Text("CLOCK IN")
                                                    .font(.system(size: 12, weight: .heavy))
                                                    .foregroundColor(.black)
                                                DatePicker("", selection: $taskStore.workClockInTime, displayedComponents: .hourAndMinute)
                                                    .labelsHidden()
                                                    .scaleEffect(0.8)
                                            }
                                            
                                            VStack {
                                                Text("CLOCK OUT")
                                                    .font(.system(size: 12, weight: .heavy))
                                                    .foregroundColor(.black)
                                                DatePicker("", selection: $taskStore.workClockOutTime, displayedComponents: .hourAndMinute)
                                                    .labelsHidden()
                                                    .scaleEffect(0.8)
                                            }
                                        }
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            ZStack {
                                                Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.1)
                                                Rectangle()
                                                    .stroke(Color(red: 0.2, green: 0.8, blue: 0.4), lineWidth: 2)
                                            }
                                        )
                                        
                                        // Calendar blocking toggle
                                        Button(action: {
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                            taskStore.isWorkCalendarBlockingEnabled.toggle()
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("OFF THE CLOCK!")
                                                        .font(.system(size: 14, weight: .heavy))
                                                        .foregroundColor(.red)
                                                    Text("Blocks work calendar and all work related tasks until your next Clock in time")
                                                        .font(.system(size: 11, weight: .medium))
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                Spacer()
                                                
                                                ZStack {
                                                    Rectangle()
                                                        .fill(taskStore.isWorkCalendarBlockingEnabled ? Color.green : Color.gray.opacity(0.3))
                                                        .frame(width: 44, height: 26)
                                                        .cornerRadius(13)
                                                    
                                                    Circle()
                                                        .fill(.white)
                                                        .frame(width: 22, height: 22)
                                                        .offset(x: taskStore.isWorkCalendarBlockingEnabled ? 9 : -9)
                                                }
                                                .animation(.easeInOut(duration: 0.2), value: taskStore.isWorkCalendarBlockingEnabled)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            ZStack {
                                                Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.05)
                                                Rectangle()
                                                    .stroke(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.3), lineWidth: 1)
                                            }
                                        )
                                    }
                                    
                                    // School hours settings
                                    VStack(spacing: 12) {
                                        Text("SCHOOL HOURS")
                                            .font(.system(size: 14, weight: .heavy))
                                            .foregroundColor(.black)
                                        
                                        // School hours
                                        HStack(spacing: 16) {
                                            VStack {
                                                Text("START")
                                                    .font(.system(size: 12, weight: .heavy))
                                                    .foregroundColor(.black)
                                                DatePicker("", selection: $taskStore.schoolStartTime, displayedComponents: .hourAndMinute)
                                                    .labelsHidden()
                                                    .scaleEffect(0.8)
                                            }
                                            
                                            VStack {
                                                Text("END")
                                                    .font(.system(size: 12, weight: .heavy))
                                                    .foregroundColor(.black)
                                                DatePicker("", selection: $taskStore.schoolEndTime, displayedComponents: .hourAndMinute)
                                                    .labelsHidden()
                                                    .scaleEffect(0.8)
                                            }
                                        }
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            ZStack {
                                                Color(red: 0.6, green: 0.3, blue: 0.8).opacity(0.1)
                                                Rectangle()
                                                    .stroke(Color(red: 0.6, green: 0.3, blue: 0.8), lineWidth: 2)
                                            }
                                        )
                                        
                                        // School days selection
                                        VStack(spacing: 8) {
                                            Text("SCHOOL DAYS")
                                                .font(.system(size: 12, weight: .heavy))
                                                .foregroundColor(.black)
                                            
                                            HStack(spacing: 8) {
                                                ForEach([(0, "S"), (1, "M"), (2, "T"), (3, "W"), (4, "T"), (5, "F"), (6, "S")], id: \.0) { day, letter in
                                                    Button(action: {
                                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                                        impactFeedback.impactOccurred()
                                                        if taskStore.schoolDays.contains(day) {
                                                            taskStore.schoolDays.remove(day)
                                                        } else {
                                                            taskStore.schoolDays.insert(day)
                                                        }
                                                    }) {
                                                        Text(letter)
                                                            .font(.system(size: 14, weight: .heavy))
                                                            .foregroundColor(taskStore.schoolDays.contains(day) ? .white : .black)
                                                            .frame(width: 32, height: 32)
                                                            .background(
                                                                taskStore.schoolDays.contains(day) 
                                                                    ? Color(red: 0.6, green: 0.3, blue: 0.8)
                                                                    : Color.gray.opacity(0.2)
                                                            )
                                                            .cornerRadius(16)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            ZStack {
                                                Color(red: 0.6, green: 0.3, blue: 0.8).opacity(0.05)
                                                Rectangle()
                                                    .stroke(Color(red: 0.6, green: 0.3, blue: 0.8).opacity(0.3), lineWidth: 1)
                                            }
                                        )
                                    }
                                    
                                    // Study time calendar lock
                                    VStack(spacing: 12) {
                                        Text("STUDY TIME")
                                            .font(.system(size: 14, weight: .heavy))
                                            .foregroundColor(.black)
                                        
                                        // Enable study time calendar lock
                                        Button(action: {
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                            taskStore.isStudyTimeCalendarLockEnabled.toggle()
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("LOCK CALENDAR DURING STUDY")
                                                        .font(.system(size: 14, weight: .heavy))
                                                        .foregroundColor(.black)
                                                    Text("Blocks all calendars during study hours")
                                                        .font(.system(size: 11, weight: .medium))
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                Spacer()
                                                
                                                ZStack {
                                                    Rectangle()
                                                        .fill(taskStore.isStudyTimeCalendarLockEnabled ? Color(red: 0.6, green: 0.3, blue: 0.8) : Color.gray.opacity(0.3))
                                                        .frame(width: 44, height: 26)
                                                        .cornerRadius(13)
                                                    
                                                    Circle()
                                                        .fill(.white)
                                                        .frame(width: 22, height: 22)
                                                        .offset(x: taskStore.isStudyTimeCalendarLockEnabled ? 9 : -9)
                                                }
                                                .animation(.easeInOut(duration: 0.2), value: taskStore.isStudyTimeCalendarLockEnabled)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            ZStack {
                                                Color(red: 0.6, green: 0.3, blue: 0.8).opacity(0.05)
                                                Rectangle()
                                                    .stroke(Color(red: 0.6, green: 0.3, blue: 0.8).opacity(0.3), lineWidth: 1)
                                            }
                                        )
                                        
                                        if taskStore.isStudyTimeCalendarLockEnabled {
                                            // Study hours
                                            HStack(spacing: 16) {
                                                VStack {
                                                    Text("START")
                                                        .font(.system(size: 12, weight: .heavy))
                                                        .foregroundColor(.black)
                                                    DatePicker("", selection: $taskStore.studyStartTime, displayedComponents: .hourAndMinute)
                                                        .labelsHidden()
                                                        .scaleEffect(0.8)
                                                }
                                                
                                                VStack {
                                                    Text("END")
                                                        .font(.system(size: 12, weight: .heavy))
                                                        .foregroundColor(.black)
                                                    DatePicker("", selection: $taskStore.studyEndTime, displayedComponents: .hourAndMinute)
                                                        .labelsHidden()
                                                        .scaleEffect(0.8)
                                                }
                                            }
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                ZStack {
                                                    Color(red: 0.6, green: 0.3, blue: 0.8).opacity(0.1)
                                                    Rectangle()
                                                        .stroke(Color(red: 0.6, green: 0.3, blue: 0.8), lineWidth: 2)
                                                }
                                            )
                                            
                                            // Study days selection
                                            VStack(spacing: 8) {
                                                Text("STUDY DAYS")
                                                    .font(.system(size: 12, weight: .heavy))
                                                    .foregroundColor(.black)
                                                
                                                HStack(spacing: 8) {
                                                    ForEach([(0, "S"), (1, "M"), (2, "T"), (3, "W"), (4, "T"), (5, "F"), (6, "S")], id: \.0) { day, letter in
                                                        Button(action: {
                                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                                            impactFeedback.impactOccurred()
                                                            if taskStore.studyDays.contains(day) {
                                                                taskStore.studyDays.remove(day)
                                                            } else {
                                                                taskStore.studyDays.insert(day)
                                                            }
                                                        }) {
                                                            Text(letter)
                                                                .font(.system(size: 14, weight: .heavy))
                                                                .foregroundColor(taskStore.studyDays.contains(day) ? .white : .black)
                                                                .frame(width: 32, height: 32)
                                                                .background(
                                                                    taskStore.studyDays.contains(day) 
                                                                        ? Color(red: 0.6, green: 0.3, blue: 0.8)
                                                                        : Color.gray.opacity(0.2)
                                                                )
                                                                .cornerRadius(16)
                                                        }
                                                    }
                                                }
                                            }
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                ZStack {
                                                    Color(red: 0.6, green: 0.3, blue: 0.8).opacity(0.05)
                                                    Rectangle()
                                                        .stroke(Color(red: 0.6, green: 0.3, blue: 0.8).opacity(0.3), lineWidth: 1)
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 40)
                            
                            // Statistics
                            VStack(spacing: 12) {
                                Text("STATISTICS")
                                    .font(.system(size: 18, weight: .heavy))
                                    .foregroundColor(.black)
                                    .padding(.top, 20)
                                
                                HStack {
                                    SettingsStatBox(title: "TOTAL", value: "\(taskStore.tasks.count)", color: Color(red: 0.4, green: 0.8, blue: 1.0))
                                    SettingsStatBox(title: "COMPLETED", value: "\(taskStore.tasks.filter { $0.isCompleted }.count)", color: Color(red: 0.4, green: 0.8, blue: 0.4))
                                }
                                
                                HStack {
                                    SettingsStatBox(title: "PENDING", value: "\(taskStore.tasks.filter { !$0.isCompleted }.count)", color: Color(red: 1.0, green: 0.7, blue: 0.3))
                                    SettingsStatBox(title: "TODAY", value: "\(taskStore.tasks.filter { $0.listId == "today" && !$0.isCompleted }.count)", color: Color(red: 1.0, green: 0.431, blue: 0.431))
                                }
                            }
                            .padding(.horizontal, 40)
                            
                            // About Section
                            VStack(spacing: 12) {
                                Text("ABOUT")
                                    .font(.system(size: 18, weight: .heavy))
                                    .foregroundColor(.black)
                                    .padding(.top, 20)
                                
                                VStack(spacing: 4) {
                                    Text("TODOMAI")
                                        .font(.system(size: 24, weight: .heavy))
                                        .foregroundColor(.black)
                                    Text("VERSION 1.0")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text("© 2025")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    ZStack {
                                        Color.gray.opacity(0.1)
                                        Rectangle()
                                            .stroke(Color.black, lineWidth: 3)
                                    }
                                )
                            }
                            .padding(.horizontal, 40)
                            
                            // Clear Data Button
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                taskStore.clearCompleted()
                            }) {
                                Text("CLEAR COMPLETED TASKS")
                                    .font(.system(size: 16, weight: .heavy))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        ZStack {
                                            Color.red
                                            Rectangle()
                                                .stroke(Color.black, lineWidth: 3)
                                        }
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                        }
                        .padding(.bottom, 40)
                    }
                    
                    // Back button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        currentTab = "menu"
                    }) {
                        Text("← BACK")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                ZStack {
                                    Color.white
                                    Rectangle()
                                        .stroke(Color.black, lineWidth: 3)
                                }
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct SettingsStatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.black)
            
            Text(value)
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    ZStack {
                        color
                        Rectangle()
                            .stroke(Color.black, lineWidth: 3)
                    }
                )
        }
    }
}

#Preview {
    SettingsView(taskStore: TaskStore(), currentTab: .constant("settings"))
}