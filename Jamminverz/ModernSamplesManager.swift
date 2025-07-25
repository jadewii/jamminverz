//
//  ModernSamplesManager.swift
//  Jamminverz
//
//  Manages audio file scanning and sample pack organization
//

import Foundation
import SwiftUI
import AVFoundation

// MARK: - Audio File Model
struct SampleFile: Identifiable, Codable, Transferable {
    var id = UUID().uuidString
    let url: URL
    let name: String
    let size: Int64
    let duration: TimeInterval?
    let bpm: Double?
    let dateModified: Date
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .audioContent)
    }
}

// MARK: - Sample Pack Model
struct SamplePack: Identifiable, Codable {
    var id = UUID().uuidString
    var name: String
    var icon: String
    var color: Color
    var samples: [String] = [] // Audio file IDs
    var dateCreated: Date = Date()
    
    private enum CodingKeys: String, CodingKey {
        case id, name, icon, samples, dateCreated
        case colorRed, colorGreen, colorBlue
    }
    
    init(name: String, icon: String, color: Color) {
        self.name = name
        self.icon = icon
        self.color = color
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        samples = try container.decode([String].self, forKey: .samples)
        dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        
        let red = try container.decode(Double.self, forKey: .colorRed)
        let green = try container.decode(Double.self, forKey: .colorGreen)
        let blue = try container.decode(Double.self, forKey: .colorBlue)
        color = Color(red: red, green: green, blue: blue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(samples, forKey: .samples)
        try container.encode(dateCreated, forKey: .dateCreated)
        
        // Encode color components
        let components = UIColor(color).cgColor.components ?? [0, 0, 0, 1]
        try container.encode(Double(components[0]), forKey: .colorRed)
        try container.encode(Double(components[1]), forKey: .colorGreen)
        try container.encode(Double(components[2]), forKey: .colorBlue)
    }
}

// MARK: - Modern Samples Manager
@MainActor
class ModernSamplesManager: ObservableObject {
    @Published var audioFiles: [SampleFile] = []
    @Published var samplePacks: [SamplePack] = []
    @Published var favoritePacks: Set<String> = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    
    private let fileManager = FileManager.default
    private let supportedExtensions = ["wav", "mp3", "aiff", "flac", "m4a", "ogg", "wma"]
    private let bpmAnalyzer = BPMAnalyzer()
    
    // Default sample packs
    private let defaultPacks = [
        ("TRAP", "🎵", Color(red: 0.91, green: 0.475, blue: 0.976)),
        ("HOUSE", "🥁", Color(red: 0.957, green: 0.447, blue: 0.714)),
        ("LOFI", "🎹", Color(red: 0.376, green: 0.647, blue: 0.98)),
        ("DRILL", "🎸", Color(red: 0.204, green: 0.827, blue: 0.6)),
        ("R&B", "🎤", Color(red: 0.984, green: 0.749, blue: 0.141)),
        ("TECHNO", "🎧", Color(red: 0.655, green: 0.545, blue: 0.98))
    ]
    
    init() {
        loadSamplePacks()
        loadFavorites()
        if samplePacks.isEmpty {
            createDefaultPacks()
        }
    }
    
    // MARK: - File Scanning
    func scanForAudioFiles() {
        _Concurrency.Task {
            await scanDirectories()
        }
    }
    
    @MainActor
    private func scanDirectories() async {
        isScanning = true
        scanProgress = 0.0
        audioFiles.removeAll()
        
        // Directories to scan
        let searchPaths: [FileManager.SearchPathDirectory] = [
            .musicDirectory,
            .documentDirectory,
            .downloadsDirectory
        ]
        
        var allFiles: [SampleFile] = []
        
        for searchPath in searchPaths {
            if let url = fileManager.urls(for: searchPath, in: .userDomainMask).first {
                await scanDirectory(url, into: &allFiles)
            }
        }
        
        // Also scan desktop
        if let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first {
            await scanDirectory(desktopURL, into: &allFiles)
        }
        
        // Sort by date modified
        audioFiles = allFiles.sorted { $0.dateModified > $1.dateModified }
        isScanning = false
    }
    
    private func scanDirectory(_ directory: URL, into files: inout [SampleFile]) async {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        while let element = enumerator.nextObject() {
            guard let fileURL = element as? URL else { continue }
            let pathExtension = fileURL.pathExtension.lowercased()
            
            if supportedExtensions.contains(pathExtension) {
                do {
                    let attributes = try fileURL.resourceValues(forKeys: [
                        .fileSizeKey,
                        .contentModificationDateKey
                    ])
                    
                    let size = Int64(attributes.fileSize ?? 0)
                    let dateModified = attributes.contentModificationDate ?? Date()
                    
                    // Get duration
                    let duration = await getAudioDuration(url: fileURL)
                    
                    // Quick BPM detection (simplified for demo)
                    let bpm = await detectBPM(url: fileURL)
                    
                    let audioFile = SampleFile(
                        url: fileURL,
                        name: fileURL.lastPathComponent,
                        size: size,
                        duration: duration,
                        bpm: bpm,
                        dateModified: dateModified
                    )
                    
                    files.append(audioFile)
                    
                    // Update progress
                    await MainActor.run {
                        self.scanProgress = Double(files.count) / 100.0 // Estimate
                    }
                    
                } catch {
                    print("Error scanning file: \(error)")
                }
            }
        }
    }
    
    private func getAudioDuration(url: URL) async -> TimeInterval? {
        do {
            let asset = AVAsset(url: url)
            let duration = try await asset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            return nil
        }
    }
    
    private func detectBPM(url: URL) async -> Double? {
        // Simplified BPM detection - in production, use proper audio analysis
        return Double.random(in: 80...180)
    }
    
