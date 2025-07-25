//
//  MyMusicView.swift
//  Jamminverz
//
//  My Music section with favorites
//

import SwiftUI

struct MyMusicView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @StateObject private var playerManager = MusicPlayerManager.shared
    
    var body: some View {
        ZStack {
            // Dark background
            Color(red: 0.05, green: 0.05, blue: 0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        currentTab = "menu"
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
                
                // Subtitle
                Text("Your personal music collection")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 40)
                
                // Music sections grid
                HStack(spacing: 30) {
                    // My Music card
                    MusicSectionCard(
                        title: "MY MUSIC",
                        subtitle: "\(playerManager.availableSongs.count) songs",
                        color: Color(red: 0.8, green: 0.6, blue: 1.0), // Light purple
                        icon: "music.note",
                        action: {
                            // Go to full music library
                            currentTab = "allmusicview"
                        }
                    )
                    
                    // My Favorite Songs card
                    MusicSectionCard(
                        title: "MY FAVORITE SONGS",
                        subtitle: "\(playerManager.favoriteSongs.count) songs",
                        color: Color(red: 1.0, green: 0.4, blue: 0.4), // Light red
                        icon: "heart.fill",
                        action: {
                            // Go to favorites view
                            currentTab = "favorites"
                        }
                    )
                }
                .padding(.horizontal, 50)
                
                Spacer()
            }
        }
    }
}

struct MusicSectionCard: View {
    let title: String
    let subtitle: String
    let color: Color
    let icon: String
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            VStack {
                // Icon area
                ZStack {
                    Rectangle()
                        .fill(color.opacity(isHovering ? 0.9 : 0.8))
                        .frame(height: 200)
                    
                    Image(systemName: icon)
                        .font(.system(size: 80, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Title area
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.3))
            }
            .frame(width: 250, height: 280)
            .background(color.opacity(0.1))
            .overlay(
                Rectangle()
                    .stroke(color, lineWidth: isHovering ? 3 : 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    MyMusicView(taskStore: TaskStore(), currentTab: .constant("mymusic"))
}