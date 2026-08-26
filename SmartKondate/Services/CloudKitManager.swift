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
    
    let container: CKContainer
    
    init(containerIdentifier: String = "iCloud.com.suzuki.kenichiro.SmaKon") {
        self.container = CKContainer(identifier: containerIdentifier)
        checkAccountStatus()
    }
    
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
    
    /// SwiftData ゾーン内に CKShare を作成して保存する
    func prepareShare() async throws -> CKShare {
        let privateDB = container.privateCloudDatabase
        
        // SwiftData が標準で使用するゾーン ID
        let zoneID = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)
        
        // 既存の CKShare レコードの有無を確認
        let shareID = CKRecord.ID(recordName: "SmartKondateShare", zoneID: zoneID)
        if let existingShare = try? await privateDB.record(for: shareID) as? CKShare {
            return existingShare
        }
        
        // 1. ルートレコードの作成
        let rootRecordID = CKRecord.ID(recordName: "KondatePatternRoot", zoneID: zoneID)
        
        // サーバー上に既存のルートレコードがあるか確認し、なければ新規作成
        let rootRecord: CKRecord
        if let fetchedRecord = try? await privateDB.record(for: rootRecordID) {
            rootRecord = fetchedRecord
        } else {
            rootRecord = CKRecord(recordType: "CD_KondatePattern", recordID: rootRecordID)
        }
        
        // 2. CKShare の作成と公開パーミッションの設定（重要）
        let share = CKShare(rootRecord: rootRecord)
        share[CKShare.SystemFieldKey.title] = "SmartKondate Family Share" as CKRecordValue
        share[CKShare.SystemFieldKey.shareType] = "com.suzuki.kenichiro.SmaKon.share" as CKRecordValue
        
        // リンクを知っている非公開メンバーのみアクセス可能（または none）
        share.publicPermission = .none
        
        // 3. ルートレコードと Share を一括で保存
        let operation = CKModifyRecordsOperation(recordsToSave: [rootRecord, share], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: share)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            privateDB.add(operation)
        }
    }
}
