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
        let zoneID = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)
        let shareID = CKRecord.ID(recordName: "SmartKondateShare", zoneID: zoneID)
        
        // 既存の Share を取得・チェック
        if let existingShare = try? await privateDB.record(for: shareID) as? CKShare {
            return existingShare
        }
        
        // ルートレコードの準備
        let rootRecordID = CKRecord.ID(recordName: "KondatePatternRoot", zoneID: zoneID)
        let rootRecord: CKRecord
        if let fetched = try? await privateDB.record(for: rootRecordID) {
            rootRecord = fetched
        } else {
            rootRecord = CKRecord(recordType: "CD_KondatePattern", recordID: rootRecordID)
        }
        
        let share = CKShare(rootRecord: rootRecord, shareID: shareID)
        share[CKShare.SystemFieldKey.title] = "SmartKondate Family Share" as CKRecordValue
        
        share.publicPermission = .readWrite
        
        let operation = CKModifyRecordsOperation(recordsToSave: [rootRecord, share], recordIDsToDelete: nil)
        // サーバーにレコードが存在しない場合に新規作成を許可し、タグの不一致エラーを防ぐポリシー設定
        operation.savePolicy = .allKeys
        
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
    
    /// 共有 URL
    func acceptShare(url: URL) {
        let operation = CKFetchShareMetadataOperation(shareURLs: [url])
        operation.perShareMetadataResultBlock = { [weak self] shareURL, result in
            guard let self = self else { return }
            switch result {
            case .success(let metadata):
                let acceptOp = CKAcceptSharesOperation(shareMetadatas: [metadata])
                acceptOp.acceptSharesResultBlock = { acceptResult in
                    switch acceptResult {
                    case .success:
                        print("SmartKondate: 共有の受け入れに成功しました！")
                    case .failure(let error):
                        print("SmartKondate: 共有受諾エラー: \(error.localizedDescription)")
                    }
                }
                self.container.add(acceptOp)
            case .failure(let error):
                print("SmartKondate: Share Metadata 取得エラー: \(error.localizedDescription)")
            }
        }
        container.add(operation)
    }
}
