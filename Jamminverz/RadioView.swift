//
//  RadioView.swift
//  Todomai-iOS
//
//  Radio stations grid view with beautiful custom design
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Radio View
struct RadioView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @StateObject private var downloadManager = StationDownloadManager.shared
    @StateObject private var playlistManager = PlaylistManager.shared
    @State private var selectedStation: MusicStation? = nil
    @State private var showingStationDetail = false
    @State private var showingMusicPlayer = false
    @State private var selectedTab = 0 // 0 = RADIO, 1 = MYMUSIC
    @State private var showingFilePicker = false
    @State private var showingNamePrompt = false
    @State private var selectedAudioFiles: [URL] = []
    @State private var newPlaylistName = ""
    @State private var showingCustomFileBrowser = false
    
    let stations = [
        StationDownloadManager.shared.lofiStation,
        StationDownloadManager.shared.getStation(by: "piano"),
        StationDownloadManager.shared.getStation(by: "hiphop"),
        StationDownloadManager.shared.getStation(by: "jungle")
    ]
    
    var backgroundColor: Color {
        Color.black // New black background theme
    }
    
    var body: some View {
        mainContent
            .sheet(isPresented: $showingStationDetail) {
                stationDetailSheet
            }
            .fullScreenCover(isPresented: $showingMusicPlayer) {
                musicPlayerSheet
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    selectedAudioFiles = urls
                    showingNamePrompt = true
                case .failure(let error):
                    print("File picker error: \(error)")
                }
            }
            .alert("Name Your Playlist", isPresented: $showingNamePrompt) {
                TextField("Playlist name", text: $newPlaylistName)
                Button("Cancel", role: .cancel) {
                    selectedAudioFiles = []
                    newPlaylistName = ""
                }
                Button("Create") {
                    if !newPlaylistName.isEmpty {
                        playlistManager.createPlaylist(name: newPlaylistName, audioFiles: selectedAudioFiles)
                        selectedAudioFiles = []
                        newPlaylistName = ""
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCustomFileBrowser) {
                CustomFileBrowser(
                    selectedFiles: $selectedAudioFiles,
                    isPresented: $showingCustomFileBrowser,
                    onFilesSelected: {
                        if !selectedAudioFiles.isEmpty {
                            showingNamePrompt = true
                        }
                    }
                )
            }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                // Tab selector
                tabSelector
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                
                // Content based on selected tab
                Group {
                    if selectedTab == 0 {
                        // RADIO content
                        ScrollView {
                            VStack(spacing: 24) {
                                titleView
                                stationsGridView
                                descriptionView
                            }
                            .padding(.bottom, 40)
                        }
                    } else {
                        // MYMUSIC content
                        myMusicContent
                    }
                }
                .animation(nil, value: selectedTab)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                currentTab = "menu"
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                    Text("BACK")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Text("MUSIC")
                .font(.system(size: 17, weight: .heavy))
                .foregroundColor(.white)
            
            Spacer()
            
            // Invisible spacer to balance the header
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.clear)
                Text("BACK")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.clear)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            // RADIO tab
            Button(action: {
                selectedTab = 0
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                Text("RADIO")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(selectedTab == 0 ? Color.black : .white.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .frame(maxHeight: .infinity)
            .background(selectedTab == 0 ? Color(red: 0.373, green: 0.275, blue: 0.569) : Color.clear)
            .buttonStyle(PlainButtonStyle())
            
            // MYMUSIC tab
            Button(action: {
                selectedTab = 1
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                Text("MY MUSIC")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(selectedTab == 1 ? Color.black : .white.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .frame(maxHeight: .infinity)
            .background(selectedTab == 1 ? Color(red: 0.373, green: 0.275, blue: 0.569) : Color.clear)
            .buttonStyle(PlainButtonStyle())
        }
        .frame(height: 44)
        .background(Color.white.opacity(0.2))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var myMusicContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("MY PLAYLISTS")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                playlistsGridView
                
                Text("Upload your favorite tracks")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 20)
            }
            .padding(.bottom, 40)
        }
    }
    
    private var playlistsGridView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Show existing playlists
                ForEach(playlistManager.playlists) { playlist in
                    PlaylistCard(playlist: playlist) {
                        // TODO: Open playlist player
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            playlistManager.deletePlaylist(playlist)
                        } label: {
                            Label("Delete Playlist", systemImage: "trash")
                        }
                    }
                }
                
                // Add Music card
                AddMusicCard {
                    showingCustomFileBrowser = true
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var titleView: some View {
        Text("SELECT A STATION")
            .font(.system(size: 28, weight: .heavy))
            .foregroundColor(.white)
            .padding(.top, 20)
    }
    
    private var stationsGridView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(stations, id: \.id) { station in
                    StationCard(
                        station: station,
                        downloadState: downloadManager.downloadStates[station.id] ?? .notDownloaded,
                        action: {
                            selectedStation = station
                            
                            // If downloaded, show player; otherwise show detail
                            if downloadManager.downloadStates[station.id] == .downloaded {
                                showingMusicPlayer = true
                            } else {
                                showingStationDetail = true
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var descriptionView: some View {
        VStack(spacing: 16) {
            Text("TAP A STATION TO LISTEN")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text("DOWNLOAD STATIONS FOR OFFLINE LISTENING")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.top, 40)
    }
    
    @ViewBuilder
    private var stationDetailSheet: some View {
        if let station = selectedStation {
            StationDetailView(
                station: station,
                downloadManager: downloadManager,
                onClose: {
                    showingStationDetail = false
                    selectedStation = nil
                }
            )
        }
    }
    
    @ViewBuilder
    private var musicPlayerSheet: some View {
        if let station = selectedStation {
            MusicPlayerView(
                station: station,
                downloadManager: downloadManager,
                onClose: {
                    showingMusicPlayer = false
                    selectedStation = nil
                }
            )
        }
    }
}

// MARK: - Station Card Component
struct StationCard: View {
    let station: MusicStation
    let downloadState: StationDownloadState
    let action: () -> Void
    
    var statusIcon: String {
        switch downloadState {
        case .downloaded:
            return "play.circle.fill"
        case .downloading:
            return "arrow.down.circle.fill"
        default:
            return station.isAvailable ? "arrow.down.circle" : "lock.circle"
        }
    }
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 0) {
                // Station icon placeholder
                ZStack {
                    Rectangle()
                        .fill(station.color)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.system(size: 42, weight: .heavy))
                            .foregroundColor(.white)
                        
                        // Download status indicator
                        if case .downloading(let progress) = downloadState {
                            ProgressView(value: progress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .tint(.white)
                                .frame(width: 100)
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        } else {
                            Image(systemName: statusIcon)
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .frame(width: 208, height: 208)
                
                // Station info
                VStack(spacing: 3) {
                    Text(station.name)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.white)
                    
                    if station.isAvailable {
                        Text("\(station.songCount) songs")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("COMING SOON")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    station.color
                        .overlay(Color.black.opacity(0.2))
                )
            }
            .background(station.color)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Station Detail View
struct StationDetailView: View {
    let station: MusicStation
    @ObservedObject var downloadManager: StationDownloadManager
    let onClose: () -> Void
    @State private var shouldShowPlayer = false
    
    var downloadState: StationDownloadState {
        downloadManager.downloadStates[station.id] ?? .notDownloaded
    }
    
    var body: some View {
        ZStack {
            station.color.ignoresSafeArea()
            
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
                    
                    if case .downloaded = downloadState {
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            downloadManager.deleteStation(station.id)
                        }) {
                            Text("DELETE")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Station icon
                        VStack(spacing: 16) {
                            ZStack {
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 160, height: 160)
                                
                                Image(systemName: "music.note")
                                    .font(.system(size: 80, weight: .heavy))
                                    .foregroundColor(.white)
                            }
                            .overlay(
                                Rectangle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            
                            Text(station.name)
                                .font(.system(size: 36, weight: .heavy))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)
                        
                        if station.isAvailable {
                            // Station info
                            VStack(spacing: 20) {
                                HStack(spacing: 40) {
                                    VStack(spacing: 4) {
                                        Text("\(station.songCount)")
                                            .font(.system(size: 32, weight: .heavy))
                                            .foregroundColor(.white)
                                        Text("SONGS")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    VStack(spacing: 4) {
                                        Text("~\(station.totalSizeMB)")
                                            .font(.system(size: 32, weight: .heavy))
                                            .foregroundColor(.white)
                                        Text("MB")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                
                                // Download button/status
                                Group {
                                    switch downloadState {
                                    case .notDownloaded:
                                        Button(action: {
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                            impactFeedback.impactOccurred()
                                            downloadManager.downloadStation(station)
                                        }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "arrow.down.circle.fill")
                                                    .font(.system(size: 24))
                                                Text("DOWNLOAD STATION")
                                                    .font(.system(size: 18, weight: .heavy))
                                            }
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 64)
                                            .background(Color.white)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color.black, lineWidth: 4)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                    case .downloading(let progress):
                                        VStack(spacing: 16) {
                                            Text("DOWNLOADING...")
                                                .font(.system(size: 18, weight: .heavy))
                                                .foregroundColor(.white)
                                            
                                            StationDownloadProgressView(progress: progress)
                                                .frame(height: 40)
                                            
                                            Button(action: {
                                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                                impactFeedback.impactOccurred()
                                                downloadManager.cancelDownload()
                                            }) {
                                                Text("CANCEL")
                                                    .font(.system(size: 16, weight: .heavy))
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                        }
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white.opacity(0.1))
                                        .overlay(
                                            Rectangle()
                                                .stroke(Color.white, lineWidth: 3)
                                        )
                                        
                                    case .downloaded:
                                        VStack(spacing: 16) {
                                            Button(action: {
                                                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                                impactFeedback.impactOccurred()
                                                shouldShowPlayer = true
                                            }) {
                                                HStack(spacing: 12) {
                                                    Image(systemName: "play.circle.fill")
                                                        .font(.system(size: 28))
                                                    Text("PLAY STATION")
                                                        .font(.system(size: 20, weight: .heavy))
                                                }
                                                .foregroundColor(.black)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 72)
                                                .background(Color.white)
                                                .overlay(
                                                    Rectangle()
                                                        .stroke(Color.black, lineWidth: 4)
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            HStack(spacing: 12) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.green)
                                                Text("DOWNLOADED")
                                                    .font(.system(size: 14, weight: .heavy))
                                                    .foregroundColor(.white.opacity(0.8))
                                            }
                                        }
                                        
                                    case .error(let message):
                                        VStack(spacing: 8) {
                                            Text("ERROR")
                                                .font(.system(size: 16, weight: .heavy))
                                                .foregroundColor(.red)
                                            Text(message)
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.7))
                                                .multilineTextAlignment(.center)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.red.opacity(0.2))
                                        .overlay(
                                            Rectangle()
                                                .stroke(Color.red, lineWidth: 3)
                                        )
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        } else {
                            // Coming soon message
                            VStack(spacing: 16) {
                                Text("COMING SOON")
                                    .font(.system(size: 24, weight: .heavy))
                                    .foregroundColor(.white)
                                
                                Text("This station will be available in a future update")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .fullScreenCover(isPresented: $shouldShowPlayer) {
            MusicPlayerView(
                station: station,
                downloadManager: downloadManager,
                onClose: {
                    shouldShowPlayer = false
                }
            )
        }
    }
}

// MARK: - Playlist Card
struct PlaylistCard: View {
    let playlist: Playlist
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 0) {
                // Main content area with icon
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.6, green: 0.4, blue: 1.0),
                                    Color(red: 0.5, green: 0.3, blue: 0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 42, weight: .heavy))
                            .foregroundColor(.white)
                        
                        // Play icon
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(width: 208, height: 208)
                
                // Bottom info section with darker background
                VStack(spacing: 3) {
                    Text(playlist.name.uppercased())
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(playlist.songCount) songs")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.5, green: 0.3, blue: 0.9),
                            Color(red: 0.4, green: 0.2, blue: 0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(Color.black.opacity(0.2))
                )
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.6, green: 0.4, blue: 1.0),
                        Color(red: 0.5, green: 0.3, blue: 0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Music Card
struct AddMusicCard: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background gradient - darker shade at bottom
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                VStack {
                    Spacer()
                    
                    // Plus icon where music note would be
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 60, weight: .heavy))
                            .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                    }
                    
                    Spacer()
                    
                    // Title at bottom with darker background
                    ZStack {
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .frame(height: 60)
                        
                        Text("ADD MUSIC")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.white)
                            .tracking(0.5)
                    }
                }
            }
            .frame(width: 208, height: 268)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                pressing: { pressing in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = pressing
                    }
                },
                perform: {})
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom File Browser
struct CustomFileBrowser: View {
    @Binding var selectedFiles: [URL]
    @Binding var isPresented: Bool
    let onFilesSelected: () -> Void
    
    @State private var currentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    @State private var files: [URL] = []
    @State private var selectedURLs: Set<URL> = []
    @State private var showingFolders = true
    
    var body: some View {
        ZStack {
            // Green background matching Radio
            Color(red: 0.4, green: 0.9, blue: 0.6).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("CANCEL")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("SELECT MUSIC")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        selectedFiles = Array(selectedURLs)
                        isPresented = false
                        onFilesSelected()
                    }) {
                        Text("ADD (\(selectedURLs.count))")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white)
                            .opacity(selectedURLs.isEmpty ? 0.5 : 1.0)
                    }
                    .disabled(selectedURLs.isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                // File list
                VStack(spacing: 0) {
                    // Path breadcrumb with navigation
                    HStack {
                        Button(action: {
                            // Navigate up one directory
                            currentPath = currentPath.deletingLastPathComponent()
                            loadFiles()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .heavy))
                                    .foregroundColor(.white)
                                
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                
                                Text(currentPath.lastPathComponent.isEmpty ? "Files" : currentPath.lastPathComponent)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                        }
                        .disabled(currentPath.path == "/")
                        
                        Spacer()
                        
                        // Toggle between folders and all files
                        Button(action: {
                            showingFolders.toggle()
                            loadFiles()
                        }) {
                            Text(showingFolders ? "SHOW ALL" : "FOLDERS")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            if files.isEmpty {
                                // Empty state
                                VStack(spacing: 16) {
                                    Image(systemName: "music.note.list")
                                        .font(.system(size: 48))
                                        .foregroundColor(Color.gray.opacity(0.3))
                                    
                                    Text("No audio files found")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color.gray.opacity(0.5))
                                    
                                    Text("Navigate to a folder with music files")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.gray.opacity(0.4))
                                }
                                .padding(.vertical, 60)
                                .frame(maxWidth: .infinity)
                            } else {
                                ForEach(files, id: \.self) { fileURL in
                                    if fileURL.hasDirectoryPath {
                                        // Folder row
                                        FolderRow(
                                            folderURL: fileURL,
                                            onTap: {
                                                currentPath = fileURL
                                                loadFiles()
                                            }
                                        )
                                    } else {
                                        // File row
                                        FileRow(
                                            fileName: fileURL.lastPathComponent,
                                            isSelected: selectedURLs.contains(fileURL),
                                            onTap: {
                                                if selectedURLs.contains(fileURL) {
                                                    selectedURLs.remove(fileURL)
                                                } else {
                                                    selectedURLs.insert(fileURL)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .background(Color.white.opacity(0.05))
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            loadFiles()
        }
    }
    
    func loadFiles() {
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: currentPath, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            
            if showingFolders {
                // Show folders and audio files
                files = contents.filter { url in
                    if let isDirectory = try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory {
                        return isDirectory || isAudioFile(url)
                    }
                    return false
                }.sorted { url1, url2 in
                    // Sort folders first, then files
                    let isDir1 = (try? url1.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    let isDir2 = (try? url2.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    
                    if isDir1 != isDir2 {
                        return isDir1
                    }
                    return url1.lastPathComponent < url2.lastPathComponent
                }
            } else {
                // Show only audio files
                files = contents.filter { isAudioFile($0) }.sorted { $0.lastPathComponent < $1.lastPathComponent }
            }
        } catch {
            print("Error loading files: \(error)")
            files = []
        }
    }
    
    func isAudioFile(_ url: URL) -> Bool {
        let audioExtensions = ["mp3", "m4a", "wav", "aiff", "aac", "flac", "alac", "opus", "ogg"]
        return audioExtensions.contains(url.pathExtension.lowercased())
    }
}

// MARK: - Folder Row
struct FolderRow: View {
    let folderURL: URL
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                
                Text(folderURL.lastPathComponent)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.gray.opacity(0.5))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
        
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(height: 1)
            .padding(.leading, 60)
    }
}

// MARK: - File Row
struct FileRow: View {
    let fileName: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: "music.note")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                
                Text(fileName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(isSelected ? Color.gray.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(height: 1)
            .padding(.leading, 60)
    }
}

#Preview {
    RadioView(taskStore: TaskStore(), currentTab: .constant("radio"))
}