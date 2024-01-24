//
//  AppDelegate.swift
//  BillManager
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let notificationID = response.notification.request.identifier
        guard var bill = Database.shared.getBill(forNotificationID: notificationID) else { completionHandler(); return }
        
        switch response.actionIdentifier {
        case "hourReminder":
            let newRemindDate = Date().addingTimeInterval(60 * 60)
            
            bill.scheduleReminder(setDate: newRemindDate) { updatedBill in
                Database.shared.updateAndSave(updatedBill)
            }
        case "billPaid":
            bill.paidDate = Date()
            Database.shared.updateAndSave(bill)
        default:
            break
        }
        
        completionHandler()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let center = UNUserNotificationCenter.current()
        
        let hourlyReminderAction = UNNotificationAction(identifier: "hourReminder", title: "Remind Me In 1 Hour", options: [])
        
        let billPaidAction = UNNotificationAction(identifier: "billPaid", title: "Bill Has Been Paid", options: [.authenticationRequired])
        
        let billCategory = UNNotificationCategory(identifier: Bill.notificationCategoryID, actions: [hourlyReminderAction, billPaidAction], intentIdentifiers: [], options: [])
        
        center.setNotificationCategories([billCategory])
        center.delegate = self
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

