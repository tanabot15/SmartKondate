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
    
    // 外部からコンテナを取得できるように public / internal に設定
    let container: CKContainer
    
    init(containerIdentifier: String = "iCloud.com.suzuki.kenichiro.SmaKon") {
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
    
    /// 共有ゾーンと CKShare を作成し、CloudKit サーバーへ保存して返す
    func prepareShare() async throws -> CKShare {
        let privateDB = container.privateCloudDatabase
        let zoneID = CKRecordZone.ID(zoneName: "SmartKondateZone", ownerName: CKCurrentUserDefaultName)
        let zone = CKRecordZone(zoneID: zoneID)
        
        // 1. カスタムゾーンを保存（既存の場合はそのまま取得）
        try await privateDB.save(zone)
        
        // 2. ゾーン内にルートとなるレコードと CKShare を作成
        let rootRecord = CKRecord(recordType: "KondateRoot", recordID: CKRecord.ID(recordName: "RootRecord", zoneID: zoneID))
        let share = CKShare(rootRecord: rootRecord)
        share[CKShare.SystemFieldKey.title] = "SmartKondate Family Share" as CKRecordValue
        
        // 3. ルートレコードと Share をサーバーへ保存（一括書き込み）
        let operation = CKModifyRecordsOperation(recordsToSave: [rootRecord, share], recordIDsToDelete: nil)
        
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
