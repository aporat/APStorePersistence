import KeychainAccess
import StoreKit
import SwiftyStoreKit

public final class StorePersistence {
    public static let shared = StorePersistence()
    
    public var isSubscriptionActive = false
    private var transactions: [String]?
    
    private lazy var keychain: Keychain = {
        Keychain(service: "StorePersistence").accessibility(.afterFirstUnlock)
    }()
    
    private func loadTransactions() {
        if let data = try? keychain.getData("transactions"),
           let json = try? JSONSerialization.jsonObject(with: data, options: []),
           let transactions = json as? [String]
        {
            self.transactions = transactions
        } else {
            removeTransactions()
        }
    }
    
    public func saveTransactions() {
        if let currentTransactions = transactions {
            let jsonData = try? JSONSerialization.data(withJSONObject: currentTransactions, options: [])
            
            if let currentJsonData = jsonData {
                try? keychain.set(currentJsonData, key: "transactions")
            }
        }
    }
    
    public func removeTransactions() {
        try? keychain.remove("transactions")
        transactions = [String]()
    }
    
    public func saveProduct(_ productId: String) {
        if transactions == nil {
            transactions = [String]()
        }
        
        transactions?.append(productId)
        saveTransactions()
    }
    
    public func isPurchasedProduct(of identifier: String) -> Bool {
        if transactions == nil {
            loadTransactions()
        }
        
        if let currentTransactions = transactions, currentTransactions.contains(identifier) {
            return true
        }
        
        return false
    }
    
    // MARK: - StoreKit
    
    private(set) var products: [String: SKProduct] = [:]
    
    private func addProduct(_ product: SKProduct) {
        products[product.productIdentifier] = product
    }
    
    private func allProductsMatching(_ productIds: Set<String>) -> Set<SKProduct> {
        if products.count == 0 {
            return Set()
        }
        
        return Set(productIds.compactMap { self.products[$0] })
    }
    
    public func retrieveProductInfo(_ productId: String, completion: @escaping (_ retrievedProduct: SKProduct?) -> Void) {
        if productId.isEmpty {
            completion(nil)
            return
        }
        
        var productIds = Set<String>()
        productIds.insert(productId)
        
        retrieveProductsInfo(productIds) { retrievedProducts in
            completion(retrievedProducts.first)
        }
    }
    
    public func retrieveProductsInfo(_ productIds: Set<String>, completion: @escaping (_ retrievedProducts: Set<SKProduct>) -> Void) {
        if productIds.count == 0 {
            completion(Set())
            return
        }
        
        let products = allProductsMatching(productIds)
        
        guard products.count == productIds.count else {
            SwiftyStoreKit.retrieveProductsInfo(productIds) { [weak self] result in
                
                for product in result.retrievedProducts {
                    self?.addProduct(product)
                }
                
                completion(result.retrievedProducts)
            }
            
            return
        }
        
        completion(products)
    }
}
