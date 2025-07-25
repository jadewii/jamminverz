//
//  ProfileView.swift
//  Jamminverz
//
//  Profile page with tabs, customization, and content display
//

import SwiftUI
import AVFoundation

// MARK: - Profile View
struct ProfileView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedProfileTab = "profile"
    @State private var isEditingProfile = false
    @State private var profileImage: Image? = nil
    @State private var bannerImage: Image? = nil
    @State private var showProfilePicker = false
    @State private var selectedProfileIcon: String? = nil
    @State private var isHoveringProfile = false
    
    // Profile data
    @State private var username = "jadewii"
    @State private var displayName = "JAde Wii"
    @State private var bio = "Music producer & creative platform builder"
    @State private var profileSong: URL? = nil
    
    // Theme customization
    @State private var primaryColor = Color.purple
    @State private var secondaryColor = Color.pink
    @State private var backgroundColor = Color.black
    
    // Content counts
    @State private var albumCount = 12
    @State private var packCount = 47
    @State private var collabCount = 8
    @State private var projectCount = 156
    @State private var friendCount = 234
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Header
                profileHeader
                
                // Main Content
                ScrollView {
                    VStack(spacing: 0) {
                        // Banner Section
                        bannerSection
                        
                        // Profile Info Section
                        profileInfoSection
                        
                        // Stats Bar
                        statsBar
                        
                        // Tab Navigation
                        profileTabBar
                        
                        // Tab Content
                        profileTabContent
                            .padding(.horizontal, 24)
                            .padding(.bottom, 100)
                    }
                }
            }
        }
        .sheet(isPresented: $isEditingProfile) {
            ProfileEditView(
                username: $username,
                displayName: $displayName,
                bio: $bio,
                profileImage: $profileImage,
                bannerImage: $bannerImage,
                primaryColor: $primaryColor,
                secondaryColor: $secondaryColor,
                backgroundColor: $backgroundColor
            )
        }
        .sheet(isPresented: $showProfilePicker) {
            ProfilePicker(
                selectedIcon: $selectedProfileIcon,
                profileImage: $profileImage,
                isPresented: $showProfilePicker
            )
        }
    }
    
    // MARK: - Header
    private var profileHeader: some View {
        HStack {
            Button(action: {
                currentTab = "organize"
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .heavy))
                    Text("BACK")
                        .font(.system(size: 17, weight: .heavy))
                }
                .foregroundColor(themeManager.currentTheme.primaryText)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Text("PROFILE")
                .font(.system(size: 17, weight: .heavy))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                isEditingProfile = true
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color.black)
    }
    
    // MARK: - Banner Section
    private var bannerSection: some View {
        ZStack(alignment: .bottom) {
            // Banner Image or Gradient
            if let bannerImage = bannerImage {
                bannerImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 200)
            }
            
            // Profile Image
            HStack {
                Button(action: {
                    showProfilePicker = true
                }) {
                    ZStack {
                        Circle()
                            .fill(isHoveringProfile ? Color.black.opacity(0.7) : Color.black)
                            .frame(width: 180, height: 180)
                        
                        if isHoveringProfile {
                            Image(systemName: "plus")
                                .font(.system(size: 75, weight: .medium))
                                .foregroundColor(.white)
                        } else {
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 174, height: 174)
                                    .clipShape(Circle())
                            } else if let icon = selectedProfileIcon {
                                Text(icon)
                                    .font(.system(size: 75))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 75))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    isHoveringProfile = hovering
                }
                .overlay(
                    Circle()
                        .stroke(primaryColor, lineWidth: 6)
                )
                .offset(y: 90)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Profile Info Section
    private var profileInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Spacer().frame(width: 144) // Space for profile image
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName)
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(.white)
                            
                            Text("@\(username)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        
                        // Friend/Follow Button - moved closer to name
                        Button(action: {
                            // Add friend functionality
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.badge.plus")
                                Text("ADD FRIEND")
                            }
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(primaryColor)
                            .cornerRadius(25)
                        }
                    }
                    
                    if !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(3)
                    }
                }
                
                Spacer()
                
                // Friends section moved to the right
                if friendCount > 0 {
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("FRIENDS")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.gray)
                        
                        let maxFriends = min(8, Int(friendCount))
                        HStack(spacing: -10) {
                            ForEach(0..<maxFriends, id: \.self) { index in
                                FriendAvatarCircle(
                                    index: index,
                                    size: 44
                                )
                                .zIndex(Double(8 - index))
                            }
                            
                            if friendCount > 8 {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 44, height: 44)
                                    
                                    Text("+\(friendCount - 8)")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundColor(.white)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 2)
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
    }
    
    // MARK: - Stats Bar
    private var statsBar: some View {
        HStack(spacing: 0) {
            StatItem(count: friendCount, label: "FRIENDS", color: primaryColor)
            StatItem(count: packCount, label: "PACKS", color: primaryColor)
            StatItem(count: projectCount, label: "PROJECTS", color: primaryColor)
            StatItem(count: collabCount, label: "COLLABS", color: primaryColor)
        }
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
        .padding(.top, 20)
    }
    
    // MARK: - Profile Tab Bar
    private var profileTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 32) {
                ProfileTabButton(title: "PROFILE", isSelected: selectedProfileTab == "profile") {
                    selectedProfileTab = "profile"
                }
                ProfileTabButton(title: "PACKS", isSelected: selectedProfileTab == "packs") {
                    selectedProfileTab = "packs"
                }
                ProfileTabButton(title: "ALBUMS", isSelected: selectedProfileTab == "albums") {
                    selectedProfileTab = "albums"
                }
                ProfileTabButton(title: "PROJECTS", isSelected: selectedProfileTab == "projects") {
                    selectedProfileTab = "projects"
                }
                ProfileTabButton(title: "COLLABS", isSelected: selectedProfileTab == "collabs") {
                    selectedProfileTab = "collabs"
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Tab Content
    private var profileTabContent: some View {
        VStack(spacing: 20) {
            switch selectedProfileTab {
            case "profile":
                ProfileOverviewView(primaryColor: primaryColor)
            case "packs":
                ProfilePacksView(primaryColor: primaryColor)
            case "albums":
                ProfileAlbumsView(primaryColor: primaryColor)
            case "projects":
                ProfileProjectsView(primaryColor: primaryColor)
            case "collabs":
                ProfileCollabsView(primaryColor: primaryColor)
            default:
                EmptyView()
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Profile Tab Button
struct ProfileTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(isSelected ? .white : .gray)
                
                Rectangle()
                    .fill(isSelected ? Color.purple : Color.clear)
                    .frame(height: 3)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Profile Overview View
struct ProfileOverviewView: View {
    let primaryColor: Color
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Packs Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("SAMPLE PACKS")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {}) {
                            Text("SEE ALL")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(primaryColor)
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(0..<6) { index in
                                ProfilePackCard(index: index, primaryColor: primaryColor)
                                    .frame(width: 180)
                            }
                        }
                    }
                }
                
                // Albums Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("ALBUMS")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {}) {
                            Text("SEE ALL")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(primaryColor)
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(0..<4) { index in
                                ProfileAlbumCard(index: index, primaryColor: primaryColor)
                                    .frame(width: 180)
                            }
                        }
                    }
                }
                
                // Projects Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("PROJECTS")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {}) {
                            Text("SEE ALL")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(primaryColor)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(0..<3) { index in
                            ProjectRow(index: index, primaryColor: primaryColor)
                        }
                    }
                }
                
                // Collabs Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("COLLABS")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {}) {
                            Text("SEE ALL")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(primaryColor)
                        }
                    }
                    
                    VStack(spacing: 16) {
                        ForEach(0..<2) { index in
                            ProfileCollabCard(index: index, primaryColor: primaryColor)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Profile Packs View
struct ProfilePacksView: View {
    let primaryColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Sample packs section header
            HStack {
                Text("SAMPLE PACKS")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {}) {
                    Text("SEE ALL")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(primaryColor)
                }
            }
            
            // Sample packs grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 24), count: 6), spacing: 24) {
                ForEach(0..<6) { index in
                    SamplePackViewWithAdd(index: index)
                }
            }
        }
    }
}

