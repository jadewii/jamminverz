//
//  StationDownloadManager.swift
//  Todomai-iOS
//
//  Manages batch downloads for music stations
//

import Foundation
import SwiftUI
import Combine

// MARK: - Download Models
struct MusicStation {
    let id: String
    let name: String
    let songCount: Int
    let totalSizeMB: Int
    let color: Color
    let isAvailable: Bool
    let songs: [StationSong]
}

struct StationSong {
    let filename: String
    let url: String
}

// MARK: - Download States
enum StationDownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case error(String)
}

// MARK: - Station Download Manager
class StationDownloadManager: ObservableObject {
    static let shared = StationDownloadManager()
    
    @Published var downloadStates: [String: StationDownloadState] = [:]
    @Published var currentDownloadID: String? = nil
    
    private var downloadTasks: [URLSessionDownloadTask] = []
    private var currentStationDownload: (station: MusicStation, songIndex: Int)?
    private let fileManager = FileManager.default
    
    // LOFI FOCUS station with all 50 songs
    let lofiStation = MusicStation(
        id: "lofi",
        name: "LOFI FOCUS",
        songCount: 50,
        totalSizeMB: 150,
        color: Color(red: 0.373, green: 0.275, blue: 0.569), // Rich vibrant purple
        isAvailable: true,
        songs: createLofiSongs()
    )
    
    private init() {
        // Initialize download states
        downloadStates["lofi"] = .notDownloaded
        downloadStates["piano"] = .notDownloaded
        downloadStates["hiphop"] = .notDownloaded
        downloadStates["jungle"] = .notDownloaded
        
        // Check if stations are already downloaded
        checkExistingDownloads()
    }
    
    // Create song list for LOFI station
    private static func createLofiSongs() -> [StationSong] {
        // All 50 songs from the Internet Archive collection
        let fileNumbers = [100, 11, 15, 16, 19, 2, 20, 21, 23, 25, 26, 27, 28, 29, 3, 30, 31, 33, 34, 35, 36, 37, 38, 39, 4, 40, 41, 42, 43, 44, 45, 46, 47, 48, 5, 50, 51, 52, 53, 54, 55, 56, 57, 58, 6, 62, 69, 7, 94, 97]
        
        return fileNumbers.map { number in
            StationSong(
                filename: "File \(number).m4a",
                url: "https://archive.org/download/file-100/File%20\(number).m4a"
            )
        }
    }
    
    // MARK: - Public Methods
    func downloadStation(_ station: MusicStation) {
        guard currentDownloadID == nil else {
            print("Another download is in progress")
            return
        }
        
        currentDownloadID = station.id
        downloadStates[station.id] = .downloading(progress: 0.0)
        currentStationDownload = (station, 0)
        
        // Create station directory
        let documentsPath = getDocumentsDirectory()
        let musicPath = documentsPath.appendingPathComponent("Music")
        let stationPath = musicPath.appendingPathComponent(station.name.replacingOccurrences(of: " ", with: "_"))
        
        do {
            try fileManager.createDirectory(at: stationPath, withIntermediateDirectories: true, attributes: nil)
            
            // Start downloading songs
            downloadNextSong()
        } catch {
            print("Error creating directory: \(error)")
            downloadStates[station.id] = .error("Failed to create directory")
            currentDownloadID = nil
        }
    }
    
    func cancelDownload() {
        downloadTasks.forEach { $0.cancel() }
        downloadTasks.removeAll()
        
        if let id = currentDownloadID {
            downloadStates[id] = .notDownloaded
        }
        
        currentDownloadID = nil
        currentStationDownload = nil
    }
    
    func deleteStation(_ stationID: String) {
        let station = getStation(by: stationID)
        let documentsPath = getDocumentsDirectory()
        let stationPath = documentsPath
            .appendingPathComponent("Music")
            .appendingPathComponent(station.name.replacingOccurrences(of: " ", with: "_"))
        
        do {
            try fileManager.removeItem(at: stationPath)
            downloadStates[stationID] = .notDownloaded
        } catch {
            print("Error deleting station: \(error)")
        }
    }
    
