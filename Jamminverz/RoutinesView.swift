import SwiftUI

// MARK: - Wellness Routine Categories
enum WellnessCategory: String, CaseIterable {
    case workout = "workout"
    case meditation = "meditation"
    case selfCare = "selfCare"
    case sleep = "sleep"
    
    var displayName: String {
        switch self {
        case .workout: return "WORKOUT ROUTINES"
        case .meditation: return "MEDITATION ROUTINES"
        case .selfCare: return "SELF-CARE ROUTINES"
        case .sleep: return "SLEEP ROUTINES"
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .workout:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.6, blue: 0.0), Color(red: 1.0, green: 0.8, blue: 0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .meditation:
            return LinearGradient(
                colors: [Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .selfCare:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.4, blue: 0.6), Color(red: 1.0, green: 0.6, blue: 0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sleep:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.3, blue: 0.8), Color(red: 0.4, green: 0.5, blue: 0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var baseColor: Color {
        switch self {
        case .workout: return Color(red: 1.0, green: 0.7, blue: 0.2)
        case .meditation: return Color(red: 0.5, green: 0.5, blue: 1.0)
        case .selfCare: return Color(red: 1.0, green: 0.5, blue: 0.7)
        case .sleep: return Color(red: 0.3, green: 0.4, blue: 0.85)
        }
    }
}

// MARK: - Wellness Routine Model
struct WellnessRoutine: Identifiable {
    let id = UUID()
    let name: String
    let duration: Int // in minutes
    let category: WellnessCategory
    let difficulty: Difficulty
    let description: String
    let steps: [String]
    let modeRecommendation: [ViewMode]
    
    enum Difficulty: String {
        case beginner = "BEGINNER"
        case intermediate = "INTERMEDIATE"
        case advanced = "ADVANCED"
    }
}

// MARK: - Predefined Wellness Routines
extension WellnessRoutine {
    static let allRoutines: [WellnessRoutine] = [
        // Workout Routines
        WellnessRoutine(
            name: "Morning Stretch",
            duration: 10,
            category: .workout,
            difficulty: .beginner,
            description: "Wake up your body with gentle stretches",
            steps: ["Neck rolls", "Shoulder shrugs", "Side bends", "Forward fold", "Cat-cow stretches"],
            modeRecommendation: [ViewMode.life]
        ),
        WellnessRoutine(
            name: "Desk Workout",
            duration: 5,
            category: .workout,
            difficulty: .beginner,
            description: "Quick exercises you can do at your desk",
            steps: ["Desk push-ups", "Seated leg raises", "Chair dips", "Calf raises", "Seated twists"],
            modeRecommendation: [ViewMode.work]
        ),
        WellnessRoutine(
            name: "HIIT Workout",
            duration: 20,
            category: .workout,
            difficulty: .advanced,
            description: "High intensity interval training",
            steps: ["Jumping jacks", "Burpees", "Mountain climbers", "High knees", "Cool down"],
            modeRecommendation: [ViewMode.life]
        ),
        WellnessRoutine(
            name: "Yoga Flow",
            duration: 15,
            category: .workout,
            difficulty: .intermediate,
            description: "Relaxing yoga sequence",
            steps: ["Sun salutation", "Warrior poses", "Tree pose", "Child's pose", "Savasana"],
            modeRecommendation: [ViewMode.life]
        ),
        
        // Meditation Routines
        WellnessRoutine(
            name: "Morning Meditation",
            duration: 10,
            category: .meditation,
            difficulty: .beginner,
            description: "Start your day with mindfulness",
            steps: ["Find comfortable position", "Close eyes", "Focus on breath", "Body scan", "Set intention"],
            modeRecommendation: [ViewMode.life]
        ),
        WellnessRoutine(
            name: "Focus Meditation",
            duration: 5,
            category: .meditation,
            difficulty: .beginner,
            description: "Improve concentration before work",
            steps: ["Sit upright", "Deep breaths", "Count breaths 1-10", "Reset if distracted", "Open eyes slowly"],
            modeRecommendation: [ViewMode.work, ViewMode.school]
        ),
        WellnessRoutine(
            name: "Sleep Meditation",
            duration: 15,
            category: .meditation,
            difficulty: .intermediate,
            description: "Prepare your mind for rest",
            steps: ["Lie down comfortably", "Progressive relaxation", "Visualize peaceful scene", "Release the day", "Drift to sleep"],
            modeRecommendation: [ViewMode.life]
        ),
        
        // Self-Care Routines
        WellnessRoutine(
            name: "Morning Skincare",
            duration: 10,
            category: .selfCare,
            difficulty: .beginner,
            description: "Complete morning skincare routine",
            steps: ["Cleanse face", "Apply toner", "Moisturize", "Apply sunscreen", "Eye cream"],
            modeRecommendation: [ViewMode.life]
        ),
        WellnessRoutine(
            name: "Evening Wind-Down",
            duration: 20,
            category: .selfCare,
            difficulty: .beginner,
            description: "Relax and prepare for tomorrow",
            steps: ["Journal reflections", "Prepare clothes", "Skincare routine", "Read a book", "Set alarm"],
            modeRecommendation: [ViewMode.life]
        ),
        
        // Sleep Routines
        WellnessRoutine(
            name: "Power Nap",
            duration: 20,
            category: .sleep,
            difficulty: .beginner,
            description: "Optimal afternoon energy boost",
            steps: ["Set 20-min timer", "Darken room", "Lie down", "Close eyes", "Wake gently"],
            modeRecommendation: [ViewMode.life]
        ),
        WellnessRoutine(
            name: "Bedtime Routine",
            duration: 30,
            category: .sleep,
            difficulty: .beginner,
            description: "Prepare for quality sleep",
            steps: ["No screens", "Dim lights", "Warm shower", "Light stretching", "Sleep meditation"],
            modeRecommendation: [ViewMode.life]
        )
    ]
}

// MARK: - Enhanced Routines View
struct RoutinesView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @State private var selectedCategory: WellnessCategory? = nil
    @State private var selectedRoutine: WellnessRoutine? = nil
    @State private var showingRoutineDetail = false
    @State private var activeRoutine: WellnessRoutine? = nil
    @State private var routineProgress: Double = 0
    @State private var completedRoutines: Set<UUID> = []
    @State private var quickStartMode = false
    
    var backgroundColor: Color {
        Color(red: 0.8, green: 0.8, blue: 1.0) // Routines purple color
    }
    
    var recommendedRoutines: [WellnessRoutine] {
        WellnessRoutine.allRoutines.filter { routine in
            routine.modeRecommendation.contains(taskStore.currentMode)
        }
    }
    
    var quickStartRoutines: [WellnessRoutine] {
        let timeOfDay = Calendar.current.component(.hour, from: Date())
        
        if timeOfDay < 10 {
            // Morning routines
            return WellnessRoutine.allRoutines.filter { $0.name.contains("Morning") || $0.name == "Energy Check-In" }
        } else if timeOfDay < 14 {
            // Midday routines
            return WellnessRoutine.allRoutines.filter { $0.name.contains("Desk") || $0.name == "Focus Preparation" }
        } else if timeOfDay < 18 {
            // Afternoon routines
            return WellnessRoutine.allRoutines.filter { $0.name.contains("Energy") || $0.name == "Stress Relief" }
        } else {
            // Evening routines
            return WellnessRoutine.allRoutines.filter { $0.name.contains("Evening") || $0.name.contains("Post-Work") }
        }
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            if let active = activeRoutine {
                // Active routine view
                ActiveRoutineView(
                    routine: active,
                    progress: $routineProgress,
                    onComplete: {
                        completedRoutines.insert(active.id)
                        activeRoutine = nil
                        routineProgress = 0
                    },
                    onCancel: {
                        activeRoutine = nil
                        routineProgress = 0
                    }
                )
            } else if quickStartMode {
                // Quick start selection
                QuickStartView(
                    routines: quickStartRoutines,
                    onSelect: { routine in
                        activeRoutine = routine
                        quickStartMode = false
                    },
                    onClose: {
                        quickStartMode = false
                    }
                )
            } else {
                // Main routines view
                VStack(spacing: 0) {
                    // Header
                    Text("ROUTINES")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.black.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            currentTab = "menu"
                        }
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Quick start buttons
                            QuickStartButtonsView(onQuickStart: { quickStartMode = true }, taskStore: taskStore)
                                .padding(.horizontal, 24)
                                .padding(.top, 20)
                            
                            // Category selection
                            CategorySelectionView(
                                selectedCategory: $selectedCategory,
                                completedCount: completedRoutines.count
                            )
                            .padding(.horizontal, 24)
                            
                            // Routines list
                            if let category = selectedCategory {
                                RoutineListView(
                                    routines: WellnessRoutine.allRoutines.filter { $0.category == category },
                                    completedRoutines: completedRoutines,
                                    onSelectRoutine: { routine in
                                        selectedRoutine = routine
                                        showingRoutineDetail = true
                                    }
                                )
                                .padding(.horizontal, 24)
                            } else {
                                // Show recommended routines
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("RECOMMENDED FOR \(taskStore.currentMode.displayName)")
                                        .font(.system(size: 14, weight: .heavy))
                                        .foregroundColor(.black.opacity(0.6))
                                    
                                    RoutineListView(
                                        routines: recommendedRoutines,
                                        completedRoutines: completedRoutines,
                                        onSelectRoutine: { routine in
                                            selectedRoutine = routine
                                            showingRoutineDetail = true
                                        }
                                    )
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showingRoutineDetail) {
            if let routine = selectedRoutine {
                RoutineDetailView(
                    routine: routine,
                    onStart: {
                        showingRoutineDetail = false
                        activeRoutine = routine
                    },
                    onClose: {
                        showingRoutineDetail = false
                    }
                )
            }
        }
    }
}

// MARK: - Quick Start Buttons
struct QuickStartButtonsView: View {
    let onQuickStart: () -> Void
    @ObservedObject var taskStore: TaskStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK START")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.black.opacity(0.6))
            
            HStack(spacing: 12) {
                QuickStartButton(
                    title: "MORNING ROUTINE",
                    color: Color(red: 1.0, green: 0.7, blue: 0.2),
                    action: onQuickStart
                )
                
                QuickStartButton(
                    title: "EVENING ROUTINE",
                    color: Color(red: 0.5, green: 0.5, blue: 1.0),
                    action: onQuickStart
                )
            }
            
            HStack(spacing: 12) {
                QuickStartButton(
                    title: "5-MIN MEDITATION",
                    color: Color(red: 0.6, green: 0.4, blue: 1.0),
                    action: onQuickStart
                )
                
                QuickStartButton(
                    title: "QUICK WORKOUT",
                    color: Color(red: 1.0, green: 0.6, blue: 0.0),
                    action: onQuickStart
                )
            }
        }
    }
}

struct QuickStartButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    ZStack {
                        color
                        Rectangle()
                            .stroke(Color.black, lineWidth: 3)
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Selection
struct CategorySelectionView: View {
    @Binding var selectedCategory: WellnessCategory?
    let completedCount: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("WELLNESS CATEGORIES")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.black.opacity(0.6))
                
                Spacer()
                
                Text("\(completedCount) COMPLETED TODAY")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black.opacity(0.5))
            }
            
