//
//  BeatsView.swift
//  Jamminverz
//
//  Community beat sharing platform
//

import SwiftUI
import AVFoundation

// MARK: - Beats View
struct BeatsView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @StateObject private var beatsManager = BeatsManager()
    @State private var selectedTab = 0
    @State private var showShareSheet = false
    @State private var showBeatDetail: Beat?
    
    private let tabs = ["🔥 Trending", "🆕 Latest", "👥 Following"]
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.4, blue: 0.2),
                    Color(red: 0.9, green: 0.3, blue: 0.2),
                    Color(red: 0.8, green: 0.2, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text("BEATS")
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: { showShareSheet = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Share Your Beat")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(25)
                        }
                    }
                    
                    // Tab selector
                    HStack(spacing: 0) {
                        ForEach(0..<tabs.count, id: \.self) { index in
                            Button(action: { selectedTab = index }) {
                                Text(tabs[index])
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(selectedTab == index ? .white : .white.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedTab == index ?
                                        Color.white.opacity(0.3) : Color.clear
                                    )
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
                
                // Beat feed
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(getBeatsForTab()) { beat in
                            BeatCard(beat: beat, beatsManager: beatsManager)
                                .onTapGesture {
                                    showBeatDetail = beat
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareBeatView(beatsManager: beatsManager)
        }
        .sheet(item: $showBeatDetail) { beat in
            BeatDetailView(beat: beat, beatsManager: beatsManager)
        }
    }
    
    private func getBeatsForTab() -> [Beat] {
        switch selectedTab {
        case 0: return beatsManager.trendingBeats
        case 1: return beatsManager.latestBeats
        case 2: return beatsManager.followingBeats
        default: return []
        }
    }
}

// MARK: - Beat Card
struct BeatCard: View {
    let beat: Beat
    @ObservedObject var beatsManager: BeatsManager
    @State private var isPlaying = false
    @State private var isLiked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Play button
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(beat.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text("by @\(beat.creator.username)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.6))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text(formatDuration(beat.duration))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.6))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "music.note")
                                .font(.system(size: 12))
                            Text("\(beat.bpm) BPM")
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .font(.system(size: 14))
                }
                
                Spacer()
                
                // Save button
                Button(action: { }) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                }
            }
            
            // Sample packs used
            if !beat.packsUsed.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("📦 Made with packs:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    ForEach(beat.packsUsed.prefix(2)) { pack in
                        HStack {
                            Text("• \(pack.name)")
                                .font(.system(size: 13))
                            Text("by @\(pack.creator.username)")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                    
                    if beat.packsUsed.count > 2 {
                        Text("+ \(beat.packsUsed.count - 2) more")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            // Interaction bar
            HStack(spacing: 20) {
                // Like
                Button(action: { toggleLike() }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                        Text("\(beat.hearts)")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isLiked ? .pink : .white)
                }
                
                // Comments
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                    Text("\(beat.comments.count)")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                
                // Shares
                Button(action: { }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.turn.up.right")
                        Text("\(beat.shares)")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                }
                
                Spacer()
                
                // Tags
                HStack(spacing: 8) {
                    ForEach(beat.tags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
    }
    
    private func togglePlayback() {
        if isPlaying {
            beatsManager.stopPlayback()
        } else {
            beatsManager.playBeat(beat)
        }
        isPlaying.toggle()
    }
    
    private func toggleLike() {
        isLiked.toggle()
        if isLiked {
            beatsManager.likeBeat(beat)
        } else {
            beatsManager.unlikeBeat(beat)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Share Beat View
struct ShareBeatView: View {
    @ObservedObject var beatsManager: BeatsManager
    @Environment(\.dismiss) var dismiss
    
    @State private var beatTitle = ""
    @State private var beatDescription = ""
    @State private var tags = ""
    @State private var selectedPacks: Set<String> = []
    @State private var visibility = "public"
    @State private var audioFileURL: URL?
    @State private var isRecording = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Audio file section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Beat File", systemImage: "music.note")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 16) {
                            Button(action: selectAudioFile) {
                                VStack {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.system(size: 32))
                                    Text("Upload File")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 100)
                                .foregroundColor(.white)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                            }
                            
                            Button(action: { isRecording.toggle() }) {
                                VStack {
                                    Image(systemName: isRecording ? "stop.circle" : "mic.circle")
                                        .font(.system(size: 32))
                                    Text(isRecording ? "Stop Recording" : "Record")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 100)
                                .foregroundColor(isRecording ? .red : .white)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                        
                        if let url = audioFileURL {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(url.lastPathComponent)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Beat info
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            TextField("Beat name", text: $beatTitle)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            TextEditor(text: $beatDescription)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            TextField("#trap #fire #sample", text: $tags)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Sample packs used
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sample Packs Used")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Auto-detected from your beat")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        
                        // Mock detected packs
                        ForEach(beatsManager.availablePacks) { pack in
                            HStack {
                                Image(systemName: selectedPacks.contains(pack.id) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(.white)
                                
                                Text(pack.name)
                                    .foregroundColor(.white)
                                
                                Text("by @\(pack.creator.username)")
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Spacer()
                            }
                            .onTapGesture {
                                if selectedPacks.contains(pack.id) {
                                    selectedPacks.remove(pack.id)
                                } else {
                                    selectedPacks.insert(pack.id)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Button(action: { }) {
                            Label("Add More Packs", systemImage: "plus")
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Visibility
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Visibility")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        ForEach(["public", "private"], id: \.self) { option in
                            HStack {
                                Image(systemName: visibility == option ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(.white)
                                
                                Text(option.capitalized)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .onTapGesture {
                                visibility = option
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.4, blue: 0.2),
                        Color(red: 0.8, green: 0.2, blue: 0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Share Your Beat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        shareBeat()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .disabled(beatTitle.isEmpty || audioFileURL == nil)
                }
            }
        }
        .accentColor(.white)
    }
    
    private func selectAudioFile() {
        // TODO: Implement file picker
    }
    
    private func shareBeat() {
        beatsManager.shareBeat(
            title: beatTitle,
            description: beatDescription,
            tags: tags.components(separatedBy: " ").compactMap { tag in
                tag.hasPrefix("#") ? String(tag.dropFirst()) : nil
            },
            audioURL: audioFileURL!,
            packsUsed: Array(selectedPacks)
        )
        dismiss()
    }
}

// MARK: - Beat Detail View
struct BeatDetailView: View {
    let beat: Beat
    @ObservedObject var beatsManager: BeatsManager
    @Environment(\.dismiss) var dismiss
    @State private var newComment = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Beat info
                    BeatCard(beat: beat, beatsManager: beatsManager)
                    
                    // Comments section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Comments")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Comment input
                        HStack {
                            TextField("Add a comment...", text: $newComment)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                            
                            Button(action: postComment) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.3))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Comments list
                        ForEach(beat.comments) { comment in
                            CommentRow(comment: comment)
                        }
                    }
                    .padding()
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.4, blue: 0.2),
                        Color(red: 0.8, green: 0.2, blue: 0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle(beat.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func postComment() {
        guard !newComment.isEmpty else { return }
        beatsManager.addComment(to: beat, text: newComment)
        newComment = ""
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.purple)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(comment.user.username.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("@\(comment.user.username)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("• \(comment.timestamp.formatted(.relative(presentation: .named)))")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text(comment.text)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}