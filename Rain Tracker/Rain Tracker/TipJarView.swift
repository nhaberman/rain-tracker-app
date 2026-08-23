import SwiftUI
import StoreKit

struct TipJarView: View {
    @State private var store = TipJarStore()

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enjoying Rain Tracker?")
                        .font(.headline)
                    Text("Rain Tracker is free with no ads or subscriptions. If it's been useful, a tip is always appreciated — thank you!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                if store.isLoadingProducts {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    ForEach(store.products) { product in
                        Button {
                            Task { await store.purchase(product) }
                        } label: {
                            HStack {
                                Text(product.displayName)
                                Spacer()
                                Text(product.displayPrice)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(store.purchaseState == .purchasing)
                    }
                }
            }

            if case .failed(let message) = store.purchaseState {
                Section {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }

            if store.purchaseState == .pending {
                Section {
                    Text("Your tip is awaiting approval.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Tip Jar")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.loadProducts()
        }
        .alert("Thank You!", isPresented: Binding(
            get: { store.purchaseState == .success },
            set: { if !$0 { store.purchaseState = .idle } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your support means a lot. Thanks for tipping!")
        }
    }
}

#Preview {
    NavigationStack {
        TipJarView()
    }
}
