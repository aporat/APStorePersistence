import Foundation
import StoreKit
import KeychainAccess
import SwiftyStoreKit

@MainActor
public final class StorePersistence {
    public static let shared = StorePersistence()

    public var isSubscriptionActive = false
    private var transactions: [String]?   // lazily loaded

    // MARK: - Constants
    private enum Const {
        static let keychainService = "StorePersistence"
        static let transactionsKey = "transactions"
    }

    private lazy var keychain: Keychain = {
        Keychain(service: Const.keychainService).accessibility(.afterFirstUnlock)
    }()

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

    // MARK: - StoreKit (cached products)

    private(set) var products: [String: SKProduct] = [:]

    private func addProduct(_ product: SKProduct) {
        products[product.productIdentifier] = product
    }

    private func cachedProducts(matching productIds: Set<String>) -> Set<SKProduct> {
        guard !products.isEmpty else { return [] }
        return Set(productIds.compactMap { products[$0] })
    }

    public func retrieveProductInfo(
        _ productId: String,
        completion: @escaping (_ retrievedProduct: SKProduct?) -> Void
    ) {
        guard !productId.isEmpty else { completion(nil); return }
        retrieveProductsInfo([productId]) { completion($0.first) }
    }

    public func retrieveProductsInfo(
        _ productIds: Set<String>,
        completion: @escaping (_ retrievedProducts: Set<SKProduct>) -> Void
    ) {
        guard !productIds.isEmpty else { completion([]); return }

        // Return cached immediately if all present; otherwise fetch only the missing IDs.
        let cached = cachedProducts(matching: productIds)
        if cached.count == productIds.count {
            completion(cached)
            return
        }

        let missing = productIds.subtracting(cached.map(\.productIdentifier))
        guard !missing.isEmpty else {
            completion(cached)
            return
        }

        SwiftyStoreKit.retrieveProductsInfo(missing) { [weak self] result in
            guard let self else {
                completion(cached.union(result.retrievedProducts))
                return
            }
            for product in result.retrievedProducts {
                self.addProduct(product)
            }
            completion(cached.union(result.retrievedProducts))
        }
    }
}
