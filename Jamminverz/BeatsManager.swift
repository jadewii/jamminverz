//
//  BeatsManager.swift
//  Jamminverz
//
//  Manages community beats and social features
//

import Foundation
import SwiftUI
import AVFoundation

// MARK: - Data Models
struct Beat: Identifiable, Codable {
    let id: String
    let title: String
    let creator: User
    let audioURL: URL
    let description: String
    let tags: [String]
    let packsUsed: [BeatSamplePack]
    let duration: TimeInterval
    let bpm: Int
    var hearts: Int
    var comments: [Comment]
    var shares: Int
    let isPublic: Bool
    let createdDate: Date
}

// Extended SamplePack with creator info for beats
struct BeatSamplePack: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let creator: User
    
    private enum CodingKeys: String, CodingKey {
        case id, name, icon, creator
        case colorRed, colorGreen, colorBlue
    }
    
    init(from samplePack: SamplePack, creator: User) {
        self.id = samplePack.id
        self.name = samplePack.name
        self.icon = samplePack.icon
        self.color = samplePack.color
        self.creator = creator
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        creator = try container.decode(User.self, forKey: .creator)
        
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
        try container.encode(creator, forKey: .creator)
        
        // Encode color components
        let components = UIColor(color).cgColor.components ?? [0, 0, 0, 1]
        try container.encode(Double(components[0]), forKey: .colorRed)
        try container.encode(Double(components[1]), forKey: .colorGreen)
        try container.encode(Double(components[2]), forKey: .colorBlue)
    }
}

struct Comment: Identifiable, Codable {
    let id: String
    let user: User
    let text: String
    let timestamp: Date
}

struct User: Identifiable, Codable {
    let id: String
    let username: String
    let profileImage: String?
    var createdPacks: [String] // Pack IDs
    var collectedPacks: [String] // Pack IDs
    var sharedBeats: [String] // Beat IDs
    var followers: [String] // User IDs
    var following: [String] // User IDs
    var stats: BeatsUserStats
}

struct BeatsUserStats: Codable {
    var totalPacksCreated: Int
    var totalPackAdds: Int
    var beatsUsingPacks: Int
    var monthlyRank: Int?
    var genre: String?
}

// MARK: - Beats Manager
@MainActor
class BeatsManager: ObservableObject {
    @Published var trendingBeats: [Beat] = []
    @Published var latestBeats: [Beat] = []
    @Published var followingBeats: [Beat] = []
    @Published var availablePacks: [BeatSamplePack] = []
    @Published var currentUser: User?
    
    private var audioPlayer: AVAudioPlayer?
    
    init() {
        loadMockData()
    }
    
    // MARK: - Beat Management
    func shareBeat(title: String, description: String, tags: [String], audioURL: URL, packsUsed: [String]) {
        // Create new beat
        let packs = packsUsed.compactMap { packId in
            availablePacks.first { $0.id == packId }
        }
        
        let beat = Beat(
            id: UUID().uuidString,
            title: title,
            creator: currentUser ?? createMockUser(),
            audioURL: audioURL,
            description: description,
            tags: tags,
            packsUsed: packs,
            duration: 154, // Mock duration
            bpm: 120, // Mock BPM
            hearts: 0,
            comments: [],
            shares: 0,
            isPublic: true,
            createdDate: Date()
        )
        
        latestBeats.insert(beat, at: 0)
        
        // Send notifications to pack creators
        for pack in packs {
            sendPackUsageNotification(pack: pack, beat: beat)
        }
    }
    
