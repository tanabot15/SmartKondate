//
//  AppDelegate.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import UIKit
import UserNotifications
import CloudKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        // UNUserNotificationCenter のデリゲートを設定
        UNUserNotificationCenter.current().delegate = self
        
        // リモート通知の登録（APNs への登録）
        application.registerForRemoteNotifications()
        
        return true
    }

    // MARK: - APNs デバイス・トークン登録成功
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {

    }

    // MARK: - APNs デバイス・トークン登録失敗
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - CloudKit サイレントプッシュ通知（バックグラウンド同期）受信時
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // CloudKit からの通知かどうかを確認
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        
        if notification?.notificationType == .database {
            // SwiftData がバックグラウンドで CloudKit 変更データを同期するため、newData を返して完了を伝える
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }
}
