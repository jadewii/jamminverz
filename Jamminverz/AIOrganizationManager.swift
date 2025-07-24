//
//  AIOrganizationManager.swift
//  Jamminverz
//
//  AI-powered music organization and classification system
//

import Foundation
import AVFoundation
import SwiftUI

// MARK: - Music Analysis Results
struct MusicAnalysisResult {
    let confidence: Double
    let primaryGenre: String
    let subGenres: [String]
    let bpm: Int?
    let key: String?
    let mood: String?
    let energy: Double? // 0.0 to 1.0
    let danceability: Double? // 0.0 to 1.0
    let instrumentalness: Double? // 0.0 to 1.0
    let metadata: [String: Any]
}

// MARK: - Audio Classification Categories
enum AudioCategory: String, CaseIterable {
    // Sample categories
    case drumKick = "Drums/Kick"
    case drumSnare = "Drums/Snare"
    case drumHiHat = "Drums/Hi-Hat"
    case drumPerc = "Drums/Percussion"
    case bassElectronic = "Bass/Electronic"
    case bassAcoustic = "Bass/Acoustic"
    case melodySynth = "Melody/Synth"
    case melodyPiano = "Melody/Piano"
    case melodyGuitar = "Melody/Guitar"
    case fxAtmosphere = "FX/Atmosphere"
    case fxTransition = "FX/Transition"
    case vocalsLead = "Vocals/Lead"
    case vocalsChop = "Vocals/Chop"
    
    // Genre categories
    case lofi = "Lofi"
    case trap = "Trap"
    case house = "House"
    case techno = "Techno"
    case dubstep = "Dubstep"
    case jazz = "Jazz"
    case rock = "Rock"
    case pop = "Pop"
    case rnb = "R&B"
    case hiphop = "Hip-Hop"
    case electronic = "Electronic"
    case ambient = "Ambient"
    
    var color: Color {
        switch self {
        case .drumKick, .drumSnare, .drumHiHat, .drumPerc:
            return Color.red.opacity(0.8)
        case .bassElectronic, .bassAcoustic:
            return Color.blue.opacity(0.8)
        case .melodySynth, .melodyPiano, .melodyGuitar:
            return Color.green.opacity(0.8)
        case .fxAtmosphere, .fxTransition:
            return Color.purple.opacity(0.8)
        case .vocalsLead, .vocalsChop:
            return Color.orange.opacity(0.8)
        default:
            return Color.gray.opacity(0.8)
        }
    }
}

// MARK: - AI Organization Manager
class AIOrganizationManager: ObservableObject {
    static let shared = AIOrganizationManager()
    
    @Published var analysisProgress: Double = 0.0
    @Published var isAnalyzing = false
    @Published var analysisResults: [URL: MusicAnalysisResult] = [:]
    
    private init() {}
    
