import XCTest
@testable import APStorePersistence

final class StorePersistenceTests: XCTestCase {

    // MARK: - Test lifecycle

    override func setUp() async throws {
        try await MainActor.run {
            // Start each test with a clean slate
            StorePersistence.shared.removeTransactions()
            StorePersistence.shared.isSubscriptionActive = false
        }
    }

    override func tearDown() async throws {
        try await MainActor.run {
            StorePersistence.shared.removeTransactions()
            StorePersistence.shared.isSubscriptionActive = false
        }
    }

    // MARK: - Transactions (Keychain) tests

    @MainActor
    func testInitiallyNotPurchased() {
        XCTAssertFalse(StorePersistence.shared.isPurchasedProduct(of: "com.example.product1"))
    }

    @MainActor
    func testSaveAndLoadProductPersistsAcrossInstances() {
        let pid = "com.example.product1"

        // Save once
        StorePersistence.shared.saveProduct(pid)
        XCTAssertTrue(StorePersistence.shared.isPurchasedProduct(of: pid))

        // Simulate a fresh instance (ensures keychain persisted)
        let fresh = StorePersistence()
        XCTAssertTrue(fresh.isPurchasedProduct(of: pid))
    }

    @MainActor
    func testRemoveTransactionsClearsPurchases() {
        let pid = "com.example.product.remove-me"

        StorePersistence.shared.saveProduct(pid)
        XCTAssertTrue(StorePersistence.shared.isPurchasedProduct(of: pid))

        StorePersistence.shared.removeTransactions()
        XCTAssertFalse(StorePersistence.shared.isPurchasedProduct(of: pid))
    }

    @MainActor
    func testSavingDuplicateProductIsSafeAndStillPurchased() {
        let pid = "com.example.product.dup"

        StorePersistence.shared.saveProduct(pid)
        StorePersistence.shared.saveProduct(pid) // duplicate
        XCTAssertTrue(StorePersistence.shared.isPurchasedProduct(of: pid))

        // Another instance still sees it purchased (persists)
        let fresh = StorePersistence()
        XCTAssertTrue(fresh.isPurchasedProduct(of: pid))
    }

    // MARK: - Product retrieval guards (no network)

    func testRetrieveProductInfoWithEmptyIdReturnsNil() async {
        let exp = expectation(description: "Empty productId yields nil")
        Task { @MainActor in
            StorePersistence.shared.retrieveProductInfo("") { product in
                XCTAssertNil(product)
                exp.fulfill()
            }
        }
        await fulfillment(of: [exp], timeout: 2.0)
    }

    func testRetrieveProductsInfoWithEmptySetReturnsEmpty() async {
        let exp = expectation(description: "Empty productIds yields empty set")
        Task { @MainActor in
            StorePersistence.shared.retrieveProductsInfo([]) { products in
                XCTAssertTrue(products.isEmpty)
                exp.fulfill()
            }
        }
        await fulfillment(of: [exp], timeout: 2.0)
    }
}
