//
//  ArtStoreView.swift
//  Jamminverz
//
//  Curated album art gallery with purchase functionality
//

import SwiftUI
import StoreKit

struct ArtStoreView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @State private var selectedCategory = "all"
    @State private var selectedArt: AlbumArt?
    @State private var showPurchaseConfirmation = false
    @State private var isLoading = false
    @State private var artCollection: [AlbumArt] = []
    @State private var purchasedArtIds: Set<String> = []
    @State private var currentPage = 1
    @State private var selectedFilters = ArtFilters()
    
    let itemsPerPage = 12
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Category Tabs
                categoryTabs
                
                // Filter Bar
                filterBar
                
                // Art Gallery
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    Spacer()
                } else {
                    artGallery
                }
                
                // Pagination
                if !filteredArt.isEmpty {
                    paginationControls
                }
            }
        }
        .sheet(item: $selectedArt) { art in
            ArtDetailView(
                art: art,
                isPurchased: purchasedArtIds.contains(art.id),
                onPurchase: { purchaseArt(art) },
                onClose: { selectedArt = nil }
            )
        }
        .alert("Purchase Complete!", isPresented: $showPurchaseConfirmation) {
            Button("OK") { }
        } message: {
            Text("You now have full rights to use this artwork in your Jamminverz albums, profile, and sample packs.")
        }
        .onAppear {
            loadArtCollection()
            loadPurchasedArt()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("ALBUM ART")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundColor(.purple)
                        
                        Text("GALLERY")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    
                    Text("Curated cover art by JAde Wii • Full usage rights included")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Purchase count
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(purchasedArtIds.count)")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.purple)
                    Text("OWNED")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                CategoryTab(title: "ALL", isSelected: selectedCategory == "all") {
                    selectedCategory = "all"
                }
                CategoryTab(title: "FEATURED", isSelected: selectedCategory == "featured") {
                    selectedCategory = "featured"
                }
                CategoryTab(title: "LIMITED", isSelected: selectedCategory == "limited") {
                    selectedCategory = "limited"
                }
                CategoryTab(title: "OWNED", isSelected: selectedCategory == "owned") {
                    selectedCategory = "owned"
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Mood filters
                FilterMenu(title: "MOOD", options: ["All", "Lofi", "Dreamy", "Glitch", "Dark", "Vibrant", "Minimal"]) { mood in
                    selectedFilters.mood = mood == "All" ? nil : mood
                }
                
                // Color filters
                FilterMenu(title: "COLOR", options: ["All", "Purple", "Blue", "Pink", "Green", "Red", "Monochrome"]) { color in
                    selectedFilters.color = color == "All" ? nil : color
                }
                
                // Genre filters
                FilterMenu(title: "GENRE", options: ["All", "Trap", "Ambient", "Vaporwave", "House", "Experimental", "Hip Hop"]) { genre in
                    selectedFilters.genre = genre == "All" ? nil : genre
                }
                
                // Price filters
                FilterMenu(title: "PRICE", options: ["All", "Under $5", "$5-$10", "Over $10"]) { price in
                    selectedFilters.priceRange = price == "All" ? nil : price
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 12)
    }
    
    private var artGallery: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ], spacing: 20) {
                ForEach(paginatedArt) { art in
                    ArtCard(
                        art: art,
                        isPurchased: purchasedArtIds.contains(art.id),
                        onTap: { selectedArt = art }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }
    
    private var paginationControls: some View {
        HStack(spacing: 20) {
            Button(action: { currentPage = max(1, currentPage - 1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(currentPage > 1 ? .white : .gray)
            }
            .disabled(currentPage <= 1)
            
            Text("Page \(currentPage) of \(totalPages)")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.gray)
            
            Button(action: { currentPage = min(totalPages, currentPage + 1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(currentPage < totalPages ? .white : .gray)
            }
            .disabled(currentPage >= totalPages)
        }
        .padding(.vertical, 20)
    }
    
    private var filteredArt: [AlbumArt] {
        artCollection.filter { art in
            // Category filter
            switch selectedCategory {
            case "featured":
                if !art.isFeatured { return false }
            case "limited":
                if !art.isLimited { return false }
            case "owned":
                if !purchasedArtIds.contains(art.id) { return false }
            default:
                break
            }
            
            // Additional filters
            if let mood = selectedFilters.mood, !art.tags.contains(mood.lowercased()) { return false }
            if let color = selectedFilters.color, !art.tags.contains(color.lowercased()) { return false }
            if let genre = selectedFilters.genre, !art.tags.contains(genre.lowercased()) { return false }
            
            // Price filter
            if let priceRange = selectedFilters.priceRange {
                switch priceRange {
                case "Under $5":
                    if art.price >= 5.0 { return false }
                case "$5-$10":
                    if art.price < 5.0 || art.price > 10.0 { return false }
                case "Over $10":
                    if art.price <= 10.0 { return false }
                default:
                    break
                }
            }
            
            return true
        }
    }
    
    private var paginatedArt: [AlbumArt] {
        let startIndex = (currentPage - 1) * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, filteredArt.count)
        
        guard startIndex < filteredArt.count else { return [] }
        return Array(filteredArt[startIndex..<endIndex])
    }
    
    private var totalPages: Int {
        max(1, (filteredArt.count + itemsPerPage - 1) / itemsPerPage)
    }
    
    private func loadArtCollection() {
        isLoading = true
        
        // Mock data - replace with Supabase query
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            artCollection = generateMockArt()
            isLoading = false
        }
    }
    
    private func loadPurchasedArt() {
        // Mock data - replace with Supabase query
        purchasedArtIds = ["art1", "art3", "art7"]
    }
    
    private func purchaseArt(_ art: AlbumArt) {
        // TODO: Implement Stripe/Lemon Squeezy payment
        // For now, mock the purchase
        purchasedArtIds.insert(art.id)
        showPurchaseConfirmation = true
        selectedArt = nil
    }
    
    private func generateMockArt() -> [AlbumArt] {
        return [
            AlbumArt(
                id: "art1",
                title: "Neon Dreams",
                tags: ["vaporwave", "purple", "dreamy", "retro"],
                thumbnailUrl: "",
                fullResUrl: "",
                price: 4.99,
                isFeatured: true,
                isLimited: false
            ),
            AlbumArt(
                id: "art2",
                title: "Digital Rain",
                tags: ["ambient", "blue", "minimal", "tech"],
                thumbnailUrl: "",
                fullResUrl: "",
                price: 7.99,
                isFeatured: false,
                isLimited: true
            ),
            AlbumArt(
                id: "art3",
                title: "Sunset Vibes",
                tags: ["lofi", "pink", "warm", "chill"],
                thumbnailUrl: "",
                fullResUrl: "",
                price: 5.99,
                isFeatured: true,
                isLimited: false
            ),
            AlbumArt(
                id: "art4",
                title: "Glitch City",
                tags: ["glitch", "green", "experimental", "dark"],
                thumbnailUrl: "",
                fullResUrl: "",
                price: 9.99,
                isFeatured: false,
                isLimited: true
            ),
            AlbumArt(
                id: "art5",
                title: "Abstract Flow",
                tags: ["house", "vibrant", "colorful", "energetic"],
                thumbnailUrl: "",
                fullResUrl: "",
                price: 6.99,
                isFeatured: false,
                isLimited: false
            ),
            AlbumArt(
                id: "art6",
                title: "Monochrome",
                tags: ["minimal", "monochrome", "clean", "modern"],
                thumbnailUrl: "",
                fullResUrl: "",
                price: 4.99,
                isFeatured: false,
                isLimited: false
            ),
            AlbumArt(
                id: "art7",
                title: "Trap Galaxy",
                tags: ["trap", "purple", "space", "dark"],
                thumbnailUrl: "",
                fullResUrl: "",
                price: 8.99,
                isFeatured: true,
                isLimited: false
            ),
            AlbumArt(
                id: "art8",
                title: "Ocean Waves",
                tags: ["ambient", "blue", "calm", "nature"],
                thumbnailUrl: "",
                fullResUrl: "",
                price: 5.99,
                isFeatured: false,
                isLimited: false
            ),
            AlbumArt(
                id: "art9",
                title: "Cyber Punk",
                tags: ["experimental", "red", "futuristic", "bold"],
                thumbnailUrl: "",
                fullResUrl: "",
                price: 11.99,
                isFeatured: false,
                isLimited: true
            ),
            AlbumArt(
                id: "art10",
                title: "Hip Hop Classic",
                tags: ["hip hop", "gold", "vintage", "classic"],
                thumbnailUrl: "",
                fullResUrl: "",
                price: 7.99,
                isFeatured: true,
                isLimited: false
            )
        ]
    }
}

// MARK: - Models
struct AlbumArt: Identifiable, Equatable {
    let id: String
    let title: String
    let tags: [String]
    let thumbnailUrl: String
    let fullResUrl: String
    let price: Double
    let isFeatured: Bool
    let isLimited: Bool
}

struct ArtFilters {
    var mood: String?
    var color: String?
    var genre: String?
    var priceRange: String?
}

// MARK: - Components
struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(isSelected ? .white : .gray)
                
                Rectangle()
                    .fill(isSelected ? Color.purple : Color.clear)
                    .frame(height: 3)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterMenu: View {
    let title: String
    let options: [String]
    let onSelect: (String) -> Void
    @State private var selectedOption = "All"
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selectedOption = option
                    onSelect(option)
                }) {
                    HStack {
                        Text(option)
                        if selectedOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .heavy))
                Text(selectedOption == "All" ? "" : selectedOption)
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .heavy))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
        }
    }
}