            ForEach(WellnessCategory.allCases, id: \.self) { category in
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    selectedCategory = selectedCategory == category ? nil : category
                }) {
                    HStack {
                        Text(category.displayName)
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(selectedCategory == category ? .white : .black)
                        
                        Spacer()
                        
                        if selectedCategory == category {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(
                        ZStack {
                            if selectedCategory == category {
                                category.gradient
                            } else {
                                category.baseColor.opacity(0.3)
                            }
                            Rectangle()
                                .stroke(Color.black, lineWidth: selectedCategory == category ? 4 : 2)
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Routine List
struct RoutineListView: View {
    let routines: [WellnessRoutine]
    let completedRoutines: Set<UUID>
    let onSelectRoutine: (WellnessRoutine) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(routines) { routine in
                RoutineCard(
                    routine: routine,
                    isCompleted: completedRoutines.contains(routine.id),
                    onTap: { onSelectRoutine(routine) }
                )
            }
        }
    }
}

struct RoutineCard: View {
    let routine: WellnessRoutine
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(routine.name)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                    }
                }
                
                Text(routine.description)
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.leading)
                
                HStack {
                    // Duration badge
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text("\(routine.duration) MIN")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        ZStack {
                            routine.category.baseColor
                            Rectangle()
                                .stroke(Color.black, lineWidth: 2)
                        }
                    )
                    
                    // Difficulty badge
                    Text(routine.difficulty.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            ZStack {
                                Color.white
                                Rectangle()
                                    .stroke(Color.black, lineWidth: 2)
                            }
                        )
                    
                    Spacer()
                }
            }
            .padding(16)
            .background(
                ZStack {
                    Color.white
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Routine Detail View
struct RoutineDetailView: View {
    let routine: WellnessRoutine
    let onStart: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            routine.category.gradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        onClose()
                    }) {
                        Text("CLOSE")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title and description
                        VStack(alignment: .leading, spacing: 12) {
                            Text(routine.name)
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundColor(.white)
                            
                            Text(routine.description)
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Info badges
                        HStack(spacing: 16) {
                            InfoBadge(
                                icon: "clock",
                                text: "\(routine.duration) MINUTES",
                                backgroundColor: .white.opacity(0.2)
                            )
                            
                            InfoBadge(
                                icon: "star",
                                text: routine.difficulty.rawValue,
                                backgroundColor: .white.opacity(0.2)
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Steps
                        VStack(alignment: .leading, spacing: 16) {
                            Text("STEPS")
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(.white)
                            
                            ForEach(Array(routine.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 16, weight: .heavy))
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(
                                            ZStack {
                                                Circle()
                                                    .fill(Color.white.opacity(0.2))
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                            }
                                        )
                                    
                                    Text(step)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Start button
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            onStart()
                        }) {
                            Text("START ROUTINE")
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    ZStack {
                                        Color.white
                                        Rectangle()
                                            .stroke(Color.black, lineWidth: 4)
                                    }
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}

struct InfoBadge: View {
    let icon: String
    let text: String
    let backgroundColor: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            ZStack {
                backgroundColor
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
            }
        )
    }
}

// MARK: - Active Routine View
struct ActiveRoutineView: View {
    let routine: WellnessRoutine
    @Binding var progress: Double
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    @State private var currentStep = 0
    @State private var timer: Timer?
    @State private var elapsedTime = 0
    
    var body: some View {
        ZStack {
            routine.category.gradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        timer?.invalidate()
                        onCancel()
                    }) {
                        Text("CANCEL")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("\(formatTime(elapsedTime)) / \(routine.duration):00")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // Current step
                VStack(spacing: 24) {
                    Text("STEP \(currentStep + 1) OF \(routine.steps.count)")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(routine.steps[currentStep])
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Progress indicator
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.white, lineWidth: 8)
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 20) {
                    if currentStep > 0 {
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            currentStep -= 1
                        }) {
                            Text("PREVIOUS")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 48)
                                .background(
                                    ZStack {
                                        Color.white.opacity(0.2)
                                        Rectangle()
                                            .stroke(Color.white, lineWidth: 3)
                                    }
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if currentStep < routine.steps.count - 1 {
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            currentStep += 1
                        }) {
                            Text("NEXT")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.black)
                                .frame(width: 120, height: 48)
                                .background(
                                    ZStack {
                                        Color.white
                                        Rectangle()
                                            .stroke(Color.black, lineWidth: 3)
                                    }
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            timer?.invalidate()
                            onComplete()
                        }) {
                            Text("COMPLETE")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.black)
                                .frame(width: 120, height: 48)
                                .background(
                                    ZStack {
                                        Color.green
                                        Rectangle()
                                            .stroke(Color.black, lineWidth: 3)
                                    }
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
            progress = Double(elapsedTime) / Double(routine.duration * 60)
            
            if elapsedTime >= routine.duration * 60 {
                timer?.invalidate()
                onComplete()
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Quick Start View
struct QuickStartView: View {
    let routines: [WellnessRoutine]
    let onSelect: (WellnessRoutine) -> Void
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("QUICK START")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.white)
                
                Text("Based on your time of day")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                
                VStack(spacing: 16) {
                    ForEach(routines.prefix(4)) { routine in
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            onSelect(routine)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(routine.name)
                                        .font(.system(size: 18, weight: .heavy))
                                        .foregroundColor(.white)
                                    
                                    Text("\(routine.duration) minutes")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 64)
                            .background(
                                ZStack {
                                    routine.category.baseColor
                                    Rectangle()
                                        .stroke(Color.white, lineWidth: 3)
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    onClose()
                }) {
                    Text("CANCEL")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                }
            }
        }
    }
}

#Preview {
    RoutinesView(taskStore: TaskStore(), currentTab: .constant("routines"))
}