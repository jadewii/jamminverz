//
//  AlbumsView.swift
//  Jamminverz
//
//  Create and manage albums from projects
//

import SwiftUI
import AVFoundation

struct AlbumsView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = "my-albums"
    @State private var showCreateAlbum = false
    @State private var albums: [Album] = []
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Selector
                tabSelector
                
                // Content
                ScrollView {
                    switch selectedTab {
                    case "my-albums":
                        myAlbumsView
                    case "favorites":
                        favoritesView
                    default:
                        EmptyView()
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showCreateAlbum) {
            CreateAlbumView(taskStore: taskStore, albums: $albums)
        }
        .onAppear {
            loadAlbums()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("ALBUMS")
                    .font(.system(size: 34, weight: themeManager.currentTheme.headerFont))
                    .foregroundColor(themeManager.currentTheme.primaryText)
                
                Text("Create albums from your projects")
                    .font(.system(size: 14, weight: themeManager.currentTheme.captionFont))
                    .foregroundColor(themeManager.currentTheme.secondaryText)
            }
            
            Spacer()
            
            Button(action: {
                showCreateAlbum = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var tabSelector: some View {
        HStack(spacing: 32) {
            TabButton(title: "MY ALBUMS", isSelected: selectedTab == "my-albums") {
                selectedTab = "my-albums"
            }
            
            TabButton(title: "FAVORITES", isSelected: selectedTab == "favorites") {
                selectedTab = "favorites"
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(themeManager.currentTheme.cardBackground)
    }
    
    private var myAlbumsView: some View {
        VStack(spacing: 20) {
            if albums.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(albums) { album in
                        AlbumsAlbumCard(album: album)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
    }
    
    private var favoritesView: some View {
        VStack(spacing: 20) {
            emptyState
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Albums Yet")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(.white)
            
            Text("Create your first album from your projects")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Button(action: {
                showCreateAlbum = true
            }) {
                Text("CREATE ALBUM")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(30)
            }
        }
        .padding(.top, 100)
    }
    
    private func loadAlbums() {
        // Mock data for now
        albums = []
    }
}

// MARK: - Album Model
struct Album: Identifiable {
    let id = UUID()
    var title: String
    var description: String
    var coverArt: UIImage?
    var tracks: [AlbumTrack]
    var moodTags: [String]
    var isPublic: Bool
    var playCount: Int
    var createdAt: Date
}

struct AlbumTrack: Identifiable {
    let id = UUID()
    var title: String
    var projectId: UUID?
    var duration: TimeInterval
    var audioURL: URL?
}

// MARK: - Album Card
struct AlbumsAlbumCard: View {
    let album: Album
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cover Art
            ZStack {
                if let coverArt = album.coverArt {
                    Image(uiImage: coverArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [themeManager.currentTheme.accentColor, themeManager.currentTheme.secondaryAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 160)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(themeManager.currentTheme.primaryText.opacity(0.8))
                    )
                }
            }
            .cornerRadius(themeManager.currentTheme.cornerRadius)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.system(size: 16, weight: themeManager.currentTheme.headerFont))
                    .foregroundColor(themeManager.currentTheme.primaryText)
                    .lineLimit(1)
                
                Text("\(album.tracks.count) tracks • \(album.playCount) plays")
                    .font(.system(size: 12, weight: themeManager.currentTheme.captionFont))
                    .foregroundColor(themeManager.currentTheme.secondaryText)
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Create Album View
struct CreateAlbumView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var albums: [Album]
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var albumTitle = ""
    @State private var albumDescription = ""
    @State private var selectedProjects: Set<UUID> = []
    @State private var coverArt: UIImage?
    @State private var showImagePicker = false
    @State private var showArtStore = false
    @State private var selectedArtId: String?
    @State private var moodTags: [String] = []
    @State private var isPublic = true
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Cover Art
                        VStack(spacing: 12) {
                            Button(action: {
                                showImagePicker = true
                            }) {
                            ZStack {
                                if let coverArt = coverArt {
                                    Image(uiImage: coverArt)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 200)
                                        .clipped()
                                } else {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 200)
                                        .overlay(
                                            VStack(spacing: 12) {
                                                Image(systemName: "photo.fill")
                                                    .font(.system(size: 40))
                                                Text("ADD COVER ART")
                                                    .font(.system(size: 12, weight: .heavy))
                                            }
                                            .foregroundColor(.gray)
                                        )
                                }
                            }
                            .cornerRadius(12)
                        }
                            
                            // Art Store Button
                            Button(action: {
                                showArtStore = true
                            }) {
                                HStack {
                                    Image(systemName: "photo.artframe")
                                        .font(.system(size: 16))
                                    Text("BROWSE ART GALLERY")
                                        .font(.system(size: 14, weight: .heavy))
                                }
                                .foregroundColor(.purple)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.purple.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Album Info
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ALBUM TITLE")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(.gray)
                                
                                TextField("My Album", text: $albumTitle)
                                    .textFieldStyle(AlbumTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("DESCRIPTION")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(.gray)
                                
                                TextEditor(text: $albumDescription)
                                    .frame(height: 100)
                                    .padding(12)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Project Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SELECT TRACKS FROM PROJECTS")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.gray)
                            
                            Text("No projects available")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .padding(.vertical, 40)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                        }
                        
                        // Mood Tags
                        VStack(alignment: .leading, spacing: 12) {
                            Text("MOOD TAGS")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.gray)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(["Chill", "Energetic", "Dark", "Uplifting", "Experimental"], id: \.self) { tag in
                                        MoodTagButton(tag: tag, isSelected: moodTags.contains(tag)) {
                                            if moodTags.contains(tag) {
                                                moodTags.removeAll { $0 == tag }
                                            } else {
                                                moodTags.append(tag)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Privacy Toggle
                        Toggle(isOn: $isPublic) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PUBLIC ALBUM")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(.white)
                                Text("Allow others to discover and play")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
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
                        
                        Text("CREATE ALBUM")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Create") {
                            createAlbum()
                        }
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.blue)
                        .disabled(albumTitle.isEmpty)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(Color.black)
                    
                    Spacer()
                }
            )
            .sheet(isPresented: $showArtStore) {
                ArtSelectionView(
                    selectedArtId: $selectedArtId,
                    coverArt: $coverArt
                )
            }
        }
    }
    
    private func createAlbum() {
        let newAlbum = Album(
            title: albumTitle,
            description: albumDescription,
            coverArt: coverArt,
            tracks: [],
            moodTags: moodTags,
            isPublic: isPublic,
            playCount: 0,
            createdAt: Date()
        )
        albums.append(newAlbum)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Mood Tag Button
struct MoodTagButton: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white : Color.white.opacity(0.2))
                .cornerRadius(20)
        }
    }
}

// MARK: - Text Field Style
struct AlbumTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .medium))
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: themeManager.currentTheme.headerFont))
                    .foregroundColor(isSelected ? themeManager.currentTheme.primaryText : themeManager.currentTheme.secondaryText)
                
                Rectangle()
                    .fill(isSelected ? themeManager.currentTheme.accentColor : Color.clear)
                    .frame(height: 3)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AlbumsView(
        taskStore: TaskStore(),
        currentTab: .constant("albums")
    )
}