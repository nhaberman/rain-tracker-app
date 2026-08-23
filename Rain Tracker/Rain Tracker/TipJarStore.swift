import StoreKit

enum TipPurchaseState: Equatable {
    case idle
    case purchasing
    case success
    case pending
    case failed(String)
}

@MainActor
@Observable
final class TipJarStore {
    static let productIDs = [
        "nickhaberman.Rain_Tracker.tip.small",
        "nickhaberman.Rain_Tracker.tip.medium",
        "nickhaberman.Rain_Tracker.tip.large",
    ]

    private(set) var products: [Product] = []
    private(set) var isLoadingProducts = true
    var purchaseState: TipPurchaseState = .idle

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let storeProducts = try await Product.products(for: Self.productIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            purchaseState = .failed("Couldn't load tip options. Check your connection and try again.")
        }
    }

    func purchase(_ product: Product) async {
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    purchaseState = .success
                case .unverified:
                    purchaseState = .failed("Purchase could not be verified.")
                }
            case .pending:
                purchaseState = .pending
            case .userCancelled:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    static func observeTransactionUpdates() async {
        for await verification in Transaction.updates {
            if case .verified(let transaction) = verification {
                await transaction.finish()
            }
        }
    }
}
