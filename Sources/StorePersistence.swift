import Foundation
import StoreKit
import KeychainAccess
import SwiftyStoreKit

@MainActor
public final class StorePersistence {
    public static let shared = StorePersistence()

    public var isSubscriptionActive = false
    private var transactions: [String]?

    // MARK: - Constants
    private enum Const {
        static let keychainService = "StorePersistence"
        static let transactionsKey = "transactions"
    }

    private lazy var keychain: Keychain = {
        Keychain(service: Const.keychainService).accessibility(.afterFirstUnlock)
    }()

    // MARK: - Transactions (Keychain)

    private func loadTransactions() {
        guard
            let data = try? keychain.getData(Const.transactionsKey),
            let json = try? JSONSerialization.jsonObject(with: data, options: []),
            let arr = json as? [String]
        else {
            // No stored data yet; keep an empty in-memory cache without writing.
            transactions = []
            return
        }
        transactions = arr
    }

    public func saveTransactions() {
        guard let current = transactions else { return }
        if let data = try? JSONSerialization.data(withJSONObject: current, options: []) {
            try? keychain.set(data, key: Const.transactionsKey)
        }
    }

    public func removeTransactions() {
        try? keychain.remove(Const.transactionsKey)
        transactions = []
    }

    public func saveProduct(_ productId: String) {
        if transactions == nil { loadTransactions() }
        // Avoid duplicates
        if transactions?.contains(productId) != true {
            transactions?.append(productId)
            saveTransactions()
        }
    }

    public func isPurchasedProduct(of identifier: String) -> Bool {
        if transactions == nil { loadTransactions() }
        return transactions?.contains(identifier) == true
    }

    // MARK: - StoreKit (cached products)

    private(set) var products: [String: SKProduct] = [:]

    private func addProduct(_ product: SKProduct) {
        products[product.productIdentifier] = product
    }

    private func allProductsMatching(_ productIds: Set<String>) -> Set<SKProduct> {
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

        let cached = allProductsMatching(productIds)
        guard cached.count != productIds.count else {
            completion(cached)
            return
        }

        SwiftyStoreKit.retrieveProductsInfo(productIds) { [weak self] result in
            for product in result.retrievedProducts {
                self?.addProduct(product)
            }
            completion(result.retrievedProducts)
        }
    }
}
