//
//  UnlockManager.swift
//  dime
//
//  Created by Rafael Soh on 15/9/22.
//

import Foundation
import StoreKit

class UnlockManager: NSObject, ObservableObject, SKPaymentTransactionObserver, SKProductsRequestDelegate {
    enum RequestState {
        case loading
        case loaded
        case failed
    }

    var canMakePayments: Bool {
        SKPaymentQueue.canMakePayments()
    }

    private enum StoreError: Error {
        case invalidIdentifiers, missingProduct
    }

    @Published var requestState = RequestState.loading
    @Published var purchaseCount: Int
    @Published var failedTransaction = false

    private let dataController: DataController
    private let request: SKProductsRequest

    var loadedProducts = [SKProduct]()

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        DispatchQueue.main.async { [self] in
            for transaction in transactions {
                switch transaction.transactionState {
                case .purchased, .restored:

                    self.purchaseCount += 1
                    self.dataController.tipCounter = purchaseCount
                    queue.finishTransaction(transaction)

                case .failed:
                    self.failedTransaction = true
                    queue.finishTransaction(transaction)
                    revertBool()
                default:
                    break
                }
            }
        }
    }

    func productsRequest(_: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            // Store the returned products for later, if we need them.
            self.loadedProducts = response.products

            guard !self.loadedProducts.isEmpty else {
                self.requestState = .failed
                return
            }

            if response.invalidProductIdentifiers.isEmpty == false {
                print("ALERT: Received invalid product identifiers: \(response.invalidProductIdentifiers)")
                self.requestState = .failed
                return
            }

            self.requestState = .loaded
        }
    }

    func buy(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    func revertBool() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.failedTransaction = false
        }
    }

    func restore() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    init(dataController: DataController) {
        // Store the data controller we were sent.
        self.dataController = dataController

        // Prepare to look for our unlock product.
        let productIDs = Set(["com.rafaelsoh.dime.smalltip", "com.rafaelsoh.dime.mediumtip", "com.rafaelsoh.dime.largetip"])
        request = SKProductsRequest(productIdentifiers: productIDs)

        // This is required because we inherit from NSObject.
        purchaseCount = dataController.tipCounter

        super.init()

        // Start watching the payment queue.
        SKPaymentQueue.default().add(self)

        // Set ourselves up to be notified when the product request completes.
        request.delegate = self

        // Start the request
        request.start()
    }

    deinit {
        SKPaymentQueue.default().remove(self)
    }
}