    // MARK: - Main analysis function for different modes
    func analyzeContent(urls: [URL], mode: OrganizationMode, completion: @escaping ([URL: MusicAnalysisResult]) -> Void) {
        isAnalyzing = true
        analysisProgress = 0.0
        
        var results: [URL: MusicAnalysisResult] = [:]
        let totalFiles = urls.count
        
        DispatchQueue.global(qos: .userInitiated).async {
            for (index, url) in urls.enumerated() {
                let result = self.analyzeFile(url: url, mode: mode)
                results[url] = result
                
                DispatchQueue.main.async {
                    self.analysisProgress = Double(index + 1) / Double(totalFiles)
                }
                
                // Simulate processing time
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            DispatchQueue.main.async {
                self.isAnalyzing = false
                self.analysisResults = results
                completion(results)
            }
        }
    }
    
    // MARK: - File Analysis by Mode
    private func analyzeFile(url: URL, mode: OrganizationMode) -> MusicAnalysisResult {
        switch mode {
        case .samples:
            return analyzeSample(url: url)
        case .albums:
            return analyzeAlbum(url: url)
        case .tracks:
            return analyzeTrack(url: url)
        case .playlists:
            return analyzePlaylist(url: url)
        }
    }
    
    // MARK: - Sample Analysis
    private func analyzeSample(url: URL) -> MusicAnalysisResult {
        let filename = url.lastPathComponent.lowercased()
        let fileExtension = url.pathExtension.lowercased()
        
        // BPM detection (simulated)
        let bpm = detectBPM(from: url)
        
        // Loop detection
        let isLoop = detectLoop(from: url)
        
        // Instrument detection based on filename and audio analysis
        var primaryGenre = "Unknown"
        var confidence = 0.5
        
        if filename.contains("kick") || filename.contains("bd") {
            primaryGenre = AudioCategory.drumKick.rawValue
            confidence = 0.9
        } else if filename.contains("snare") || filename.contains("sd") {
            primaryGenre = AudioCategory.drumSnare.rawValue
            confidence = 0.9
        } else if filename.contains("hihat") || filename.contains("hh") {
            primaryGenre = AudioCategory.drumHiHat.rawValue
            confidence = 0.85
        } else if filename.contains("bass") || filename.contains("sub") {
            primaryGenre = AudioCategory.bassElectronic.rawValue
            confidence = 0.8
        } else if filename.contains("lead") || filename.contains("melody") {
            primaryGenre = AudioCategory.melodySynth.rawValue
            confidence = 0.75
        } else if filename.contains("vocal") || filename.contains("vox") {
            primaryGenre = AudioCategory.vocalsLead.rawValue
            confidence = 0.8
        } else if filename.contains("fx") || filename.contains("effect") {
            primaryGenre = AudioCategory.fxAtmosphere.rawValue
            confidence = 0.7
        }
        
        // Genre classification based on BPM and filename
        var subGenres: [String] = []
        if let bpm = bpm {
            if bpm < 90 && (filename.contains("lofi") || filename.contains("chill")) {
                subGenres.append(AudioCategory.lofi.rawValue)
            } else if bpm > 120 && bpm < 140 && filename.contains("trap") {
                subGenres.append(AudioCategory.trap.rawValue)
            } else if bpm > 120 && filename.contains("house") {
                subGenres.append(AudioCategory.house.rawValue)
            }
        }
        
        return MusicAnalysisResult(
            confidence: confidence,
            primaryGenre: primaryGenre,
            subGenres: subGenres,
            bpm: bpm,
            key: detectKey(from: url),
            mood: nil,
            energy: nil,
            danceability: nil,
            instrumentalness: nil,
            metadata: [
                "isLoop": isLoop,
                "fileType": fileExtension,
                "filename": filename
            ]
        )
    }
    
    // MARK: - Album Analysis
    private func analyzeAlbum(url: URL) -> MusicAnalysisResult {
        // For album folders, analyze contained tracks
        let filename = url.lastPathComponent
        
        // Extract year from folder name
        let year = extractYear(from: filename)
        
        // Analyze tracks in album for dominant genre
        let dominantGenre = classifyAlbumGenre(from: url)
        
        // Artist name normalization
        let artist = normalizeArtistName(from: filename)
        
        return MusicAnalysisResult(
            confidence: 0.8,
            primaryGenre: dominantGenre,
            subGenres: [],
            bpm: nil,
            key: nil,
            mood: nil,
            energy: nil,
            danceability: nil,
            instrumentalness: nil,
            metadata: [
                "year": year as Any,
                "artist": artist,
                "albumName": filename,
                "trackCount": getTrackCount(from: url)
            ]
        )
    }
    
    // MARK: - Track Analysis
    private func analyzeTrack(url: URL) -> MusicAnalysisResult {
        let filename = url.lastPathComponent
        
        // Comprehensive track analysis
        let genre = classifyGenre(from: url)
        let mood = analyzeMood(from: url)
        let bpm = detectBPM(from: url)
        let key = detectKey(from: url)
        let energy = calculateEnergy(from: url)
        let danceability = calculateDanceability(from: url)
        
        return MusicAnalysisResult(
            confidence: 0.85,
            primaryGenre: genre,
            subGenres: [],
            bpm: bpm,
            key: key,
            mood: mood,
            energy: energy,
            danceability: danceability,
            instrumentalness: calculateInstrumentalness(from: url),
            metadata: [
                "title": extractTitle(from: filename),
                "artist": extractArtist(from: filename),
                "duration": getDuration(from: url),
                "bitrate": getBitrate(from: url)
            ]
        )
    }
    
    // MARK: - Playlist Analysis
    private func analyzePlaylist(url: URL) -> MusicAnalysisResult {
        let filename = url.lastPathComponent
        
        // Detect playlist theme
        var theme = "Mixed"
        var confidence = 0.6
        
        if filename.lowercased().contains("workout") || filename.lowercased().contains("gym") {
            theme = "Workout"
            confidence = 0.9
        } else if filename.lowercased().contains("chill") || filename.lowercased().contains("relax") {
            theme = "Chill"
            confidence = 0.9
        } else if filename.lowercased().contains("party") || filename.lowercased().contains("dance") {
            theme = "Party"
            confidence = 0.9
        } else if filename.lowercased().contains("study") || filename.lowercased().contains("focus") {
            theme = "Study"
            confidence = 0.9
        }
        
        return MusicAnalysisResult(
            confidence: confidence,
            primaryGenre: theme,
            subGenres: [],
            bpm: nil,
            key: nil,
            mood: theme.lowercased(),
            energy: nil,
            danceability: nil,
            instrumentalness: nil,
            metadata: [
                "playlistName": filename,
                "songCount": getPlaylistSongCount(from: url),
                "theme": theme
            ]
        )
    }
    
    // MARK: - Audio Analysis Helper Functions
    private func detectBPM(from url: URL) -> Int? {
        // Simulated BPM detection - in real implementation would use audio analysis
        let filename = url.lastPathComponent.lowercased()
        
        if filename.contains("120") { return 120 }
        if filename.contains("130") { return 130 }
        if filename.contains("140") { return 140 }
        if filename.contains("trap") { return Int.random(in: 130...150) }
        if filename.contains("house") { return Int.random(in: 120...130) }
        if filename.contains("lofi") { return Int.random(in: 70...90) }
        if filename.contains("techno") { return Int.random(in: 125...135) }
        
        return Int.random(in: 80...140)
    }
    
    private func detectLoop(from url: URL) -> Bool {
        let filename = url.lastPathComponent.lowercased()
        return filename.contains("loop") || filename.contains("_lp") || 
               filename.contains("cycle") || url.pathExtension.lowercased() == "loop"
    }
    
    private func detectKey(from url: URL) -> String? {
        // Simulated key detection
        let keys = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let modes = ["maj", "min"]
        
        return "\(keys.randomElement()!) \(modes.randomElement()!)"
    }
    
    private func classifyGenre(from url: URL) -> String {
        let filename = url.lastPathComponent.lowercased()
        
        if filename.contains("trap") { return AudioCategory.trap.rawValue }
        if filename.contains("house") { return AudioCategory.house.rawValue }
        if filename.contains("lofi") { return AudioCategory.lofi.rawValue }
        if filename.contains("jazz") { return AudioCategory.jazz.rawValue }
        if filename.contains("rock") { return AudioCategory.rock.rawValue }
        if filename.contains("pop") { return AudioCategory.pop.rawValue }
        if filename.contains("rnb") || filename.contains("r&b") { return AudioCategory.rnb.rawValue }
        if filename.contains("hiphop") || filename.contains("hip-hop") { return AudioCategory.hiphop.rawValue }
        if filename.contains("electronic") { return AudioCategory.electronic.rawValue }
        if filename.contains("techno") { return AudioCategory.techno.rawValue }
        
        return AudioCategory.electronic.rawValue
    }
    
    private func analyzeMood(from url: URL) -> String {
        let filename = url.lastPathComponent.lowercased()
        
        if filename.contains("energetic") || filename.contains("pump") { return "energetic" }
        if filename.contains("chill") || filename.contains("relax") { return "chill" }
        if filename.contains("aggressive") || filename.contains("hard") { return "aggressive" }
        if filename.contains("sad") || filename.contains("melancholy") { return "melancholy" }
        if filename.contains("happy") || filename.contains("upbeat") { return "happy" }
        
        return "neutral"
    }
    
    private func calculateEnergy(from url: URL) -> Double {
        // Simulated energy calculation (0.0 to 1.0)
        let mood = analyzeMood(from: url)
        switch mood {
        case "energetic": return Double.random(in: 0.8...1.0)
        case "aggressive": return Double.random(in: 0.7...0.9)
        case "happy": return Double.random(in: 0.6...0.8)
        case "chill": return Double.random(in: 0.2...0.4)
        case "melancholy": return Double.random(in: 0.1...0.3)
        default: return Double.random(in: 0.4...0.6)
        }
    }
    
    private func calculateDanceability(from url: URL) -> Double {
        let genre = classifyGenre(from: url)
        
        switch genre {
        case AudioCategory.house.rawValue, AudioCategory.techno.rawValue:
            return Double.random(in: 0.8...1.0)
        case AudioCategory.trap.rawValue, AudioCategory.hiphop.rawValue:
            return Double.random(in: 0.7...0.9)
        case AudioCategory.pop.rawValue, AudioCategory.rnb.rawValue:
            return Double.random(in: 0.6...0.8)
        case AudioCategory.lofi.rawValue, AudioCategory.ambient.rawValue:
            return Double.random(in: 0.1...0.3)
        default:
            return Double.random(in: 0.4...0.6)
        }
    }
    
    private func calculateInstrumentalness(from url: URL) -> Double {
        let filename = url.lastPathComponent.lowercased()
        
        if filename.contains("instrumental") || filename.contains("inst") {
            return Double.random(in: 0.8...1.0)
        } else if filename.contains("vocal") || filename.contains("feat") {
            return Double.random(in: 0.0...0.3)
        }
        
        return Double.random(in: 0.3...0.7)
    }
    
    // MARK: - Metadata Extraction Helpers
    private func extractYear(from filename: String) -> Int? {
        let regex = try! NSRegularExpression(pattern: "\\b(19|20)\\d{2}\\b")
        let range = NSRange(location: 0, length: filename.count)
        
        if let match = regex.firstMatch(in: filename, range: range) {
            let yearString = (filename as NSString).substring(with: match.range)
            return Int(yearString)
        }
        
        return nil
    }
    
    private func normalizeArtistName(from filename: String) -> String {
        // Extract artist name from filename
        let components = filename.components(separatedBy: " - ")
        if components.count > 1 {
            return components[0].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try other separators
        let altComponents = filename.components(separatedBy: "_")
        if altComponents.count > 1 {
            return altComponents[0].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return "Unknown Artist"
    }
    
    private func extractTitle(from filename: String) -> String {
        let components = filename.components(separatedBy: " - ")
        if components.count > 1 {
            let titleWithExt = components[1]
            return URL(fileURLWithPath: titleWithExt).deletingPathExtension().lastPathComponent
        }
        
        return URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
    }
    
    private func extractArtist(from filename: String) -> String {
        return normalizeArtistName(from: filename)
    }
    
    private func classifyAlbumGenre(from url: URL) -> String {
        // Analyze tracks in album directory to determine dominant genre
        return AudioCategory.pop.rawValue // Simplified
    }
    
    private func getTrackCount(from url: URL) -> Int {
        // Count audio files in album directory
        return Int.random(in: 8...15) // Simulated
    }
    
    private func getDuration(from url: URL) -> TimeInterval {
        // Get track duration
        return TimeInterval.random(in: 120...300) // Simulated
    }
    
    private func getBitrate(from url: URL) -> Int {
        // Get audio bitrate
        return [128, 192, 256, 320].randomElement()! // Simulated
    }
    
    private func getPlaylistSongCount(from url: URL) -> Int {
        return Int.random(in: 15...50) // Simulated
    }
}

// MARK: - Organization Suggestion
struct OrganizationSuggestion {
    let originalPath: URL
    let suggestedCategory: AudioCategory
    let suggestedPath: String
    let confidence: Double
    let reasoning: String
}

extension AIOrganizationManager {
    func generateOrganizationSuggestions(for results: [URL: MusicAnalysisResult], mode: OrganizationMode) -> [OrganizationSuggestion] {
        var suggestions: [OrganizationSuggestion] = []
        
        for (url, result) in results {
            let suggestion = createSuggestion(url: url, result: result, mode: mode)
            suggestions.append(suggestion)
        }
        
        return suggestions.sorted { $0.confidence > $1.confidence }
    }
    
    private func createSuggestion(url: URL, result: MusicAnalysisResult, mode: OrganizationMode) -> OrganizationSuggestion {
        let category = AudioCategory(rawValue: result.primaryGenre) ?? .electronic
        var suggestedPath = ""
        var reasoning = ""
        
        switch mode {
        case .samples:
            suggestedPath = "Samples/\(result.primaryGenre)/"
            reasoning = "Detected as \(result.primaryGenre) with \(Int(result.confidence * 100))% confidence"
            
        case .albums:
            if let artist = result.metadata["artist"] as? String,
               let year = result.metadata["year"] as? Int {
                suggestedPath = "Albums/\(artist)/\(year) - \(url.lastPathComponent)/"
                reasoning = "Album by \(artist) from \(year)"
            } else {
                suggestedPath = "Albums/\(result.primaryGenre)/\(url.lastPathComponent)/"
                reasoning = "Classified as \(result.primaryGenre)"
            }
            
        case .tracks:
            suggestedPath = "Music/\(result.primaryGenre)/"
            if let mood = result.mood {
                suggestedPath += "\(mood.capitalized)/"
            }
            reasoning = "Genre: \(result.primaryGenre)"
            if let mood = result.mood {
                reasoning += ", Mood: \(mood)"
            }
            
        case .playlists:
            suggestedPath = "Playlists/\(result.primaryGenre)/"
            reasoning = "Theme: \(result.primaryGenre)"
        }
        
        return OrganizationSuggestion(
            originalPath: url,
            suggestedCategory: category,
            suggestedPath: suggestedPath,
            confidence: result.confidence,
            reasoning: reasoning
        )
    }
}