// MARK: - Sample Pack View With Add Button
struct SamplePackViewWithAdd: View {
    let index: Int
    @State private var isAdded = false
    @State private var isHovering = false
    
    private let colors: [Color] = [.purple, .pink, .blue, .green, .orange, .red]
    private let packColor: Color
    private let gridOpacities: [Double] = (0..<16).map { _ in Double.random(in: 0.3...0.8) }
    
    init(index: Int) {
        self.index = index
        self.packColor = colors[index % colors.count]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Pack Preview Grid
            ZStack(alignment: .topTrailing) {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 1),
                    GridItem(.flexible(), spacing: 1),
                    GridItem(.flexible(), spacing: 1),
                    GridItem(.flexible(), spacing: 1)
                ], spacing: 1) {
                    ForEach(0..<16) { i in
                        Rectangle()
                            .fill(packColor.opacity(gridOpacities[i]))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .padding(8)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
                // Heart+ Add button
                Button(action: {
                    withAnimation(.spring()) {
                        isAdded.toggle()
                        if isAdded {
                            // Add to sampler
                            addPackToSampler()
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isAdded ? Color.green : Color.white.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: isAdded ? "checkmark" : "heart")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        
                        if !isAdded {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: 10, y: -10)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .offset(x: -4, y: 4)
            }
            
            // Pack name and stats
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Sample Pack \(index + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 9))
                        Text("\(Int.random(in: 10...50))")
                            .font(.system(size: 10))
                    }
                    
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 9))
                        Text("\(Int.random(in: 100...999))")
                            .font(.system(size: 10))
                    }
                }
                .foregroundColor(.gray)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(isHovering ? 0.1 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isAdded ? packColor : Color.white.opacity(0.2),
                    lineWidth: isAdded ? 2 : 1
                )
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private func addPackToSampler() {
        // This would add the pack to the user's sampler collection
        // For now, just a placeholder
        print("Added Sample Pack \(index + 1) to sampler")
    }
}

