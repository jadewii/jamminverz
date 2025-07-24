//
//  CollabsView.swift
//  Jamminverz
//
//  Collaboration system for joint projects
//

import SwiftUI

struct CollabsView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @State private var selectedTab = "active"
    @State private var collabs: [Collab] = []
    @State private var featuredOn: [Collab] = []
    @State private var showCreateCollab = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Selector
                tabSelector
                
                // Content
                ScrollView {
                    switch selectedTab {
                    case "active":
                        activeCollabsView
                    case "featured":
                        featuredOnView
                    default:
                        EmptyView()
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showCreateCollab) {
            CreateCollabView(collabs: $collabs)
        }
        .onAppear {
            loadCollabs()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("COLLABS")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundColor(.white)
                
                Text("Work together with friends on projects")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                showCreateCollab = true
            }) {
                Image(systemName: "person.2.badge.plus")
                    .font(.system(size: 28))
                    .foregroundColor(.pink)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var tabSelector: some View {
        HStack(spacing: 32) {
            TabButton(title: "ACTIVE COLLABS", isSelected: selectedTab == "active") {
                selectedTab = "active"
            }
            
            TabButton(title: "FEATURED ON", isSelected: selectedTab == "featured") {
                selectedTab = "featured"
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
    }
    
    private var activeCollabsView: some View {
        VStack(spacing: 16) {
            if collabs.isEmpty {
                emptyCollabsState
            } else {
                ForEach(collabs) { collab in
                    CollabsCollabCard(collab: collab)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    private var featuredOnView: some View {
        VStack(spacing: 16) {
            if featuredOn.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "star.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Features Yet")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.gray)
                    
                    Text("Projects where you've been credited will appear here")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 100)
            } else {
                ForEach(featuredOn) { collab in
                    FeaturedCard(collab: collab)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    private var emptyCollabsState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Collaborations Yet")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(.white)
            
            Text("Start a collaboration with friends")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Button(action: {
                showCreateCollab = true
            }) {
                Text("START COLLAB")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.pink)
                    .cornerRadius(30)
            }
        }
        .padding(.top, 100)
    }
    
    private func loadCollabs() {
        // Mock data
        collabs = [
            Collab(
                id: "1",
                title: "Summer Vibes EP",
                type: .album,
                participants: [
                    CollabParticipant(username: "jadewii", displayName: "JAde Wii", avatar: "👑", role: "Producer"),
                    CollabParticipant(username: "beatmaker23", displayName: "BeatMaker", avatar: "🎵", role: "Co-Producer")
                ],
                lastUpdated: Date(),
                progress: 0.75
            ),
            Collab(
                id: "2",
                title: "Trap Pack Vol. 2",
                type: .samplePack,
                participants: [
                    CollabParticipant(username: "jadewii", displayName: "JAde Wii", avatar: "👑", role: "Sound Design"),
                    CollabParticipant(username: "synthwave_pro", displayName: "SynthWave Pro", avatar: "🎹", role: "Synths"),
                    CollabParticipant(username: "lofi_vibes", displayName: "Lofi Vibes", avatar: "🎧", role: "Mixing")
                ],
                lastUpdated: Date().addingTimeInterval(-86400),
                progress: 0.45
            )
        ]
    }
}

// MARK: - Collab Model
struct Collab: Identifiable {
    let id: String
    let title: String
    let type: CollabType
    let participants: [CollabParticipant]
    let lastUpdated: Date
    let progress: Double
}

enum CollabType {
    case project
    case album
    case samplePack
    
    var icon: String {
        switch self {
        case .project: return "🎼"
        case .album: return "💿"
        case .samplePack: return "📦"
        }
    }
}

struct CollabParticipant {
    let username: String
    let displayName: String
    let avatar: String
    let role: String
}

// MARK: - Collab Card
struct CollabsCollabCard: View {
    let collab: Collab
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(collab.type.icon)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(collab.title)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text("Last updated \(timeAgo(collab.lastUpdated))")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Progress
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(collab.progress * 100))%")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.pink)
                    Text("COMPLETE")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.pink)
                        .frame(width: geometry.size.width * collab.progress, height: 4)
                }
            }
            .frame(height: 4)
            
            // Participants
            HStack {
                ForEach(collab.participants.indices, id: \.self) { index in
                    if index < 3 {
                        ParticipantAvatar(participant: collab.participants[index])
                            .offset(x: CGFloat(index * -10))
                    }
                }
                
                if collab.participants.count > 3 {
                    Text("+\(collab.participants.count - 3)")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.gray)
                        .clipShape(Circle())
                        .offset(x: CGFloat(2 * -10))
                }
                
                Spacer()
                
                Button(action: {}) {
                    Text("OPEN")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    .background(Color.pink)
                        .cornerRadius(20)
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

// MARK: - Participant Avatar
struct ParticipantAvatar: View {
    let participant: CollabParticipant
    
    var body: some View {
        VStack(spacing: 0) {
            Text(participant.avatar)
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                )
        }
    }
}

// MARK: - Featured Card
struct FeaturedCard: View {
    let collab: Collab
    
    var body: some View {
        HStack(spacing: 16) {
            Text(collab.type.icon)
                .font(.system(size: 30))
                .frame(width: 60, height: 60)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(collab.title)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                
                Text("by \(collab.participants.first?.displayName ?? "Unknown")")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Label("Featured as \(collab.participants.first(where: { $0.username == "jadewii" })?.role ?? "Contributor")", systemImage: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.yellow)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Create Collab View
struct CreateCollabView: View {
    @Binding var collabs: [Collab]
    @Environment(\.presentationMode) var presentationMode
    
    @State private var collabTitle = ""
    @State private var collabType: CollabType = .project
    @State private var selectedFriends: Set<String> = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Collab Info
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("COLLAB TITLE")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(.gray)
                                
                                TextField("My Collab", text: $collabTitle)
                                    .textFieldStyle(CollabTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TYPE")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(.gray)
                                
                                Picker("", selection: $collabType) {
                                    Label("Project", systemImage: "music.note").tag(CollabType.project)
                                    Label("Album", systemImage: "music.note.list").tag(CollabType.album)
                                    Label("Sample Pack", systemImage: "square.grid.2x2").tag(CollabType.samplePack)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                        }
                        
                        // Friend Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("INVITE FRIENDS")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.gray)
                            
                            Text("No friends to invite")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .padding(.vertical, 40)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationBarHidden(true)
            .overlay(
                VStack {
                    HStack {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("START COLLAB")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Create") {
                            createCollab()
                        }
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.pink)
                        .disabled(collabTitle.isEmpty)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(Color.black)
                    
                    Spacer()
                }
            )
        }
    }
    
    private func createCollab() {
        let newCollab = Collab(
            id: UUID().uuidString,
            title: collabTitle,
            type: collabType,
            participants: [
                CollabParticipant(username: "jadewii", displayName: "JAde Wii", avatar: "👑", role: "Creator")
            ],
            lastUpdated: Date(),
            progress: 0.0
        )
        collabs.append(newCollab)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Text Field Style
struct CollabTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .medium))
    }
}

#Preview {
    CollabsView(
        taskStore: TaskStore(),
        currentTab: .constant("collabs")
    )
}