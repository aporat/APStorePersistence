# APStorePersistence

A lightweight Swift package for persisting and querying **in-app purchase states** using **Keychain** and **SwiftyStoreKit**.  
It provides a simple interface to save purchased product IDs, check if a product was purchased, and fetch `SKProduct` info with caching.

---

## Features

- 🔐 Secure persistence of transactions in Keychain  
- ✅ Track if a product has been purchased  
- 🗑️ Clear / reset stored transactions  
- 📦 Cache and reuse `SKProduct` objects  
- 🔄 Fetch product info with SwiftyStoreKit  

---

## Installation

Add `APStorePersistence` as a dependency in your `Package.swift`:

```swift
.package(url: "https://github.com/yourusername/APStorePersistence.git", from: "1.0.0")
```

and include it in your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["APStorePersistence"]
)
```

---

## Usage

### Saving a Purchase

```swift
import APStorePersistence

// Save a purchased product
StorePersistence.shared.saveProduct("com.example.premium")
```

### Checking if Product is Purchased

```swift
if StorePersistence.shared.isPurchasedProduct(of: "com.example.premium") {
    print("Premium is unlocked 🎉")
}
```

### Removing Transactions

```swift
StorePersistence.shared.removeTransactions()
```

### Fetching Product Info

```swift
StorePersistence.shared.retrieveProductInfo("com.example.premium") { product in
    if let product = product {
        print("Price: \(product.priceLocale.currencySymbol ?? "")\(product.price)")
    }
}
```

Or fetch multiple:

```swift
let ids: Set<String> = ["com.example.premium", "com.example.gold"]
StorePersistence.shared.retrieveProductsInfo(ids) { products in
    for product in products {
        print("Loaded: \(product.productIdentifier)")
    }
}
```

---

## Requirements

- iOS 12+ / tvOS 12+ / watchOS 4+ / macOS 10.13+  
- Swift 5.9 / Swift 6

---

## License

MIT License. See [LICENSE](LICENSE) for details.