// MARK: - Pack Card (Original style for other views)
struct ProfilePackCard: View {
    let index: Int
    let primaryColor: Color
    
    private let gridOpacities: [Double] = (0..<16).map { _ in Double.random(in: 0.3...0.8) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Pack Preview Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2)
            ], spacing: 2) {
                ForEach(0..<16) { i in
                    Rectangle()
                        .fill(primaryColor.opacity(gridOpacities[i]))
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(2)
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Sample Pack \(index + 1)")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
                
                HStack {
                    Label("\(Int.random(in: 10...50))", systemImage: "square.grid.2x2")
                    Label("\(Int.random(in: 100...999))", systemImage: "arrow.down.circle")
                }
                .font(.system(size: 11))
                .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Profile Albums View
struct ProfileAlbumsView: View {
    let primaryColor: Color
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<4) { index in
                    ProfileAlbumCard(index: index, primaryColor: primaryColor)
                        .frame(width: 260)
                }
            }
        }
    }
}

// MARK: - Album Card
struct ProfileAlbumCard: View {
    let index: Int
    let primaryColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Album Cover
            ZStack {
                LinearGradient(
                    colors: [primaryColor, primaryColor.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(8)
                
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Album \(index + 1)")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
                
                Text("\(Int.random(in: 8...16)) tracks")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Profile Projects View
struct ProfileProjectsView: View {
    let primaryColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<5) { index in
                ProjectRow(index: index, primaryColor: primaryColor)
            }
        }
    }
}

// MARK: - Project Row
struct ProjectRow: View {
    let index: Int
    let primaryColor: Color
    
    private let waveformData: [(opacity: Double, height: CGFloat)] = (0..<30).map { _ in
        (opacity: Double.random(in: 0.3...1.0),
         height: CGFloat.random(in: 10...40))
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Waveform Preview
            HStack(spacing: 1) {
                ForEach(0..<30) { index in
                    Rectangle()
                        .fill(primaryColor.opacity(waveformData[index].opacity))
                        .frame(width: 2, height: waveformData[index].height)
                }
            }
            .frame(width: 80, height: 50)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Project \(index + 1)")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Label("\(Int.random(in: 80...140)) BPM", systemImage: "metronome")
                    Label("3:24", systemImage: "clock")
                }
                .font(.system(size: 11))
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(primaryColor)
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Profile Collabs View
struct ProfileCollabsView: View {
    let primaryColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3) { index in
                ProfileCollabCard(index: index, primaryColor: primaryColor)
            }
        }
    }
}

