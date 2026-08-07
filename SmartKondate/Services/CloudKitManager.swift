//
//  CloudKitManager.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import Foundation
import CloudKit
import SwiftUI

@Observable
final class CloudKitManager {
    static let shared = CloudKitManager()
    
    var accountStatus: CKAccountStatus = .couldNotDetermine
    var errorMessage: String?
    
    private let container: CKContainer
    
    init(containerIdentifier: String = "iCloud.com.example.SmartKondate") {
        self.container = CKContainer(identifier: containerIdentifier)
        checkAccountStatus()
    }
    
    /// iCloud サインイン状態の確認
    func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
                self?.accountStatus = status
            }
        }
    }
    
    /// 共有ゾーンと CKShare の準備
    func prepareShare() async throws -> CKShare {
        let zoneID = CKRecordZone.ID(zoneName: "SmartKondateZone", ownerName: CKCurrentUserDefaultName)
        let share = CKShare(recordZoneID: zoneID)
        share[CKShare.SystemFieldKey.title] = "SmartKondate Family Share" as CKRecordValue
        return share
    }
}
