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
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 120, height: 120)
                    
                    if let profileImage = profileImage {
                        profileImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 116, height: 116)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(primaryColor, lineWidth: 4)
                )
                .offset(y: 60)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Profile Info Section
    private var profileInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer().frame(width: 144) // Space for profile image
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(displayName)
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text("@\(username)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    if !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(3)
                    }
                }
                
                Spacer()
                
                // Friend/Follow Button
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<6) { index in
                    ProfilePackCard(index: index, primaryColor: primaryColor)
                        .frame(width: 260)
                }
            }
        }
    }
}

// MARK: - Pack Card
struct ProfilePackCard: View {
    let index: Int
    let primaryColor: Color
    
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
                        .fill(primaryColor.opacity(Double.random(in: 0.3...0.8)))
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
    
    var body: some View {
        HStack(spacing: 16) {
            // Waveform Preview
            HStack(spacing: 1) {
                ForEach(0..<30) { _ in
                    Rectangle()
                        .fill(primaryColor.opacity(Double.random(in: 0.3...1.0)))
                        .frame(width: 2, height: CGFloat.random(in: 10...40))
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

#Preview {
    ProfileView(
        taskStore: TaskStore(),
        currentTab: .constant("profile")
    )
}