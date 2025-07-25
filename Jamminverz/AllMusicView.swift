//
//  AllMusicView.swift
//  Jamminverz
//
//  View to display all available songs
//

import SwiftUI

struct AllMusicView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @StateObject private var playerManager = MusicPlayerManager.shared
    @StateObject private var downloadManager = StationDownloadManager.shared
    @State private var showingPlayer = false
    @State private var searchText = ""
    
    var filteredSongs: [StationSong] {
        if searchText.isEmpty {
            return playerManager.availableSongs
        } else {
            return playerManager.availableSongs.filter { song in
                formatSongName(song.filename).localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Dark background
            Color(red: 0.05, green: 0.05, blue: 0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        currentTab = "mymusic"
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .heavy))
                            Text("BACK")
                                .font(.system(size: 16, weight: .heavy))
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("MY MUSIC")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Balance spacer
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .heavy))
                        Text("BACK")
                            .font(.system(size: 16, weight: .heavy))
                    }
                    .foregroundColor(.clear)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 30)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    TextField("Search songs...", text: $searchText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .accentColor(Color(red: 0.8, green: 0.6, blue: 1.0))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                
                // Song count
                HStack {
                    Text("\(filteredSongs.count) songs")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Button(action: {
                        playAllSongs()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("PLAY ALL")
                                .font(.system(size: 14, weight: .heavy))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.8, green: 0.6, blue: 1.0))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
                
                if filteredSongs.isEmpty && !searchText.isEmpty {
                    // No search results
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("No songs found")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                    }
                } else {
                    // Song list
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(filteredSongs.enumerated()), id: \.element.filename) { index, song in
                                AllMusicSongRow(
                                    song: song,
                                    index: index,
                                    isFavorite: playerManager.favoriteSongs.contains(song.filename),
                                    onTap: {
                                        playSong(song)
                                    },
                                    onToggleFavorite: {
                                        playerManager.toggleFavorite(song)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingPlayer) {
            if let station = playerManager.currentStation {
                MusicPlayerView(
                    station: station,
                    downloadManager: downloadManager
                ) {
                    showingPlayer = false
                }
            }
        }
    }
    
    private func playAllSongs() {
        // Create a station with all songs
        let allMusicStation = MusicStation(
            id: "allmusic",
            name: "All Music",
            songCount: filteredSongs.count,
            totalSizeMB: 0,
            color: Color(red: 0.8, green: 0.6, blue: 1.0),
            isAvailable: true,
            songs: filteredSongs
        )
        
        playerManager.loadStation(allMusicStation)
        showingPlayer = true
    }
    
    private func playSong(_ song: StationSong) {
        // Create a station with all songs but start at the selected song
        let allMusicStation = MusicStation(
            id: "allmusic",
            name: "All Music",
            songCount: filteredSongs.count,
            totalSizeMB: 0,
            color: Color(red: 0.8, green: 0.6, blue: 1.0),
            isAvailable: true,
            songs: filteredSongs
        )
        
        playerManager.loadStation(allMusicStation)
        if let songIndex = filteredSongs.firstIndex(where: { $0.filename == song.filename }) {
            playerManager.currentSongIndex = songIndex
            playerManager.playCurrentSong()
        }
        
        showingPlayer = true
    }
    
    private func formatSongName(_ filename: String) -> String {
        return filename
            .replacingOccurrences(of: ".mp3", with: "")
            .replacingOccurrences(of: ".m4a", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }
}

struct AllMusicSongRow: View {
    let song: StationSong
    let index: Int
    let isFavorite: Bool
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Index number
                Text("\(index + 1)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 30, alignment: .trailing)
                
                // Song name
                Text(formatSongName(song.filename))
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                // Heart button
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isFavorite ? Color(red: 1.0, green: 0.4, blue: 0.4) : .white.opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Color.white.opacity(isHovering ? 0.15 : 0.05)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
    
    private func formatSongName(_ filename: String) -> String {
        return filename
            .replacingOccurrences(of: ".mp3", with: "")
            .replacingOccurrences(of: ".m4a", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }
}

#Preview {
    AllMusicView(taskStore: TaskStore(), currentTab: .constant("allmusicview"))
}