// MARK: - Collab Card
struct ProfileCollabCard: View {
    let index: Int
    let primaryColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Collaborators
                HStack(spacing: -10) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text("\(i + 1)")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                    }
                }
                
                Spacer()
                
                Label("COLLAB", systemImage: "person.2.fill")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(primaryColor)
            }
            
            Text("Collaboration Project \(index + 1)")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(.white)
            
            Text("A collaborative beat created with friends")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .lineLimit(2)
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Profile Edit View
struct ProfileEditView: View {
    @Binding var username: String
    @Binding var displayName: String
    @Binding var bio: String
    @Binding var profileImage: Image?
    @Binding var bannerImage: Image?
    @Binding var primaryColor: Color
    @Binding var secondaryColor: Color
    @Binding var backgroundColor: Color
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showingImagePicker = false
    @State private var imagePickerType: ImagePickerType = .profile
    @State private var showArtGallery = false
    @State private var selectedBannerArtId: String?
    
    enum ImagePickerType {
        case profile, banner
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Image Editor
                        VStack(spacing: 12) {
                            Text("PROFILE IMAGE")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                imagePickerType = .profile
                                showingImagePicker = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 120, height: 120)
                                    
                                    if let profileImage = profileImage {
                                        profileImage
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 116, height: 116)
                                            .clipShape(Circle())
                                    } else {
                                        VStack(spacing: 8) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 30))
                                            Text("ADD PHOTO")
                                                .font(.system(size: 10, weight: .heavy))
                                        }
                                        .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        
                        // Banner Image Editor
                        VStack(spacing: 12) {
                            Text("BANNER IMAGE")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                imagePickerType = .banner
                                showingImagePicker = true
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 150)
                                    
                                    if let bannerImage = bannerImage {
                                        bannerImage
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 150)
                                            .clipped()
                                            .cornerRadius(12)
                                    } else {
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo.fill")
                                                .font(.system(size: 30))
                                            Text("ADD BANNER")
                                                .font(.system(size: 10, weight: .heavy))
                                        }
                                        .foregroundColor(.gray)
                                    }
                                }
                            }
                            
                            // Gallery button for banner
                            Button(action: {
                                showArtGallery = true
                            }) {
                                HStack {
                                    Image(systemName: "photo.artframe")
                                        .font(.system(size: 14))
                                    Text("SELECT FROM GALLERY")
                                        .font(.system(size: 12, weight: .heavy))
                                }
                                .foregroundColor(.purple)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color.purple.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Profile Info
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("USERNAME")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(.gray)
                                
                                TextField("Username", text: $username)
                                    .textFieldStyle(ProfileTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("DISPLAY NAME")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(.gray)
                                
                                TextField("Display Name", text: $displayName)
                                    .textFieldStyle(ProfileTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("BIO")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(.gray)
                                
                                TextEditor(text: $bio)
                                    .frame(height: 100)
                                    .padding(12)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Theme Customization
                        VStack(alignment: .leading, spacing: 16) {
                            Text("THEME COLORS")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 20) {
                                ColorPickerButton(title: "PRIMARY", color: $primaryColor)
                                ColorPickerButton(title: "SECONDARY", color: $secondaryColor)
                                ColorPickerButton(title: "BACKGROUND", color: $backgroundColor)
                            }
                        }
                    }
                    .padding(24)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showArtGallery) {
                ArtSelectionView(
                    selectedArtId: $selectedBannerArtId,
                    coverArt: .constant(nil)
                )
                .onDisappear {
                    // Load selected art as banner
                    if let artId = selectedBannerArtId {
                        // TODO: Load actual image from art ID
                        loadArtAsBanner(artId: artId)
                    }
                }
            }
            .overlay(
                VStack {
                    HStack {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("EDIT PROFILE")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Save") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(Color.black)
                    
                    Spacer()
                }
            )
        }
    }
    
    private func loadArtAsBanner(artId: String) {
        // TODO: Load actual image from ArtStoreManager
        // For now, create a placeholder gradient
        let size = CGSize(width: 800, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        bannerImage = Image(uiImage: renderer.image { context in
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [UIColor.purple.cgColor, UIColor.systemPink.cgColor] as CFArray,
                locations: nil
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        })
    }
}

