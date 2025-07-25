//
//  FavoriteSongsView.swift
//  Jamminverz
//
//  View to display favorite songs
//

import SwiftUI

struct FavoriteSongsView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @StateObject private var playerManager = MusicPlayerManager.shared
    @StateObject private var downloadManager = StationDownloadManager.shared
    @State private var showingPlayer = false
    
    var favoriteSongs: [StationSong] {
        // Filter available songs to only show favorites
        playerManager.availableSongs.filter { song in
            playerManager.favoriteSongs.contains(song.filename)
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
                    
                    Text("MY FAVORITE SONGS")
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
                
                if favoriteSongs.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "heart.slash")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("No favorite songs yet")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Tap the heart button while playing to add favorites")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Spacer()
                    }
                } else {
                    // Song list
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(favoriteSongs.enumerated()), id: \.element.filename) { index, song in
                                FavoriteSongRow(
                                    song: song,
                                    index: index,
                                    onTap: {
                                        // Play this song
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
    
    private func playSong(_ song: StationSong) {
        // Create a temporary station with just favorite songs
        let favoritesStation = MusicStation(
            id: "favorites",
            name: "My Favorites",
            songCount: favoriteSongs.count,
            totalSizeMB: 0,
            color: Color(red: 1.0, green: 0.4, blue: 0.4),
            isAvailable: true,
            songs: favoriteSongs
        )
        
        // Load the station and find the song index
        playerManager.loadStation(favoritesStation)
        if let songIndex = favoriteSongs.firstIndex(where: { $0.filename == song.filename }) {
            playerManager.currentSongIndex = songIndex
            playerManager.playCurrentSong()
        }
        
        showingPlayer = true
    }
}

struct FavoriteSongRow: View {
    let song: StationSong
    let index: Int
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
                
                // Heart button (always filled for favorites)
                Button(action: onToggleFavorite) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
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
    FavoriteSongsView(taskStore: TaskStore(), currentTab: .constant("favorites"))
}