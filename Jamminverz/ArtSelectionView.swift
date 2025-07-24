//
//  ArtSelectionView.swift
//  Jamminverz
//
//  Art selection modal for album creation
//

import SwiftUI

struct ArtSelectionView: View {
    @Binding var selectedArtId: String?
    @Binding var coverArt: UIImage?
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var artManager = ArtStoreManager.shared
    @State private var selectedTab = "owned"
    @State private var showPurchaseFlow = false
    @State private var artToPurchase: AlbumArt?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tabs
                    HStack(spacing: 40) {
                        Button(action: { selectedTab = "owned" }) {
                            VStack(spacing: 8) {
                                Text("MY ART")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(selectedTab == "owned" ? .white : .gray)
                                
                                Rectangle()
                                    .fill(selectedTab == "owned" ? Color.blue : Color.clear)
                                    .frame(height: 3)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: { selectedTab = "gallery" }) {
                            VStack(spacing: 8) {
                                Text("GALLERY")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(selectedTab == "gallery" ? .white : .gray)
                                
                                Rectangle()
                                    .fill(selectedTab == "gallery" ? Color.blue : Color.clear)
                                    .frame(height: 3)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.05))
                    
                    // Content
                    if selectedTab == "owned" {
                        ownedArtView
                    } else {
                        galleryView
                    }
                }
            }
            .navigationTitle("Select Album Art")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            _Concurrency.Task {
                await artManager.fetchArtCollection()
                // TODO: Get actual user ID
                await artManager.fetchPurchasedArt(for: "current-user-id")
            }
        }
        .sheet(item: $artToPurchase) { art in
            ArtPurchaseView(
                art: art,
                onPurchaseComplete: {
                    artManager.purchasedArtIds.insert(art.id)
                    selectArt(art)
                }
            )
        }
    }
    
    private var ownedArtView: some View {
        Group {
            if ownedArt.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "photo.artframe")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Purchased Art Yet")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text("Browse the gallery to purchase album art")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        selectedTab = "gallery"
                    }) {
                        Text("BROWSE GALLERY")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(Color.purple)
                            .cornerRadius(30)
                    }
                }
                .padding(.top, 100)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(ownedArt) { art in
                            ArtSelectionCard(
                                art: art,
                                isSelected: selectedArtId == art.id,
                                onTap: { selectArt(art) }
                            )
                        }
                    }
                    .padding(24)
                }
            }
        }
    }
    
    private var galleryView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(artManager.artCollection) { art in
                    if artManager.purchasedArtIds.contains(art.id) {
                        ArtSelectionCard(
                            art: art,
                            isSelected: selectedArtId == art.id,
                            onTap: { selectArt(art) }
                        )
                    } else {
                        ArtSelectionCard(
                            art: art,
                            isSelected: false,
                            isPurchasable: true,
                            onTap: { artToPurchase = art }
                        )
                    }
                }
            }
            .padding(24)
        }
    }
    
    private var ownedArt: [AlbumArt] {
        artManager.artCollection.filter { art in
            artManager.purchasedArtIds.contains(art.id)
        }
    }
    
    private func selectArt(_ art: AlbumArt) {
        selectedArtId = art.id
        // TODO: Load actual image from URL
        // For now, create a placeholder image
        coverArt = createPlaceholderImage(for: art)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func createPlaceholderImage(for art: AlbumArt) -> UIImage {
        // Create a gradient placeholder based on art tags
        let size = CGSize(width: 500, height: 500)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let colors = getGradientColors(for: art)
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors.map { UIColor($0).cgColor } as CFArray,
                locations: nil
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }
    }
    
    private func getGradientColors(for art: AlbumArt) -> [Color] {
        if art.tags.contains("purple") {
            return [.purple, .pink]
        } else if art.tags.contains("blue") {
            return [.blue, .cyan]
        } else if art.tags.contains("green") {
            return [.green, .mint]
        } else if art.tags.contains("red") {
            return [.red, .orange]
        } else {
            return [.purple, .blue]
        }
    }
}

// MARK: - Art Selection Card
struct ArtSelectionCard: View {
    let art: AlbumArt
    let isSelected: Bool
    var isPurchasable: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Art preview
                ZStack {
                    LinearGradient(
                        colors: getGradientColors(),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .aspectRatio(1, contentMode: .fit)
                    
                    if isSelected {
                        Color.white.opacity(0.3)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    if isPurchasable {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("$\(String(format: "%.2f", art.price))")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.purple)
                                    .cornerRadius(15)
                                    .padding(8)
                            }
                        }
                    }
                }
                .cornerRadius(12)
                
                // Title
                Text(art.title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(isSelected ? .purple : .white)
                    .lineLimit(1)
                    .padding(.top, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
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
        } else {
            return [.purple, .blue]
        }
    }
}

// MARK: - Art Purchase View
struct ArtPurchaseView: View {
    let art: AlbumArt
    let onPurchaseComplete: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var paymentManager = PaymentManager.shared
    @State private var isPurchasing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
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
                    VStack(spacing: 16) {
                        Text(art.title)
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Text("$\(String(format: "%.2f", art.price))")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.purple)
                    }
                    
                    // License info
                    VStack(spacing: 12) {
                        Label("Full usage rights for Jamminverz", systemImage: "checkmark.shield.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                        
                        Text("Use in albums, profiles, and sample packs")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Purchase button
                    Button(action: purchaseArt) {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(height: 60)
                        } else {
                            Text("PURCHASE NOW")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(Color.purple)
                                .cornerRadius(30)
                        }
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Purchase Art")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .onChange(of: paymentManager.purchaseResult) { _, result in
            if case .success = result {
                onPurchaseComplete()
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func purchaseArt() {
        isPurchasing = true
        
        _Concurrency.Task {
            // TODO: Get actual user ID
            await paymentManager.purchaseArtWithStoreKit(art, userId: "current-user-id")
            isPurchasing = false
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
        } else {
            return [.purple, .blue]
        }
    }
}


#Preview {
    ArtSelectionView(
        selectedArtId: .constant(nil),
        coverArt: .constant(nil)
    )
}