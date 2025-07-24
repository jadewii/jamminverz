//
//  TodomaiSidebar.swift
//  Todomai-iOS
//
//  Custom sidebar with Todomai UI style - colorful buttons, sharp corners
//

import SwiftUI

struct TodomaiSidebar: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @State private var isCollapsed = false
    @State private var showQuickButtons = false
    
    var isColoredBackground: Bool {
        // Check if current view has a colored background
        switch currentTab {
        case "today":
            return false // White background
        case "calendar", "thisWeek", "later", "routines", "appointments", "radio", "settings":
            return true // Colored backgrounds
        default:
            return false
        }
    }
    
    var sidebarItems: [(id: String, title: String, color: Color)] {
        // Unified music production suite navigation
        return [
            ("profile", "PROFILE", Color(red: 0.373, green: 0.275, blue: 0.569)), // Purple - user account
            ("samples", "SAMPLES", Color(red: 1.0, green: 0.9, blue: 0.4)), // Yellow - sample packs
            ("create", "CREATE", Color(red: 0.8, green: 0.2, blue: 0.8)), // Magenta - pack generator
            ("albums", "ALBUMS", Color(red: 0.2, green: 0.6, blue: 1.0)), // Blue - albums
            ("studio", "STUDIO", Color(red: 0.1, green: 0.8, blue: 0.6)), // Teal - beat builder
            ("collabs", "COLLABS", Color(red: 0.9, green: 0.3, blue: 0.5)), // Hot pink - collaborations
            ("unlocks", "UNLOCKS", Color(red: 0.6, green: 0.4, blue: 0.9)), // Lavender - achievements
            ("friends", "FRIENDS", Color(red: 0.3, green: 0.8, blue: 0.3)), // Green - social
            ("store", "STORE", Color(red: 1.0, green: 0.5, blue: 0.0)), // Orange - JAde Wii marketplace
            ("artstore", "ALBUM ART", Color(red: 0.7, green: 0.3, blue: 0.9)), // Purple - album art store
            ("settings", "SETTINGS", Color(red: 0.6, green: 0.6, blue: 0.6)) // Gray - settings
        ]
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if isCollapsed {
                // Collapsed state - only show the circle button at the exact same position as expanded state
                VStack(spacing: 0) {
                    // Match the exact structure and padding from expanded state
                    HStack {
                        // Use a spacer to push the button to the right, matching expanded state
                        Spacer()
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.373, green: 0.275, blue: 0.569))
                                    .frame(width: 40, height: 40)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 12, height: 12)
                            }
                            .onTapGesture {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                // Tap expands the sidebar
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showQuickButtons = false
                                    isCollapsed = false
                                }
                            }
                            .onLongPressGesture(minimumDuration: 0.5) {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                impactFeedback.impactOccurred()
                                // Hold hides all buttons except purple
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showQuickButtons = false
                                }
                            }
                            
                            // Quick access buttons that appear on tap
                            if showQuickButtons {
                                VStack(spacing: 16) {
                                    ForEach(sidebarItems, id: \.id) { item in
                                        Button(action: {
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                            currentTab = item.id
                                            // Don't expand - just navigate
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(item.color)
                                                    .frame(width: 40, height: 40)
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 12, height: 12)
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    // Expand sidebar button
                                    Button(action: {
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showQuickButtons = false
                                            isCollapsed = false
                                        }
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white.opacity(0.3))
                                                .frame(width: 40, height: 40)
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 16, weight: .heavy))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.top, 16)
                                .transition(.opacity.combined(with: .scale))
                            }
                        }
                    }
                    .padding(.horizontal, 24) // Same as expanded
                    .padding(.vertical, 30)   // Same as expanded
                    
                    Spacer()
                }
                .frame(width: 60)
                .background(Color.clear)
                .onTapGesture {
                    if showQuickButtons {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showQuickButtons = false
                        }
                    }
                }
            } else {
                // Expanded state - full sidebar
                VStack {
                    VStack(spacing: 0) {
                        // Mode header with Todomai style
                        HStack {
                            Text("JAde Wii")
                                .font(.system(size: 36, weight: .heavy))
                                .foregroundColor(.white)
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.373, green: 0.275, blue: 0.569))
                                    .frame(width: 40, height: 40)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 12, height: 12)
                            }
                            .onTapGesture {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                // Tap: collapse and show quick access circles
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isCollapsed = true
                                    showQuickButtons = true
                                }
                            }
                            .onLongPressGesture(minimumDuration: 0.5) {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                impactFeedback.impactOccurred()
                                // Hold: collapse and hide all buttons except purple
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isCollapsed = true
                                    showQuickButtons = false
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 30)
                    
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(sidebarItems, id: \.id) { item in
                                Button(action: {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    currentTab = item.id
                                }) {
                                    Text(item.title)
                                        .font(.system(size: 18, weight: .heavy))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(item.color)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .animation(nil, value: currentTab) // Remove animation
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    }
                    .frame(maxWidth: .infinity)
                    .animation(nil, value: taskStore.currentMode) // Remove animation when mode changes
                }
                .frame(width: 320)
                .background(Color.black)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Daily Schedule Pie Chart
