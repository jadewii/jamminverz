import Foundation
import SwiftUI

// MARK: - Playlist Model
struct Playlist: Identifiable, Codable {
    let id: String
    var name: String
    var songs: [AudioFile]
    var createdDate: Date
    
    init(name: String, songs: [AudioFile] = []) {
        self.id = UUID().uuidString
        self.name = name
        self.songs = songs
        self.createdDate = Date()
    }
    
    var songCount: Int {
        songs.count
    }
}

// MARK: - Audio File Model
struct AudioFile: Identifiable, Codable {
    let id: String
    var fileName: String
    var fileURL: URL?
    var duration: TimeInterval?
    
    init(fileName: String, fileURL: URL? = nil) {
        self.id = UUID().uuidString
        self.fileName = fileName
        self.fileURL = fileURL
    }
}

// MARK: - Playlist Manager
class PlaylistManager: ObservableObject {
    static let shared = PlaylistManager()
    
    @Published var playlists: [Playlist] = []
    @Published var isImporting = false
    
    private let documentsDirectory: URL
    private let playlistsKey = "userPlaylists"
    
    init() {
        // Get documents directory
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("MyMusic")
        
        // Create MyMusic directory if it doesn't exist
        try? FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        
        // Load saved playlists
        loadPlaylists()
    }
    
    // MARK: - Playlist Management
    func createPlaylist(name: String, audioFiles: [URL]) {
        var playlist = Playlist(name: name)
        
        // Copy audio files to app documents
        for fileURL in audioFiles {
            if let copiedFile = copyAudioFile(fileURL) {
                playlist.songs.append(copiedFile)
            }
        }
        
        playlists.append(playlist)
        savePlaylists()
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        // Delete audio files
        for song in playlist.songs {
            if let fileURL = song.fileURL {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        
        // Remove playlist
        playlists.removeAll { $0.id == playlist.id }
        savePlaylists()
    }
    
    // MARK: - File Management
    private func copyAudioFile(_ sourceURL: URL) -> AudioFile? {
        let fileName = sourceURL.lastPathComponent
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            // Copy file to app documents
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            return AudioFile(
                fileName: fileName,
                fileURL: destinationURL
            )
        } catch {
            print("Error copying audio file: \(error)")
            return nil
        }
    }
    
    // MARK: - Persistence
    private func savePlaylists() {
        if let encoded = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(encoded, forKey: playlistsKey)
        }
    }
    
    private func loadPlaylists() {
        if let data = UserDefaults.standard.data(forKey: playlistsKey),
           let decoded = try? JSONDecoder().decode([Playlist].self, from: data) {
            playlists = decoded
        }
    }
}