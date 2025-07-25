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
    
    // WORLD RADIO station with all Suno songs
    let lofiStation = MusicStation(
        id: "lofi",
        name: "WORLD RADIO",
        songCount: createWorldRadioSongs().count, // Dynamic count
        totalSizeMB: 0, // No download needed - using local files
        color: Color(red: 0.373, green: 0.275, blue: 0.569), // Rich vibrant purple
        isAvailable: true,
        songs: createWorldRadioSongs()
    )
    
    private init() {
        // Initialize download states
        downloadStates["lofi"] = .downloaded // World Radio streams from local files
        downloadStates["piano"] = .notDownloaded
        downloadStates["hiphop"] = .notDownloaded
        downloadStates["jungle"] = .notDownloaded
        
        // Check if stations are already downloaded
        checkExistingDownloads()
    }
    
    // Create song list for WORLD RADIO station from Internet Archive
    private static func createWorldRadioSongs() -> [StationSong] {
        var songs: [StationSong] = []
        
        // All songs from your archive.org collection
        let archiveCollection = "audio-ambient-collection-2024"
        let songFiles = [
            "[AI] Song_2_3ed88492-7335-4113-a1ba-0a1f71aceea8.mp3",
            "[AI] Song_34_8179f08c-483f-4bbe-b29c-254959f74581.mp3",
            "[AI] Song_36_ffbc4383-308e-4885-b070-96ef3f4602bf.mp3",
            "[AI] Song_42_3ed88492-7335-4113-a1ba-0a1f71aceea8.mp3",
            "[AI] Song_42_b676e121-82d2-4e1e-ab0d-29ecb23626a1.mp3",
            "[AI] Song_44_1f083bb3-7884-433a-98f0-c7bf60c0a4c8.mp3",
            "[AI] Song_44_308df5af-6c27-4e2b-9beb-ee203186092b.mp3",
            "[AI] Song_44_4c1c2220-07a1-4232-94c0-95e71417ec16.mp3",
            "[AI] Song_44_519b499d-a007-4f55-9f72-4e89fd3f08d2.mp3",
            "[AI] Song_44_998bc90b-cf43-4fad-afa5-4a69935ec108.mp3",
            "[AI] Song_44_a8698d5d-9423-40a1-9cf8-734ae3c74ef0.mp3",
            "[AI] Song_44_bbbc599d-adac-4e89-b3a1-5e82eb2a9398.mp3",
            "[AI] Song_44_bbe51575-2846-4bb1-a569-5123335f9874.mp3",
            "[AI] Song_44_d318ef74-df7f-4d23-9a06-b83440439f31.mp3",
            "[AI] Song_44_da1c8864-0ecc-4f76-8f30-5e08bb16342c.mp3",
            "[AI] Song_46_259fa5ce-95c2-44e9-b746-50869feb5c91.mp3",
            "[AI] Song_46_4968e2b5-b32e-4017-a6eb-baf572fe23d1.mp3",
            "[AI] Song_46_4c91c854-ad45-443d-ac78-9bd830c750fb.mp3",
            "[AI] Song_46_8931f273-eb71-4dde-a19e-44ee7d8ab365.mp3",
            "[AI] Song_46_97d57d53-ab5e-4d24-bb8d-96b2615d8f95.mp3",
            "[AI] Song_46_9b75ece0-910d-4c67-8d01-e1bbe04c9a51.mp3",
            "[AI] Song_46_9eda4b4a-7d02-4dbf-916b-cabc52cd7fbe.mp3",
            "[AI] Song_48_0a679298-5568-4a9f-bf39-8152e57c205f.mp3",
            "[AI] Song_48_740c0bc6-3eaa-4f4f-8277-0a2d577a22b0.mp3",
            "[AI] Song_48_9e7e972e-0f46-4d80-b4f8-e59abfdd000d.mp3",
            "[AI] Song_48_b8baac95-b327-44d1-9763-d565e2079127.mp3",
            "[AI] Song_4_4c1c2220-07a1-4232-94c0-95e71417ec16.mp3",
            "[AI] Song_50_2f06ac57-0260-472f-a568-fda66d35f7fe.mp3",
            "[AI] Song_50_5eec1616-2d80-4265-83e3-2fc9e36285c0.mp3",
            "[AI] Song_50_fef1e4a7-4161-4db2-85df-0325b6020df4.mp3",
            "[AI] Song_52_3bae63a8-fe6d-48f7-9f14-d482c427281a.mp3",
            "[AI] Song_52_44a09b75-cd79-4561-ab8f-62bd4489d19b.mp3",
            "[AI] Song_52_5022e7c5-c97a-4c3c-a694-c86bd6edabe1.mp3",
            "[AI] Song_52_9bc0c0ba-4a28-4454-bd85-1f091e4b318e.mp3",
            "[AI] Song_54_0528428c-d6d2-4170-a4c1-58058dc7f2b4.mp3",
            "[AI] Song_54_43cb0e78-e1d0-4df0-96b5-1a8541b021b8.mp3",
            "[AI] Song_54_50e2b8ff-fcef-47cd-a299-ad3a28d3a7ec.mp3",
            "[AI] Song_54_6bed0435-8145-4690-b025-35842ae6c766.mp3",
            "[AI] Song_54_7bfc7bb2-eee4-48cc-9090-16bd238be69e.mp3",
            "[AI] Song_54_8b48804b-50be-466f-9b49-09c443c07557.mp3",
            "[AI] Song_54_b04828e9-56f8-4c75-8727-e0fb4edca05c.mp3",
            "[AI] Song_56_168be125-6673-4868-b3a2-fa948b7dd925.mp3",
            "[AI] Song_56_28f4c5b9-c41e-4ecf-a96a-8d6b2bfbad3c.mp3",
            "[AI] Song_56_2ac0b5b7-cfe4-4375-8913-8fbedcc4488a.mp3",
            "[AI] Song_56_51e05c73-6d25-4560-9b50-fe9c8176ce07.mp3",
            "[AI] Song_56_58e02782-74d3-4542-b040-8c8d31ebb6ce.mp3",
            "[AI] Song_56_7a74fc7a-6baa-4611-9495-2b411f0afd29.mp3",
            "[AI] Song_56_8678eda1-a636-4891-8a94-210875b56597.mp3",
            "[AI] Song_56_94e685e2-73ad-4bbf-be4e-d23255bcc287.mp3",
            "[AI] Song_56_bdc81f05-5f73-4303-81bd-ab6901c05814.mp3",
            "[AI] Song_56_d8c97f84-ce76-4017-b215-ac21fc15d19f.mp3",
            "[AI] Song_58_7fa25251-5d73-4eca-b9ce-79175b730c59.mp3",
            "[AI] Song_58_92ce71da-6f5f-4fef-9bd5-b7535e60283e.mp3",
            "[AI] Song_58_bc5bfe19-d804-4ec1-83e2-b06a5cee7dd2.mp3",
            "[AI] Song_58_c3411430-ca5c-496b-b385-2d32d6d6f8bc.mp3",
            "[AI] Song_58_cbb7b282-4985-42ba-a79f-16a396842ce5.mp3",
            "[AI] Song_58_f27fbb1c-2038-4b97-8705-1c1d46cc4aee.mp3",
            "[AI] Song_60_9752abc5-4374-42c8-bd5e-55bf39a2101b.mp3",
            "[AI] Song_60_e10e09b1-c7ae-40e5-b5b5-c53f226ed2ba.mp3",
            "[AI] Song_62_b7c676ae-815e-4613-bd74-15708a285e39.mp3",
            "[AI] Song_62_d5790b13-c580-4cf8-814c-2bc130eaac95.mp3",
            "[AI] Song_62_ee572de8-6a52-491b-be08-30146933df0f.mp3",
            "[AI] Song_64_27092880-f9c7-4020-8f4e-4bd2768aba27.mp3",
            "[AI] Song_64_6e46b3e3-bd00-4bfd-b204-d8ec59a9a7af.mp3",
            "[AI] Song_64_bc892f04-ec71-4ce7-98d3-dfe5d501f955.mp3",
            "[AI] Song_64_fb125d3d-663e-4b32-ab7f-163a754c3e15.mp3",
            "[AI] Song_66_2164b4b9-776b-4958-b5bd-ba310142fc84.mp3",
            "[AI] Song_66_2b022460-5975-4196-856e-d64849b5598e.mp3",
            "[AI] Song_66_8701d597-e52b-4383-905e-d2562b47a302.mp3",
            "[AI] Song_66_b1b5dbc1-cd82-4d56-8eb7-064409d7ed98.mp3",
            "[AI] Song_68_4e5df31b-d77f-404d-bca7-f960382c3ab6.mp3",
            "[AI] Song_68_51b39c5e-b133-4802-9d8a-546313f11c4d.mp3",
            "[AI] Song_68_c1149fd5-0229-4aa1-9aaf-9897522156df.mp3",
            "[AI] Song_68_f9108480-8b79-424f-a07c-c3ab7bdb3aee.mp3",
            "[AI] Song_68_fbb2c41c-45b4-4c74-9a70-dc3f4190190b.mp3",
            "[AI] Song_70_09c9ff2a-1e4c-4576-b63a-cc511edf0e89.mp3",
            "[AI] Song_70_0ad170f2-d056-4a94-9dff-f904a2e671de.mp3",
            "[AI] Song_70_394be892-75a9-4c3c-8508-3df54c31a95c.mp3",
            "[AI] Song_70_5b08aab4-47ec-4999-b5f0-75180695b0c7.mp3",
            "[AI] Song_70_5fa13b86-cd92-40b7-a2f7-3821983bc361.mp3",
            "[AI] Song_70_b6609f6a-39ad-4d08-b5d1-aa6cc1bcf736.mp3",
            "[AI] Song_72_279125d0-0215-476d-a0b5-354c564410e4.mp3",
            "[AI] Song_72_bb88b76c-f213-4816-a44b-5b6d0898d839.mp3",
            "[AI] Song_72_bcbab722-b360-41c3-bd97-0f126805fcd2.mp3",
            "[AI] Song_72_fa5de014-468f-4663-b6c3-6ce34faf6b03.mp3",
            "[AI] Song_74_07fa5d35-a7bb-4fad-b77d-193e586fd42f.mp3",
            "[AI] Song_74_1889663d-cf34-4022-923b-bbfd1877a827.mp3",
            "[AI] Song_74_dfc291cd-679b-4ec4-b8d5-efc5ef4bf17f.mp3",
            "[AI] Song_76_30aa0fd2-5b40-47d9-8076-3f6876a55ebc.mp3",
            "[AI] Song_76_550de3a6-c3ac-47f3-8870-800c50d374e4.mp3",
            "[AI] Song_76_5ab2c11a-6bc3-49e6-b84f-e6151a444da2.mp3",
            "[AI] Song_76_a5886ceb-d5cc-474d-89e6-9394690628a4.mp3",
            "[AI] Song_76_dd9ee4d6-8e55-4f64-a561-ed5b7b007dbd.mp3",
            "[AI] Song_78_0eea969c-b098-46db-87f1-513cbb0733ca.mp3",
            "[AI] Song_78_29cb0177-3b11-465e-b611-10f0dd48e72b.mp3",
            "[AI] Song_78_43a2b0d6-3ce0-40f9-9a94-0126ca076b52.mp3",
            "[AI] Song_78_76f0d120-d94e-490c-b53d-40942c80a0ff.mp3",
            "[AI] Song_78_955860aa-a29b-4f75-97a4-531895a88ca1.mp3",
            "[AI] Song_78_afcb2bca-9d1b-4467-bb61-610b484d0fd1.mp3",
            "[AI] Song_78_d22ded3d-f4f4-4848-a261-d1570b18650d.mp3"
        ]
        
        // Create proper archive.org URLs
        for filename in songFiles {
            let encodedFilename = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filename
            let url = "https://archive.org/download/\(archiveCollection)/\(encodedFilename)"
            
            songs.append(StationSong(
                filename: filename,
                url: url
            ))
        }
        
        print("Loaded \(songs.count) songs for World Radio from Internet Archive")
        
        return songs
    }
    
    // MARK: - Public Methods
    func downloadStation(_ station: MusicStation) {
        // World Radio doesn't need downloading - it streams from local files
        if station.id == "lofi" {
            downloadStates[station.id] = .downloaded
            return
        }
        
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
        // Can't delete World Radio - it's streaming from local files
        if stationID == "lofi" {
            print("World Radio cannot be deleted - it streams from local files")
            return
        }
        
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
        
        // Check WORLD RADIO
        let worldRadioPath = musicPath.appendingPathComponent("WORLD_RADIO")
        if fileManager.fileExists(atPath: worldRadioPath.path) {
            // Count files to verify complete download
            do {
                let files = try fileManager.contentsOfDirectory(at: worldRadioPath, includingPropertiesForKeys: nil)
                if files.count >= 100 { // Allow for partial collection
                    downloadStates["lofi"] = .downloaded
                }
            } catch {
                print("Error checking WORLD RADIO folder: \(error)")
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