    func getStation(by id: String) -> MusicStation {
        switch id {
        case "lofi":
            return lofiStation
        case "piano":
            return MusicStation(id: "piano", name: "PIANO", songCount: 0, totalSizeMB: 0, color: Color(red: 0.8, green: 0.6, blue: 1.0), isAvailable: false, songs: []) // Light purple
        case "hiphop":
            return MusicStation(id: "hiphop", name: "HIPHOP", songCount: 0, totalSizeMB: 0, color: Color(red: 1.0, green: 0.7, blue: 0.8), isAvailable: false, songs: []) // Pink hint
        case "jungle":
            return MusicStation(id: "jungle", name: "JUNGLE", songCount: 0, totalSizeMB: 0, color: Color(red: 1.0, green: 0.9, blue: 0.4), isAvailable: false, songs: []) // Yellow hint
        default:
            return lofiStation
        }
    }
    
    // MARK: - Private Methods
    private func downloadNextSong() {
        guard let (station, songIndex) = currentStationDownload else { return }
        
        if songIndex >= station.songs.count {
            // All songs downloaded
            downloadStates[station.id] = .downloaded
            currentDownloadID = nil
            currentStationDownload = nil
            return
        }
        
        let song = station.songs[songIndex]
        guard let url = URL(string: song.url) else {
            print("Invalid URL: \(song.url)")
            downloadNextSongAfterError()
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            DispatchQueue.main.async {
                self?.handleDownloadCompletion(tempURL: tempURL, song: song, station: station, songIndex: songIndex, error: error)
            }
        }
        
        downloadTasks.append(task)
        task.resume()
    }
    
    private func handleDownloadCompletion(tempURL: URL?, song: StationSong, station: MusicStation, songIndex: Int, error: Error?) {
        if let error = error {
            print("Download error for \(song.filename): \(error)")
            downloadNextSongAfterError()
            return
        }
        
        guard let tempURL = tempURL else {
            downloadNextSongAfterError()
            return
        }
        
        // Move file to station directory
        let documentsPath = getDocumentsDirectory()
        let stationPath = documentsPath
            .appendingPathComponent("Music")
            .appendingPathComponent(station.name.replacingOccurrences(of: " ", with: "_"))
        let destinationURL = stationPath.appendingPathComponent(song.filename)
        
        do {
            // Remove existing file if it exists
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            
            // Update progress
            let progress = Double(songIndex + 1) / Double(station.songs.count)
            downloadStates[station.id] = .downloading(progress: progress)
            
            // Download next song
            currentStationDownload = (station, songIndex + 1)
            downloadNextSong()
            
        } catch {
            print("Error moving file: \(error)")
            downloadNextSongAfterError()
        }
    }
    
    private func downloadNextSongAfterError() {
        guard let (station, songIndex) = currentStationDownload else { return }
        
        // Skip this song and try the next one
        currentStationDownload = (station, songIndex + 1)
        downloadNextSong()
    }
    
    private func checkExistingDownloads() {
        let documentsPath = getDocumentsDirectory()
        let musicPath = documentsPath.appendingPathComponent("Music")
        
        // Check LOFI FOCUS
        let lofiPath = musicPath.appendingPathComponent("LOFI_FOCUS")
        if fileManager.fileExists(atPath: lofiPath.path) {
            // Count files to verify complete download
            do {
                let files = try fileManager.contentsOfDirectory(at: lofiPath, includingPropertiesForKeys: nil)
                if files.count >= 45 { // Allow for some missing files
                    downloadStates["lofi"] = .downloaded
                }
            } catch {
                print("Error checking LOFI folder: \(error)")
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

// MARK: - Progress View Component
struct StationDownloadProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.white)
                .background(Color.white.opacity(0.2))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.white)
        }
    }
}