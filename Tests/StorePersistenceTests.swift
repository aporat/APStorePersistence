import XCTest
@testable import APStorePersistence

final class StorePersistenceTests: XCTestCase {

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await MainActor.run {
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

    // MARK: - Transactions (Keychain)

    @MainActor
    func testInitiallyNotPurchased() {
        XCTAssertFalse(StorePersistence.shared.isPurchasedProduct(of: "com.example.product1"))
    }

    @MainActor
    func testSaveProductIgnoresEmptyIdentifier() {
        StorePersistence.shared.saveProduct("")
        XCTAssertFalse(StorePersistence.shared.isPurchasedProduct(of: ""))
    }

    @MainActor
    func testIsPurchasedProductWithEmptyIdentifierIsFalse() {
        XCTAssertFalse(StorePersistence.shared.isPurchasedProduct(of: ""))
    }

    // MARK: - Product retrieval guard paths (no network)

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