struct DailySchedulePieChart: View {
    @ObservedObject var taskStore: TaskStore
    
    // Calculate hours for each mode
    var scheduleBreakdown: (work: Double, school: Double, life: Double) {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today) - 1 // Convert to 0-6 (Sunday=0)
        
        // Get work hours
        let workStart = calendar.dateComponents([.hour, .minute], from: taskStore.workClockInTime)
        let workEnd = calendar.dateComponents([.hour, .minute], from: taskStore.workClockOutTime)
        let workMinutes = ((workEnd.hour ?? 0) * 60 + (workEnd.minute ?? 0)) - ((workStart.hour ?? 0) * 60 + (workStart.minute ?? 0))
        let workHours = Double(max(0, workMinutes)) / 60.0
        
        // Get school hours (always calculated, shown based on school days)
        var schoolHours = 0.0
        if taskStore.schoolDays.contains(weekday) {
            let schoolStart = calendar.dateComponents([.hour, .minute], from: taskStore.schoolStartTime)
            let schoolEnd = calendar.dateComponents([.hour, .minute], from: taskStore.schoolEndTime)
            let schoolMinutes = ((schoolEnd.hour ?? 0) * 60 + (schoolEnd.minute ?? 0)) - ((schoolStart.hour ?? 0) * 60 + (schoolStart.minute ?? 0))
            schoolHours = Double(max(0, schoolMinutes)) / 60.0
        }
        
        // Life hours is the rest
        let lifeHours = 24.0 - workHours - schoolHours
        
        return (workHours, schoolHours, lifeHours)
    }
    
    var body: some View {
        let breakdown = scheduleBreakdown
        let total = 24.0
        
        ZStack {
            // Life segment (blue) - always starts at top
            if breakdown.life > 0 {
                Circle()
                    .trim(from: 0, to: breakdown.life / total)
                    .stroke(
                        taskStore.currentMode == .life 
                            ? Color.blue
                            : Color.blue.opacity(0.15),
                        style: StrokeStyle(lineWidth: 20, lineCap: .butt)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
            }
            
            // Work segment (green)
            if breakdown.work > 0 {
                Circle()
                    .trim(from: breakdown.life / total, to: (breakdown.life + breakdown.work) / total)
                    .stroke(
                        taskStore.currentMode == .work
                            ? Color.green
                            : Color.green.opacity(0.15),
                        style: StrokeStyle(lineWidth: 20, lineCap: .butt)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
            }
            
            // School segment (purple)
            if breakdown.school > 0 {
                Circle()
                    .trim(from: (breakdown.life + breakdown.work) / total, to: 1.0)
                    .stroke(
                        taskStore.currentMode == .school
                            ? Color(red: 0.784, green: 0.647, blue: 0.949)
                            : Color(red: 0.784, green: 0.647, blue: 0.949).opacity(0.15),
                        style: StrokeStyle(lineWidth: 20, lineCap: .butt)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
            }
            
            // White clock icon filling the inner space
            Image(systemName: "clock.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
        }
    }
}