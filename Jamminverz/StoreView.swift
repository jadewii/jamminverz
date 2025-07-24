//
//  StoreView.swift
//  Jamminverz
//
//  JAde Wii official marketplace for premium content
//

import SwiftUI
import StoreKit

struct StoreView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @State private var selectedCategory = "all"
    @State private var storeItems: [StoreItem] = []
    @State private var purchasedItems: Set<String> = []
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Category Filter
                categoryFilter
                
                // Store Items
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(filteredItems) { item in
                                StoreItemCard(
                                    item: item,
                                    isPurchased: purchasedItems.contains(item.id),
                                    onPurchase: { purchaseItem(item) }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .onAppear {
            loadStoreItems()
            checkPurchases()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("JAde Wii")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundColor(.orange)
                        
                        Text("STORE")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    
                    Text("Official sample packs, themes & exclusive content")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Featured Banner
            ZStack {
                LinearGradient(
                    colors: [.orange, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 120)
                .cornerRadius(16)
                
                VStack(spacing: 8) {
                    Text("🔥 NEW RELEASE")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("FUTURE BASS PACK VOL. 3")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text("50 Premium Samples • $14.99")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(title: "ALL", icon: "🛍", isSelected: selectedCategory == "all") {
                    selectedCategory = "all"
                }
                CategoryChip(title: "SAMPLE PACKS", icon: "🎵", isSelected: selectedCategory == "samples") {
                    selectedCategory = "samples"
                }
                CategoryChip(title: "ALBUMS", icon: "💿", isSelected: selectedCategory == "albums") {
                    selectedCategory = "albums"
                }
                CategoryChip(title: "THEMES", icon: "🎨", isSelected: selectedCategory == "themes") {
                    selectedCategory = "themes"
                }
                CategoryChip(title: "COVER ART", icon: "🖼", isSelected: selectedCategory == "art") {
                    selectedCategory = "art"
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
    }
    
    private var filteredItems: [StoreItem] {
        switch selectedCategory {
        case "all":
            return storeItems
        case "samples":
            return storeItems.filter { $0.type == .samplePack }
        case "albums":
            return storeItems.filter { $0.type == .album }
        case "themes":
            return storeItems.filter { $0.type == .theme }
        case "art":
            return storeItems.filter { $0.type == .coverArt }
        default:
            return storeItems
        }
    }
    
    private func loadStoreItems() {
        isLoading = true
        
        // Mock store items
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            storeItems = [
                StoreItem(
                    id: "pack1",
                    type: .samplePack,
                    title: "Future Bass Pack Vol. 3",
                    description: "50 premium future bass samples",
                    price: 14.99,
                    icon: "🎵",
                    metadata: ["samples": 50, "size": "120MB"]
                ),
                StoreItem(
                    id: "pack2",
                    type: .samplePack,
                    title: "Trap Essentials",
                    description: "Essential trap production kit",
                    price: 19.99,
                    icon: "🥁",
                    metadata: ["samples": 80, "size": "200MB"]
                ),
                StoreItem(
                    id: "theme1",
                    type: .theme,
                    title: "Neon Dreams Theme",
                    description: "Vibrant neon profile theme",
                    price: 4.99,
                    icon: "🌈",
                    metadata: ["animated": true]
                ),
                StoreItem(
                    id: "album1",
                    type: .album,
                    title: "Digital Horizons",
                    description: "Full length album by JAde Wii",
                    price: 9.99,
                    icon: "💿",
                    metadata: ["tracks": 12, "duration": "45:32"]
                ),
                StoreItem(
                    id: "art1",
                    type: .coverArt,
                    title: "Abstract Pack",
                    description: "10 abstract cover art designs",
                    price: 7.99,
                    icon: "🎨",
                    metadata: ["designs": 10, "resolution": "3000x3000"]
                )
            ]
            isLoading = false
        }
    }
    
    private func checkPurchases() {
        // Check StoreKit for purchased items
        // For now, using mock data
        purchasedItems = ["pack1"]
    }
    
    private func purchaseItem(_ item: StoreItem) {
        // Implement StoreKit purchase flow
        print("Purchasing \(item.title)")
    }
}

// MARK: - Store Item Model
struct StoreItem: Identifiable {
    let id: String
    let type: StoreItemType
    let title: String
    let description: String
    let price: Double
    let icon: String
    let metadata: [String: Any]
}

enum StoreItemType {
    case samplePack
    case album
    case theme
    case coverArt
}

// MARK: - Store Item Card
struct StoreItemCard: View {
    let item: StoreItem
    let isPurchased: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Preview
            ZStack {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 120)
                
                Text(item.icon)
                    .font(.system(size: 50))
                
                if isPurchased {
                    VStack {
                        HStack {
                            Spacer()
                            Label("OWNED", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(item.description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                // Metadata
                if let samples = item.metadata["samples"] as? Int {
                    Label("\(samples) samples", systemImage: "square.grid.2x2")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                } else if let tracks = item.metadata["tracks"] as? Int {
                    Label("\(tracks) tracks", systemImage: "music.note.list")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Price & Action
                HStack {
                    Text("$\(String(format: "%.2f", item.price))")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Button(action: onPurchase) {
                        if isPurchased {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        } else {
                            Text("BUY")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.orange)
                                .cornerRadius(20)
                        }
                    }
                    .disabled(isPurchased)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var gradientColors: [Color] {
        switch item.type {
        case .samplePack:
            return [.orange, .pink]
        case .album:
            return [.blue, .purple]
        case .theme:
            return [.purple, .pink]
        case .coverArt:
            return [.green, .blue]
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 12, weight: .heavy))
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.orange : Color.white.opacity(0.2))
            .cornerRadius(20)
        }
    }
}

#Preview {
    StoreView(
        taskStore: TaskStore(),
        currentTab: .constant("store")
    )
}