struct ArtCard: View {
    let art: AlbumArt
    let isPurchased: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Artwork preview
                ZStack {
                    // Placeholder gradient
                    LinearGradient(
                        colors: getGradientColors(),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .aspectRatio(1, contentMode: .fit)
                    
                    // Tags overlay
                    VStack {
                        HStack {
                            if art.isFeatured {
                                Label("FEATURED", systemImage: "star.fill")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple)
                                    .cornerRadius(12)
                            }
                            
                            if art.isLimited {
                                Label("LIMITED", systemImage: "hourglass")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red)
                                    .cornerRadius(12)
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        
                        Spacer()
                        
                        if isPurchased {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                                    .background(Circle().fill(Color.black).frame(width: 30, height: 30))
                                    .padding(12)
                            }
                        }
                    }
                }
                .cornerRadius(12)
                
                // Info section
                VStack(alignment: .leading, spacing: 8) {
                    Text(art.title)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Tags
                    HStack(spacing: 6) {
                        ForEach(art.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    
                    // Price
                    HStack {
                        if isPurchased {
                            Text("OWNED")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(.green)
                        } else {
                            Text("$\(String(format: "%.2f", art.price))")
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(.purple)
                        }
                        
                        Spacer()
                        
                        Text(isPurchased ? "USE" : "PREVIEW")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(isPurchased ? Color.green : Color.purple)
                            .cornerRadius(15)
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getGradientColors() -> [Color] {
        // Generate gradient based on tags
        if art.tags.contains("purple") {
            return [.purple, .pink]
        } else if art.tags.contains("blue") {
            return [.blue, .cyan]
        } else if art.tags.contains("green") {
            return [.green, .mint]
        } else if art.tags.contains("red") {
            return [.red, .orange]
        } else if art.tags.contains("monochrome") {
            return [.gray, .black]
        } else {
            return [.purple, .blue]
        }
    }
}

// MARK: - Art Detail View
struct ArtDetailView: View {
    let art: AlbumArt
    let isPurchased: Bool
    let onPurchase: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(art.title)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Spacer for balance
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                // Art preview
                LinearGradient(
                    colors: getGradientColors(),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(20)
                .padding(.horizontal, 40)
                
                // Art info
                VStack(spacing: 20) {
                    // Tags
                    HStack(spacing: 8) {
                        ForEach(art.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.3))
                                .cornerRadius(15)
                        }
                    }
                    
                    // License info
                    VStack(spacing: 12) {
                        Label("Full usage rights for Jamminverz", systemImage: "checkmark.shield.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                        
                        Text("Use in albums, profiles, and sample packs. Cannot resell or redistribute.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Purchase button
                    if isPurchased {
                        Button(action: onClose) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("OWNED - CLICK TO USE")
                            }
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.green)
                            .cornerRadius(30)
                        }
                        .padding(.horizontal, 40)
                    } else {
                        Button(action: onPurchase) {
                            HStack {
                                Text("PURCHASE")
                                Text("$\(String(format: "%.2f", art.price))")
                            }
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.purple)
                            .cornerRadius(30)
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .padding(.vertical, 30)
                
                Spacer()
            }
        }
    }
    
    private func getGradientColors() -> [Color] {
        if art.tags.contains("purple") {
            return [.purple, .pink]
        } else if art.tags.contains("blue") {
            return [.blue, .cyan]
        } else if art.tags.contains("green") {
            return [.green, .mint]
        } else if art.tags.contains("red") {
            return [.red, .orange]
        } else if art.tags.contains("monochrome") {
            return [.gray, .black]
        } else {
            return [.purple, .blue]
        }
    }
}

#Preview {
    ArtStoreView(
        taskStore: TaskStore(),
        currentTab: .constant("artstore")
    )
}