    // MARK: - Sample Pack Management
    func createPack(name: String, icon: String, color: Color) {
        let pack = SamplePack(name: name, icon: icon, color: color)
        samplePacks.append(pack)
        saveSamplePacks()
    }
    
    func addSamplesToPack(_ samples: [SampleFile], pack: SamplePack) {
        guard let index = samplePacks.firstIndex(where: { $0.id == pack.id }) else { return }
        
        let sampleIds = samples.map { $0.id }
        samplePacks[index].samples.append(contentsOf: sampleIds)
        saveSamplePacks()
    }
    
    func removeSampleFromPack(_ sampleId: String, pack: SamplePack) {
        guard let index = samplePacks.firstIndex(where: { $0.id == pack.id }) else { return }
        
        samplePacks[index].samples.removeAll { $0 == sampleId }
        saveSamplePacks()
    }
    
    func getSamplesForPack(_ pack: SamplePack) -> [SampleFile] {
        // Return all audio files that match the sample IDs in the pack
        return audioFiles.filter { sample in
            pack.samples.contains(sample.id)
        }
    }
    
    func createAutoPacksWithAI() {
        // Group samples by characteristics
        let kickSamples = audioFiles.filter { $0.name.lowercased().contains("kick") }
        let snareSamples = audioFiles.filter { $0.name.lowercased().contains("snare") }
        let bassSamples = audioFiles.filter { $0.name.lowercased().contains("bass") }
        let melodySamples = audioFiles.filter { 
            $0.name.lowercased().contains("melody") || 
            $0.name.lowercased().contains("loop") ||
            $0.name.lowercased().contains("synth")
        }
        
        // Create packs
        if !kickSamples.isEmpty {
            var kickPack = SamplePack(name: "AI: Kicks", icon: "🦵", color: Color.red)
            kickPack.samples = kickSamples.map { $0.id }
            samplePacks.append(kickPack)
        }
        
        if !snareSamples.isEmpty {
            var snarePack = SamplePack(name: "AI: Snares", icon: "🥁", color: Color.orange)
            snarePack.samples = snareSamples.map { $0.id }
            samplePacks.append(snarePack)
        }
        
        if !bassSamples.isEmpty {
            var bassPack = SamplePack(name: "AI: Bass", icon: "🎸", color: Color.purple)
            bassPack.samples = bassSamples.map { $0.id }
            samplePacks.append(bassPack)
        }
        
        if !melodySamples.isEmpty {
            var melodyPack = SamplePack(name: "AI: Melodies", icon: "🎹", color: Color.blue)
            melodyPack.samples = melodySamples.map { $0.id }
            samplePacks.append(melodyPack)
        }
        
        saveSamplePacks()
    }
    
    // MARK: - Favorite Management
    func toggleFavorite(_ packId: String) {
        if favoritePacks.contains(packId) {
            favoritePacks.remove(packId)
        } else {
            favoritePacks.insert(packId)
        }
        saveFavorites()
    }
    
    func isFavorite(_ packId: String) -> Bool {
        favoritePacks.contains(packId)
    }
    
    var favoritedPacks: [SamplePack] {
        samplePacks.filter { favoritePacks.contains($0.id) }
    }
    
    // MARK: - Persistence
    private func saveSamplePacks() {
        guard let url = getPacksURL() else { return }
        
        do {
            let data = try JSONEncoder().encode(samplePacks)
            try data.write(to: url)
        } catch {
            print("Failed to save packs: \(error)")
        }
    }
    
    private func loadSamplePacks() {
        guard let url = getPacksURL(),
              fileManager.fileExists(atPath: url.path) else { return }
        
        do {
            let data = try Data(contentsOf: url)
            samplePacks = try JSONDecoder().decode([SamplePack].self, from: data)
        } catch {
            print("Failed to load packs: \(error)")
        }
    }
    
    private func getPacksURL() -> URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("JamminverzSamplePacks.json")
    }
    
    private func createDefaultPacks() {
        for (name, icon, color) in defaultPacks {
            createPack(name: name, icon: icon, color: color)
        }
    }
    
    private func saveFavorites() {
        guard let url = getFavoritesURL() else { return }
        
        do {
            let data = try JSONEncoder().encode(Array(favoritePacks))
            try data.write(to: url)
        } catch {
            print("Failed to save favorites: \(error)")
        }
    }
    
    private func loadFavorites() {
        guard let url = getFavoritesURL(),
              fileManager.fileExists(atPath: url.path) else { return }
        
        do {
            let data = try Data(contentsOf: url)
            let favoriteIds = try JSONDecoder().decode([String].self, from: data)
            favoritePacks = Set(favoriteIds)
        } catch {
            print("Failed to load favorites: \(error)")
        }
    }
    
    private func getFavoritesURL() -> URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("JamminverzFavoritePacks.json")
    }
}

// MARK: - BPM Analyzer (Simplified)
class BPMAnalyzer {
    func analyze(url: URL) async -> Double? {
        // In production, implement proper BPM detection using:
        // - FFT analysis
        // - Peak detection
        // - Tempo tracking algorithms
        
        // For now, return estimated BPM based on genre hints in filename
        let filename = url.lastPathComponent.lowercased()
        
        if filename.contains("trap") {
            return Double.random(in: 140...160)
        } else if filename.contains("house") {
            return Double.random(in: 120...130)
        } else if filename.contains("dnb") || filename.contains("drum") {
            return Double.random(in: 170...180)
        } else if filename.contains("hip") || filename.contains("hop") {
            return Double.random(in: 80...95)
        } else if filename.contains("techno") {
            return Double.random(in: 125...135)
        } else {
            return Double.random(in: 100...140)
        }
    }
}

// MARK: - Content Type Extension
import UniformTypeIdentifiers

extension UTType {
    static let audioContent = UTType.audio
}