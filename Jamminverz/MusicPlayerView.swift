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
    private var nextAudioPlayer: AVAudioPlayer? // Pre-buffer next song
    private var audioDataCache: [String: Data] = [:] // Cache audio data
    var availableSongs: [StationSong] = []
    private var timer: Timer?
    
    // Favorite songs
    @Published var favoriteSongs: Set<String> = []
    
    override private init() {
        super.init()
        setupAudioSession()
        loadFavorites()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private var playedSongIndices: Set<Int> = []
    
    func loadStation(_ station: MusicStation) {
        currentStation = station
        playedSongIndices.removeAll() // Reset played songs
        
        // For World Radio, use all songs directly since they're local files
        if station.id == "lofi" {
            availableSongs = station.songs
            print("World Radio: Loaded \(availableSongs.count) songs")
        } else {
            // For other stations, check downloaded songs
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
        }
        
        // Start playing a random song immediately
        if !availableSongs.isEmpty {
            // Set playing state immediately for smooth UI
            isPlaying = true
            
            // Pick a random song
            currentSongIndex = Int.random(in: 0..<availableSongs.count)
            playedSongIndices.insert(currentSongIndex)
            
            print("Starting playback with song: \(availableSongs[currentSongIndex].filename)")
            playCurrentSong()
        } else {
            print("No songs available to play!")
        }
    }
    
    func playCurrentSong() {
        guard currentSongIndex < availableSongs.count else { return }
        
        let song = availableSongs[currentSongIndex]
        currentSong = song
        
        // Keep isPlaying true for smooth UI during transitions
        isPlaying = true
        
        // Handle different URL types for World Radio
        if currentStation?.id == "lofi" {
            if song.url.hasPrefix("file://") {
                // Local file URL
                playLocalFile(song.url)
            } else if song.url.hasPrefix("https://") {
                // Stream from URL
                streamFromURL(song.url)
            }
        } else {
            // Handle downloaded files for other stations
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let songURL = documentsPath
                .appendingPathComponent("Music")
                .appendingPathComponent(currentStation?.name.replacingOccurrences(of: " ", with: "_") ?? "")
                .appendingPathComponent(song.filename)
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: songURL)
                audioPlayer?.delegate = self
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                isPlaying = true
                startTimer()
            } catch {
                print("Error playing audio: \(error)")
                print("Failed URL: \(songURL)")
                // Try next song
                nextSong()
            }
        }
    }
    
    private func streamFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            nextSong()
            return
        }
        
        // Check cache first
        if let cachedData = audioDataCache[urlString] {
            print("Playing from cache: \(urlString)")
            playAudioData(cachedData)
            preloadNextSong() // Pre-buffer next song
            return
        }
        
        print("Streaming from: \(url)")
        
        // Use URLSession with aggressive settings
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = URLCache(memoryCapacity: 500_000_000, diskCapacity: 1_000_000_000, diskPath: nil)
        let session = URLSession(configuration: configuration)
        
        session.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Failed to stream: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self?.nextSong()
                }
                return
            }
            
            // Cache the data
            self?.audioDataCache[urlString] = data
            
            DispatchQueue.main.async {
                self?.playAudioData(data)
                self?.preloadNextSong() // Pre-buffer next song
            }
        }.resume()
    }
    
    private func playAudioData(_ data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            startTimer()
        } catch {
            print("Error playing audio data: \(error)")
            nextSong()
        }
    }
    
    private func playLocalFile(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid local URL: \(urlString)")
            nextSong()
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            startTimer()
            preloadNextSong() // Pre-buffer next song
        } catch {
            print("Error playing local file: \(error)")
            nextSong()
        }
    }
    
    private func preloadNextSong() {
        // Pre-buffer the next song
        guard !availableSongs.isEmpty else { return }
        
        // Find next unplayed song
        var nextIndex = currentSongIndex
        for _ in 0..<availableSongs.count {
            nextIndex = (nextIndex + 1) % availableSongs.count
            if !playedSongIndices.contains(nextIndex) {
                break
            }
        }
        
        let nextSong = availableSongs[nextIndex]
        if nextSong.url.hasPrefix("https://") {
            // Pre-download next song
            guard let url = URL(string: nextSong.url) else { return }
            
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data {
                    self?.audioDataCache[nextSong.url] = data
                    // Pre-create the audio player
                    DispatchQueue.main.async {
                        do {
                            self?.nextAudioPlayer = try AVAudioPlayer(data: data)
                            self?.nextAudioPlayer?.prepareToPlay()
                        } catch {
                            print("Error pre-buffering: \(error)")
                        }
                    }
                }
            }.resume()
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
        // Stop current playback immediately but keep isPlaying true for UI
        audioPlayer?.stop()
        stopTimer()
        
        // True random: pick from unplayed songs
        if playedSongIndices.count >= availableSongs.count {
            // All songs played, reset
            playedSongIndices.removeAll()
        }
        
        // Find unplayed songs
        var unplayedIndices: [Int] = []
        for i in 0..<availableSongs.count {
            if !playedSongIndices.contains(i) {
                unplayedIndices.append(i)
            }
        }
        
        if !unplayedIndices.isEmpty {
            // Pick random from unplayed
            currentSongIndex = unplayedIndices.randomElement()!
            playedSongIndices.insert(currentSongIndex)
        } else {
            // Fallback: pick any random song
            currentSongIndex = Int.random(in: 0..<availableSongs.count)
            playedSongIndices.insert(currentSongIndex)
        }
        
        playCurrentSong()
    }
    
    func previousSong() {
        if currentTime > 3 {
            // If more than 3 seconds in, restart current song
            audioPlayer?.currentTime = 0
            audioPlayer?.play()
        } else {
            // For previous, just go to a random song
            nextSong()
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
    
    // MARK: - Favorite Management
    func toggleFavorite(_ song: StationSong) {
        if favoriteSongs.contains(song.filename) {
            favoriteSongs.remove(song.filename)
        } else {
            favoriteSongs.insert(song.filename)
        }
        // Save to UserDefaults
        UserDefaults.standard.set(Array(favoriteSongs), forKey: "favoriteSongs")
    }
    
    func isCurrentSongFavorite() -> Bool {
        guard let currentSong = currentSong else { return false }
        return favoriteSongs.contains(currentSong.filename)
    }
    
    func loadFavorites() {
        if let saved = UserDefaults.standard.array(forKey: "favoriteSongs") as? [String] {
            favoriteSongs = Set(saved)
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
            // Background - ensure it's not white
            Color.black.ignoresSafeArea()
            
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
                            Text(formatSongName(playerManager.currentSong?.filename ?? "No Song Playing"))
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
            print("MusicPlayerView appeared for station: \(station.name)")
            print("Station has \(station.songs.count) songs")
            playerManager.loadStation(station)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatSongName(_ filename: String) -> String {
        // Clean up the filename for display
        return filename
            .replacingOccurrences(of: ".mp3", with: "")
            .replacingOccurrences(of: ".m4a", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }
}