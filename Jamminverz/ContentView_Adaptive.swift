//
//  ContentView_Adaptive.swift
//  Todomai-iOS
//
//  Adaptive ContentView that works on iPhone, iPad, and macOS
//

import SwiftUI

// MARK: - Mini Player View
struct MiniPlayerView: View {
    @StateObject private var playerManager = MusicPlayerManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                playerManager.previousSong()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Button(action: {
                playerManager.togglePlayPause()
            }) {
                Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Button(action: {
                playerManager.nextSong()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color.black
                .overlay(Color.purple.opacity(0.2))
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .top
        )
    }
}

struct ContentView_Adaptive: View {
    @StateObject private var taskStore = TaskStore()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var musicPlayerManager = MusicPlayerManager.shared
    @State private var currentTab = "sampler"
    @State private var isRouletteMode = false
    @State private var showRandomModeSelection = false
    @State private var isInYearMode = false
    @State private var selectedPriorityTask: Task? = nil
    @State private var showTimerSelection = false
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    
    
    var body: some View {
        Group {
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad layout with split view
                iPadLayout
            } else {
                // iPhone layout
                iPhoneLayout
            }
            #elseif os(macOS)
            // macOS layout uses same as iPad
            iPadLayout
            #else
            // Fallback to iPhone layout
            iPhoneLayout
            #endif
        }
    }
    
    // MARK: - iPhone Layout (current implementation)
    private var iPhoneLayout: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main content area
                    ZStack {
                        // Main navigation switch - exactly like watchOS
                        switch currentTab {
                case "menu":
                    // Default to radio view for menu
                    RadioView(
                        taskStore: taskStore,
                        currentTab: $currentTab
                    )
                    
                case "today":
                    if taskStore.isTimeBlockingEnabled {
                        TodayViewTimeBlocked(taskStore: taskStore, currentTab: $currentTab)
                    } else {
                        TodayView(taskStore: taskStore, currentTab: $currentTab)
                    }
                    
                case "thisWeek":
                    ThisWeekView(taskStore: taskStore, currentTab: $currentTab)
                    
                case "calendar":
                    CalendarView_iOS(taskStore: taskStore, currentTab: $currentTab, isInYearMode: $isInYearMode)
                    
                case "dayView":
                    DayView(taskStore: taskStore, currentTab: $currentTab)
                    
                case "getItDone":
                    GetItDoneView(
                        taskStore: taskStore,
                        currentTab: $currentTab,
                        selectedPriorityTask: $selectedPriorityTask,
                        showTimerSelection: $showTimerSelection,
                        isRouletteMode: $isRouletteMode
                    )
                    
                case "routines":
                    RoutinesView(
                        taskStore: taskStore,
                        currentTab: $currentTab
                    )
                    
                case "radio":
                    RadioView(
                        taskStore: taskStore,
                        currentTab: $currentTab
                    )
                    
                default:
                    // Check if it's a list view
                    if ["later", "appointments", "settings"].contains(currentTab) {
                        ListsView(
                            taskStore: taskStore,
                            currentTab: $currentTab,
                            isProcessing: .constant(false),
                            listId: currentTab,
                            listName: getListName(for: currentTab),
                            backgroundColor: getListColor(for: currentTab)
                        )
                    } else {
                        // Default to radio view
                        RadioView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    }
                }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    handleSwipeGesture(value: value)
                }
        )
    }
    
    // MARK: - iPad Layout with custom UI
    private var iPadLayout: some View {
        ZStack {
            // Black background for music app
            Color.black
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // Custom sidebar - width now handled internally by TodomaiSidebar
                    TodomaiSidebar(taskStore: taskStore, currentTab: $currentTab)
                    
                    // Detail view - each view controls its own background
                    Group {
                    switch currentTab {
                    case "today":
                        if taskStore.isTimeBlockingEnabled {
                            TodayViewTimeBlocked(taskStore: taskStore, currentTab: $currentTab)
                        } else {
                            TodayView(taskStore: taskStore, currentTab: $currentTab)
                        }
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
                    case "settings":
                        SettingsView()
                            .environmentObject(taskStore)
                    case "routines":
                        RoutinesView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    case "radio":
                        RadioView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "organize":
                        OrganizeView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "samples":
                        ModernSamplesView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "edit":
                        if let sample = taskStore.selectedSampleForEdit {
                            SampleEditorView(
                                taskStore: taskStore,
                                currentTab: $currentTab,
                                sample: sample
                            )
                        } else {
                            // Show empty state or sample selector
                            SampleOrganizerView(
                                taskStore: taskStore,
                                currentTab: $currentTab
                            )
                        }
                    
                    case "create":
                        CreateMenuView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "sampler":
                        SamplerView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "beats":
                        BeatsView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "social":
                        // TODO: Implement social view
                        ZStack {
                            themeManager.currentTheme.primaryBackground
                                .ignoresSafeArea()
                            Text("SOCIAL COMING SOON")
                                .font(.system(size: 24, weight: themeManager.currentTheme.headerFont))
                                .foregroundColor(themeManager.currentTheme.primaryText)
                        }
                    
                    case "profile":
                        ProfileView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "albums":
                        AlbumsView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "studio":
                        StudioView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "collabs":
                        CollabsView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "unlocks":
                        UnlocksView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "friends":
                        FriendsView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "store":
                        StoreView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "artstore":
                        ArtStoreView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "mymusic":
                        MyMusicView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "allmusicview":
                        AllMusicView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "favorites":
                        FavoriteSongsView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "remix":
                        RemixView(
                            taskStore: taskStore,
                            currentTab: $currentTab
                        )
                    
                    case "getItDone":
                        GetItDoneView(
                            taskStore: taskStore,
                            currentTab: $currentTab,
                            selectedPriorityTask: $selectedPriorityTask,
                            showTimerSelection: $showTimerSelection,
                            isRouletteMode: $isRouletteMode
                        )
                    case "later", "week", "month", "assignments", "exams",
                         "routine", "goals", "plans", "bills",
                         "projects", "schedule", "ideas", "deadlines",
                         "homework", "study", "notes", "tests",
                         "appointments":
                        ListsView(
                            taskStore: taskStore,
                            currentTab: $currentTab,
                            isProcessing: .constant(false),
                            listId: currentTab,
                            listName: getListName(for: currentTab),
                            backgroundColor: getListColor(for: currentTab)
                        )
                    default:
                        // Default view or empty state
                        ZStack {
                            Color.white.ignoresSafeArea()
                            VStack {
                                Spacer()
                                Text("SELECT A VIEW")
                                    .font(.system(size: 48, weight: .heavy))
                                    .foregroundColor(.black.opacity(0.2))
                                Spacer()
                            }
                        }
                    }
                }
                .id(currentTab) // Force view refresh on tab change
                .animation(nil, value: currentTab) // Remove animation on tab change
            } // End HStack
            } // End VStack
        } // End ZStack
    }
    
    // MARK: - Helper Methods
    private func detailView(for tab: String) -> some View {
        Group {
            switch tab {
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
                EmptyStateView()
            }
        }
    }
    
    private func handleSwipeGesture(value: DragGesture.Value) {
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
        case "radio": return "RADIO"
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
        case "radio": return Color(red: 0.4, green: 0.9, blue: 0.6)
        case "settings": return Color(red: 0.6, green: 0.6, blue: 0.6)
        default: return taskStore.currentMode.getListColor(for: id)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.3))
            Text("Select an item from the sidebar")
                .font(.title)
                .foregroundColor(.gray)
            Spacer()
        }
    }
}

#Preview {
    ContentView_Adaptive()
}