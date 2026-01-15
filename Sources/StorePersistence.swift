import Foundation
import StoreKit
import KeychainAccess
@preconcurrency import SwiftyStoreKit

/// Thread-safe persistence layer for StoreKit purchases and subscription state.
/// Uses an actor to ensure Swift 6 concurrency safety.
public actor StorePersistence {
    public static let shared = StorePersistence()
    
    // MARK: - State
    
    public private(set) var isSubscriptionActive = false
    private var transactions: [String]?
    private var products: [String: SKProduct] = [:]
    
    // MARK: - Constants
    
    private enum Const {
        static let keychainService = "StorePersistence"
        static let transactionsKey = "transactions"
    }
    
    private let keychain: Keychain
    
    // MARK: - Initialization
    
    private init() {
        self.keychain = Keychain(service: Const.keychainService)
            .accessibility(.afterFirstUnlock)
    }
    
    // MARK: - Subscription Status
    
    public func setSubscriptionActive(_ isActive: Bool) {
        isSubscriptionActive = isActive
    }
    
    // MARK: - Transactions (Keychain)
    
    private func ensureTransactionsLoaded() {
        guard transactions == nil else { return }
        loadTransactions()
    }
    
    private func loadTransactions() {
        guard
            let data = try? keychain.getData(Const.transactionsKey),
            let json = try? JSONSerialization.jsonObject(with: data),
            let arr = json as? [String]
        else {
            transactions = []
            return
        }
        transactions = arr
    }
    
    public func saveTransactions() {
        guard let current = transactions else { return }
        if let data = try? JSONSerialization.data(withJSONObject: current) {
            try? keychain.set(data, key: Const.transactionsKey)
        }
    }
    
    public func removeTransactions() {
        try? keychain.remove(Const.transactionsKey)
        transactions = []
    }
    
    public func saveProduct(_ productId: String) {
        guard !productId.isEmpty else { return }
        ensureTransactionsLoaded()
        if transactions?.contains(productId) != true {
            transactions?.append(productId)
            saveTransactions()
        }
    }
    
    public func isPurchasedProduct(of identifier: String) -> Bool {
        guard !identifier.isEmpty else { return false }
        ensureTransactionsLoaded()
        return transactions?.contains(identifier) == true
    }
    
    // MARK: - StoreKit Products
    
    private func addProduct(_ product: SKProduct) {
        products[product.productIdentifier] = product
    }
    
    private func cachedProducts(matching productIds: Set<String>) -> Set<SKProduct> {
        guard !products.isEmpty else { return [] }
        return Set(productIds.compactMap { products[$0] })
    }
    
    /// Retrieves a single product, using cache if available.
    public func retrieveProductInfo(_ productId: String) async -> SKProduct? {
        guard !productId.isEmpty else { return nil }
        let products = await retrieveProductsInfo([productId])
        return products.first
    }
    
    /// Retrieves multiple products, using cache when possible.
    public func retrieveProductsInfo(_ productIds: Set<String>) async -> Set<SKProduct> {
        guard !productIds.isEmpty else { return [] }
        
        // Return cached immediately if all present
        let cached = cachedProducts(matching: productIds)
        if cached.count == productIds.count {
            return cached
        }
        
        // Fetch missing products
        let missing = productIds.subtracting(cached.map(\.productIdentifier))
        guard !missing.isEmpty else {
            return cached
        }
        
        let retrieved = await retrieveFromStoreKit(missing)
        
        // Cache newly retrieved products
        for product in retrieved {
            addProduct(product)
        }
        
        return cached.union(retrieved)
    }
    
    private func retrieveFromStoreKit(_ productIds: Set<String>) async -> Set<SKProduct> {
        await withCheckedContinuation { continuation in
            SwiftyStoreKit.retrieveProductsInfo(productIds) { result in
                continuation.resume(returning: result.retrievedProducts)
            }
        }
    }
}