// MARK: - Color Picker Button
struct ColorPickerButton: View {
    let title: String
    @Binding var color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(.gray)
            
            ColorPicker("", selection: $color)
                .labelsHidden()
                .frame(width: 60, height: 60)
                .background(color)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                )
        }
    }
}

// MARK: - Text Field Style
struct ProfileTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .medium))
    }
}

// MARK: - Friend Avatar Circle
struct FriendAvatarCircle: View {
    let index: Int
    let size: CGFloat
    
    // Mock data for friend avatars - in real app, this would come from friend data
    private let mockFriends = [
        ("🎭", Color.gray),
        ("🦊", Color.green),
        ("🐕", Color.brown),
        ("d", Color.orange),
        ("🚫", Color.red),
        ("🌄", Color.blue),
        ("D", Color.purple),
        ("👨", Color.black)
    ]
    
    var body: some View {
        ZStack {
            if index < mockFriends.count {
                Circle()
                    .fill(mockFriends[index].1)
                    .frame(width: size, height: size)
                
                Text(mockFriends[index].0)
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.white)
            } else {
                // Fallback for additional friends
                Circle()
                    .fill(Color.gray)
                    .frame(width: size, height: size)
                
                Text("👤")
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.white)
            }
        }
        .overlay(
            Circle()
                .stroke(Color.black, lineWidth: 2)
        )
    }
}

// MARK: - Profile Picker
struct ProfilePicker: View {
    @Binding var selectedIcon: String?
    @Binding var profileImage: Image?
    @Binding var isPresented: Bool
    @State private var showingImagePicker = false
    
    let profileIcons: [(String, Color)] = {
        let icons1 = [
            ("👤", Color.gray),
            ("🎭", Color.purple),
            ("🦊", Color.orange),
            ("🐕", Color.brown),
            ("🎵", Color.blue)
        ]
        let icons2 = [
            ("🎸", Color.red),
            ("🎹", Color.indigo),
            ("🎤", Color.pink),
            ("🎧", Color.green),
            ("🥁", Color.orange)
        ]
        let icons3 = [
            ("🎺", Color.yellow),
            ("🎻", Color.brown),
            ("🎨", Color.purple),
            ("🌟", Color.yellow),
            ("🔥", Color.red)
        ]
        let icons4 = [
            ("💎", Color.cyan),
            ("🚀", Color.blue),
            ("🌈", Color.pink),
            ("⚡", Color.yellow),
            ("🌙", Color.indigo)
        ]
        return icons1 + icons2 + icons3 + icons4
    }()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Choose Profile Picture")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Upload button
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                            Text("UPLOAD PHOTO")
                                .font(.system(size: 16, weight: .heavy))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.purple)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    
                    // Icon grid
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            // Free Icons Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("OR CHOOSE AN ICON")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 24)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16)
                                ], spacing: 16) {
                                    ForEach(0..<profileIcons.count, id: \.self) { index in
                                        Button(action: {
                                            selectedIcon = profileIcons[index].0
                                            profileImage = nil
                                            isPresented = false
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(profileIcons[index].1)
                                                    .frame(width: 57, height: 57)
                                                
                                                Text(profileIcons[index].0)
                                                    .font(.system(size: 28))
                                                    .foregroundColor(.white)
                                            }
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedIcon == profileIcons[index].0 ? Color.white : Color.clear, lineWidth: 2)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            // Pro Avatars Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("PRO AVATARS")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 24)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16)
                                ], spacing: 16) {
                                    ForEach(0..<18, id: \.self) { index in
                                        Button(action: {
                                            // Show upgrade prompt
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 57, height: 57)
                                                
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 20, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(
                VStack {
                    HStack {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.gray)
                        .padding()
                        
                        Spacer()
                    }
                    Spacer()
                }
            )
        }
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first,
                   let data = try? Data(contentsOf: url),
                   let uiImage = UIImage(data: data) {
                    profileImage = Image(uiImage: uiImage)
                    selectedIcon = nil
                    isPresented = false
                }
            case .failure(let error):
                print("Error selecting image: \(error)")
            }
        }
    }
}

#Preview {
    ProfileView(
        taskStore: TaskStore(),
        currentTab: .constant("profile")
    )
}