//
//  MusicPlayerView.swift
//  Todomai-iOS
//
//  Music player interface for radio stations
//

import SwiftUI
import AVFoundation

// MARK: - Music Player Manager
class MusicPlayerManager: NSObject, ObservableObject {
    static let shared = MusicPlayerManager()
    
    @Published var isPlaying = false
    @Published var currentSong: StationSong?
    @Published var currentStation: MusicStation?
    @Published var currentSongIndex = 0
    @Published var playbackProgress: Double = 0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private var audioPlayer: AVAudioPlayer?
    var availableSongs: [StationSong] = []
    private var timer: Timer?
    
    override private init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func loadStation(_ station: MusicStation) {
        currentStation = station
        
        // Get all downloaded songs for this station
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let stationPath = documentsPath
            .appendingPathComponent("Music")
            .appendingPathComponent(station.name.replacingOccurrences(of: " ", with: "_"))
        
        availableSongs = []
        
        // Find which songs are actually downloaded
        for song in station.songs {
            let songPath = stationPath.appendingPathComponent(song.filename)
            if FileManager.default.fileExists(atPath: songPath.path) {
                availableSongs.append(song)
            }
        }
        
        // Shuffle the songs
        availableSongs.shuffle()
        
        // Start playing the first song
        if !availableSongs.isEmpty {
            currentSongIndex = 0
            playCurrentSong()
        }
    }
    
    func playCurrentSong() {
        guard currentSongIndex < availableSongs.count else { return }
        
        let song = availableSongs[currentSongIndex]
        currentSong = song
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let songPath = documentsPath
            .appendingPathComponent("Music")
            .appendingPathComponent(currentStation?.name.replacingOccurrences(of: " ", with: "_") ?? "")
            .appendingPathComponent(song.filename)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: songPath)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            startTimer()
        } catch {
            print("Error playing audio: \(error)")
            // Try next song
            nextSong()
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func play() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func nextSong() {
        currentSongIndex = (currentSongIndex + 1) % availableSongs.count
        playCurrentSong()
    }
    
    func previousSong() {
        if currentTime > 3 {
            // If more than 3 seconds in, restart current song
            audioPlayer?.currentTime = 0
            audioPlayer?.play()
        } else {
            // Otherwise go to previous song
            currentSongIndex = currentSongIndex > 0 ? currentSongIndex - 1 : availableSongs.count - 1
            playCurrentSong()
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        currentSong = nil
        currentStation = nil
        stopTimer()
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateProgress()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateProgress() {
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime
        duration = player.duration
        if duration > 0 {
            playbackProgress = currentTime / duration
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension MusicPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            nextSong()
        }
    }
}

// MARK: - Music Player View
struct MusicPlayerView: View {
    let station: MusicStation
    @StateObject private var playerManager = MusicPlayerManager.shared
    @ObservedObject var downloadManager: StationDownloadManager
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            station.color.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        playerManager.stop()
                        onClose()
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
                    
                    Text(station.name)
                        .font(.system(size: 16, weight: .heavy))
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
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                // Main content
                ScrollView {
                    VStack(spacing: 32) {
                        // Album art placeholder
                        ZStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 280, height: 280)
                            
                            Image(systemName: "music.note")
                                .font(.system(size: 120, weight: .heavy))
                                .foregroundColor(.white)
                        }
                        .overlay(
                            Rectangle()
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .padding(.top, 40)
                        
                        // Song info
                        VStack(spacing: 8) {
                            Text(playerManager.currentSong?.filename.replacingOccurrences(of: ".m4a", with: "") ?? "No Song Playing")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("\(playerManager.currentSongIndex + 1) of \(playerManager.availableSongs.count) songs")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 40)
                        
                        // Progress bar
                        VStack(spacing: 8) {
                            ProgressView(value: playerManager.playbackProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .tint(.white)
                                .background(Color.white.opacity(0.2))
                                .scaleEffect(x: 1, y: 3, anchor: .center)
                            
                            HStack {
                                Text(formatTime(playerManager.currentTime))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Spacer()
                                
                                Text(formatTime(playerManager.duration))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 40)
                        
                        // Playback controls
                        HStack(spacing: 32) {
                            // Previous
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                playerManager.previousSong()
                            }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            // Play/Pause
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                playerManager.togglePlayPause()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 36, weight: .heavy))
                                        .foregroundColor(station.color)
                                        .offset(x: playerManager.isPlaying ? 0 : 3) // Center play icon
                                }
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 4)
                                )
                            }
                            
                            // Next
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                playerManager.nextSong()
                            }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            playerManager.loadStation(station)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}