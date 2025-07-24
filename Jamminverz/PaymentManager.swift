//
//  PaymentManager.swift
//  Jamminverz
//
//  Handles payments for album art using Stripe/Lemon Squeezy
//

import Foundation
import StoreKit
import SwiftUI

class PaymentManager: ObservableObject {
    static let shared = PaymentManager()
    
    @Published var isProcessing = false
    @Published var purchaseResult: PurchaseResult?
    
    // MARK: - Stripe Configuration
    private let stripePublishableKey = "YOUR_STRIPE_PUBLISHABLE_KEY"
    private let stripeBackendUrl = "YOUR_BACKEND_URL"
    
    // MARK: - Purchase Art with Stripe
    func purchaseArtWithStripe(_ art: AlbumArt, userId: String) async {
        isProcessing = true
        
        do {
            // 1. Create payment intent on backend
            let _ = try await createPaymentIntent(for: art, userId: userId)
            
            // 2. Present Stripe payment sheet
            // Note: In a real implementation, you'd use StripePaymentSheet
            // For now, we'll simulate the payment
            try await simulatePayment()
            
            // 3. Record purchase in database
            try await ArtStoreManager.shared.purchaseArt(art, userId: userId)
            
            await MainActor.run {
                self.purchaseResult = .success(art)
                self.isProcessing = false
            }
        } catch {
            await MainActor.run {
                self.purchaseResult = .failure(error)
                self.isProcessing = false
            }
        }
    }
    
    // MARK: - In-App Purchase with StoreKit
    func purchaseArtWithStoreKit(_ art: AlbumArt, userId: String) async {
        isProcessing = true
        
        do {
            // Request products from App Store
            let products = try await Product.products(for: [art.storeKitProductId])
            guard let product = products.first else {
                throw PaymentError.productNotFound
            }
            
            // Purchase the product
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Verify the transaction
                switch verification {
                case .verified(let transaction):
                    // Record purchase in database
                    try await ArtStoreManager.shared.purchaseArt(art, userId: userId)
                    
                    // Finish the transaction
                    await transaction.finish()
                    
                    await MainActor.run {
                        self.purchaseResult = .success(art)
                        self.isProcessing = false
                    }
                    
                case .unverified:
                    throw PaymentError.verificationFailed
                }
                
            case .userCancelled:
                await MainActor.run {
                    self.purchaseResult = .cancelled
                    self.isProcessing = false
                }
                
            case .pending:
                await MainActor.run {
                    self.purchaseResult = .pending
                    self.isProcessing = false
                }
                
            @unknown default:
                throw PaymentError.unknownError
            }
        } catch {
            await MainActor.run {
                self.purchaseResult = .failure(error)
                self.isProcessing = false
            }
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        do {
            // Restore StoreKit purchases
            try await AppStore.sync()
            
            // Get all verified transactions
            var collectedArtIds: Set<String> = []
            
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    collectedArtIds.insert(transaction.productID)
                }
            }
            
            let finalArtIds = collectedArtIds
            await MainActor.run {
                // Update local state with restored purchases
                ArtStoreManager.shared.purchasedArtIds = finalArtIds
            }
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
    
    // MARK: - Private Methods
    private func createPaymentIntent(for art: AlbumArt, userId: String) async throws -> PaymentIntent {
        // Create payment intent on your backend
        // This is a simplified example
        let url = URL(string: "\(stripeBackendUrl)/create-payment-intent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "amount": Int(art.price * 100), // Convert to cents
            "currency": "usd",
            "metadata": [
                "art_id": art.id,
                "user_id": userId
            ]
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let paymentIntent = try JSONDecoder().decode(PaymentIntent.self, from: data)
        
        return paymentIntent
    }
    
    private func simulatePayment() async throws {
        // Simulate payment processing delay
        try? await _Concurrency.Task.sleep(nanoseconds: 2_000_000_000)
        
        // Randomly succeed or fail for demo purposes
        if Bool.random() {
            return
        } else {
            throw PaymentError.paymentFailed
        }
    }
}

// MARK: - Models
struct PaymentIntent: Codable {
    let clientSecret: String
    let publishableKey: String
}

enum PurchaseResult: Equatable {
    case success(AlbumArt)
    case failure(Error)
    case cancelled
    case pending
    
    static func == (lhs: PurchaseResult, rhs: PurchaseResult) -> Bool {
        switch (lhs, rhs) {
        case (.success(let lhsArt), .success(let rhsArt)):
            return lhsArt.id == rhsArt.id
        case (.failure, .failure):
            return true
        case (.cancelled, .cancelled):
            return true
        case (.pending, .pending):
            return true
        default:
            return false
        }
    }
}

enum PaymentError: LocalizedError {
    case productNotFound
    case verificationFailed
    case paymentFailed
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found in the store"
        case .verificationFailed:
            return "Purchase verification failed"
        case .paymentFailed:
            return "Payment processing failed"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

// MARK: - StoreKit Product ID Extension
extension AlbumArt {
    var storeKitProductId: String {
        // Map art IDs to StoreKit product IDs
        return "com.jamminverz.art.\(id)"
    }
}

// MARK: - Lemon Squeezy Integration (Alternative)
extension PaymentManager {
    func purchaseArtWithLemonSqueezy(_ art: AlbumArt, userId: String) async {
        isProcessing = true
        
        do {
            // Create checkout URL
            let checkoutUrl = try await createLemonSqueezyCheckout(for: art, userId: userId)
            
            // Open checkout in browser or web view
            await MainActor.run {
                if let url = URL(string: checkoutUrl) {
                    #if os(macOS)
                    NSWorkspace.shared.open(url)
                    #else
                    UIApplication.shared.open(url)
                    #endif
                }
            }
            
            // Poll for completion or use webhook
            // For now, we'll simulate success after delay
            try? await _Concurrency.Task.sleep(nanoseconds: 5_000_000_000)
            
            // Record purchase
            try await ArtStoreManager.shared.purchaseArt(art, userId: userId)
            
            await MainActor.run {
                self.purchaseResult = .success(art)
                self.isProcessing = false
            }
        } catch {
            await MainActor.run {
                self.purchaseResult = .failure(error)
                self.isProcessing = false
            }
        }
    }
    
    private func createLemonSqueezyCheckout(for art: AlbumArt, userId: String) async throws -> String {
        // Create checkout session with Lemon Squeezy API
        // This is a simplified example
        return "https://jamminverz.lemonsqueezy.com/checkout/buy/\(art.id)?user_id=\(userId)"
    }
}