    func playBeat(_ beat: Beat) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: beat.audioURL)
            audioPlayer?.play()
        } catch {
            print("Failed to play beat: \(error)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
    }
    
    func likeBeat(_ beat: Beat) {
        if let index = findBeatIndex(beat) {
            trendingBeats[index].hearts += 1
            latestBeats[index].hearts += 1
            
            // Update feed algorithm
            updateFeedRanking()
        }
    }
    
    func unlikeBeat(_ beat: Beat) {
        if let index = findBeatIndex(beat) {
            trendingBeats[index].hearts = max(0, trendingBeats[index].hearts - 1)
            latestBeats[index].hearts = max(0, latestBeats[index].hearts - 1)
            
            updateFeedRanking()
        }
    }
    
    func addComment(to beat: Beat, text: String) {
        guard let user = currentUser else { return }
        
        let comment = Comment(
            id: UUID().uuidString,
            user: user,
            text: text,
            timestamp: Date()
        )
        
        if let index = findBeatIndex(beat) {
            trendingBeats[index].comments.append(comment)
            latestBeats[index].comments.append(comment)
        }
    }
    
    // MARK: - Pack Management
    func createPack(name: String, description: String, samples: [String], genre: String, bpm: String, mood: String, coverArt: String?, isPublic: Bool) -> BeatSamplePack {
        guard let user = currentUser else {
            return BeatSamplePack(
                from: SamplePack(name: name, icon: "📦", color: Color.random),
                creator: createMockUser()
            )
        }
        
        let samplePack = SamplePack(
            name: name,
            icon: "📦",
            color: Color.random
        )
        
        let pack = BeatSamplePack(from: samplePack, creator: user)
        
        availablePacks.append(pack)
        
        // Update user stats
        if var user = currentUser {
            user.createdPacks.append(pack.id)
            user.stats.totalPacksCreated += 1
            currentUser = user
        }
        
        return pack
    }
    
    // MARK: - Social Features
    func followUser(_ userId: String) {
        guard var user = currentUser else { return }
        
        if !user.following.contains(userId) {
            user.following.append(userId)
            currentUser = user
            
            // Update following feed
            updateFollowingFeed()
        }
    }
    
    func unfollowUser(_ userId: String) {
        guard var user = currentUser else { return }
        
        user.following.removeAll { $0 == userId }
        currentUser = user
        
        updateFollowingFeed()
    }
    
    // MARK: - Feed Algorithm
    private func updateFeedRanking() {
        // Sort by engagement score
        trendingBeats.sort { beat1, beat2 in
            let score1 = calculateEngagementScore(beat1)
            let score2 = calculateEngagementScore(beat2)
            return score1 > score2
        }
    }
    
    private func calculateEngagementScore(_ beat: Beat) -> Double {
        let heartWeight = 1.0
        let commentWeight = 2.0
        let shareWeight = 3.0
        let recencyBoost = beat.createdDate.timeIntervalSinceNow > -86400 ? 10.0 : 0.0 // 24 hour boost
        
        return Double(beat.hearts) * heartWeight +
               Double(beat.comments.count) * commentWeight +
               Double(beat.shares) * shareWeight +
               recencyBoost
    }
    
    private func updateFollowingFeed() {
        guard let user = currentUser else { return }
        
        followingBeats = trendingBeats.filter { beat in
            user.following.contains(beat.creator.id)
        }
    }
    
    // MARK: - Notifications
    private func sendPackUsageNotification(pack: BeatSamplePack, beat: Beat) {
        // In production, send push notification
        print("Notification: Your pack '\(pack.name)' was used in '\(beat.title)' by @\(beat.creator.username)!")
    }
    
    // MARK: - Helpers
    private func findBeatIndex(_ beat: Beat) -> Int? {
        trendingBeats.firstIndex { $0.id == beat.id }
    }
    
    private func createMockUser() -> User {
        User(
            id: UUID().uuidString,
            username: "Producer_\(Int.random(in: 100...999))",
            profileImage: nil,
            createdPacks: [],
            collectedPacks: [],
            sharedBeats: [],
            followers: [],
            following: [],
            stats: BeatsUserStats(
                totalPacksCreated: 0,
                totalPackAdds: 0,
                beatsUsingPacks: 0,
                monthlyRank: nil,
                genre: nil
            )
        )
    }
    
    // MARK: - Mock Data
    private func loadMockData() {
        // Create mock users
        let user1 = User(
            id: UUID().uuidString,
            username: "BeatMaker_99",
            profileImage: nil,
            createdPacks: [],
            collectedPacks: [],
            sharedBeats: [],
            followers: ["user2", "user3"],
            following: ["user2"],
            stats: BeatsUserStats(
                totalPacksCreated: 15,
                totalPackAdds: 342,
                beatsUsingPacks: 89,
                monthlyRank: 5,
                genre: "Trap"
            )
        )
        
        let user2 = User(
            id: UUID().uuidString,
            username: "Producer_Mike",
            profileImage: nil,
            createdPacks: [],
            collectedPacks: [],
            sharedBeats: [],
            followers: ["user1"],
            following: ["user1", "user3"],
            stats: BeatsUserStats(
                totalPacksCreated: 23,
                totalPackAdds: 2847,
                beatsUsingPacks: 156,
                monthlyRank: 3,
                genre: "Trap"
            )
        )
        
        let user3 = User(
            id: UUID().uuidString,
            username: "BassGod",
            profileImage: nil,
            createdPacks: [],
            collectedPacks: [],
            sharedBeats: [],
            followers: ["user2"],
            following: [],
            stats: BeatsUserStats(
                totalPacksCreated: 8,
                totalPackAdds: 567,
                beatsUsingPacks: 45,
                monthlyRank: 12,
                genre: "Dubstep"
            )
        )
        
        currentUser = user1
        
        // Create mock packs
        let pack1 = BeatSamplePack(
            from: SamplePack(
                name: "Dark Trap Vibes",
                icon: "🌙",
                color: Color.purple
            ),
            creator: user1
        )
        
        let pack2 = BeatSamplePack(
            from: SamplePack(
                name: "808 Collection",
                icon: "🔊",
                color: Color.red
            ),
            creator: user2
        )
        
        let pack3 = BeatSamplePack(
            from: SamplePack(
                name: "Melodic Dreams",
                icon: "🎹",
                color: Color.blue
            ),
            creator: user3
        )
        
        availablePacks = [pack1, pack2, pack3]
        
        // Create mock beats
        let beat1 = Beat(
            id: UUID().uuidString,
            title: "Midnight Drive",
            creator: user1,
            audioURL: URL(string: "https://example.com/beat1.mp3")!,
            description: "Dark trap beat with heavy 808s",
            tags: ["trap", "midnight", "vibes"],
            packsUsed: [pack1, pack2],
            duration: 154,
            bpm: 120,
            hearts: 234,
            comments: [
                Comment(id: UUID().uuidString, user: user2, text: "This goes hard! 🔥", timestamp: Date().addingTimeInterval(-3600)),
                Comment(id: UUID().uuidString, user: user3, text: "Love the 808 pattern", timestamp: Date().addingTimeInterval(-1800))
            ],
            shares: 12,
            isPublic: true,
            createdDate: Date().addingTimeInterval(-7200)
        )
        
        let beat2 = Beat(
            id: UUID().uuidString,
            title: "Summer Vibes",
            creator: user2,
            audioURL: URL(string: "https://example.com/beat2.mp3")!,
            description: "Uplifting melodic trap",
            tags: ["melodic", "trap", "summer"],
            packsUsed: [pack3],
            duration: 186,
            bpm: 140,
            hearts: 456,
            comments: [
                Comment(id: UUID().uuidString, user: user1, text: "Perfect summer beat!", timestamp: Date().addingTimeInterval(-7200))
            ],
            shares: 23,
            isPublic: true,
            createdDate: Date().addingTimeInterval(-86400)
        )
        
        let beat3 = Beat(
            id: UUID().uuidString,
            title: "Bass Test",
            creator: user3,
            audioURL: URL(string: "https://example.com/beat3.mp3")!,
            description: "Heavy bass experimental",
            tags: ["bass", "experimental", "dubstep"],
            packsUsed: [pack2],
            duration: 132,
            bpm: 140,
            hearts: 89,
            comments: [],
            shares: 5,
            isPublic: true,
            createdDate: Date().addingTimeInterval(-3600)
        )
        
        trendingBeats = [beat1, beat2, beat3]
        latestBeats = [beat3, beat1, beat2]
        followingBeats = [beat2]
        
        // Update ranking
        updateFeedRanking()
    }
}

// MARK: - Color Extension
extension Color {
    static var random: Color {
        Color(
            red: Double.random(in: 0.4...1.0),
            green: Double.random(in: 0.4...1.0),
            blue: Double.random(in: 0.4...1.0)
        )
    }
}