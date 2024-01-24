//
//  Bill+Extras.swift
//  BillManager
//

import Foundation
import UserNotifications

extension Bill {
    var hasReminder: Bool {
        return (remindDate != nil)
    }
    
    var isPaid: Bool {
        return (paidDate != nil)
    }
    
    var formattedDueDate: String {
        let dateString: String
        
        if let dueDate = self.dueDate {
            dateString = dueDate.formatted(date: .numeric, time: .omitted)
        } else {
            dateString = ""
        }
        
        return dateString
    }
    
    mutating func removeReminders() {
        if let id = notificationID {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            notificationID = nil
            remindDate = nil
        }
    }
    
    mutating func scheduleReminder(setDate: Date, completion: @escaping ((Bill) -> ())) {
        var updatedBill = self
        
        updatedBill.removeReminders()
        
        authorizeIfNeeded { granted in
            guard granted else {
                DispatchQueue.main.async {
                    completion(updatedBill)
                }
                
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Bill Reminder"
            content.body = String(format: "$%.2f due to %@ on %@", arguments: [updatedBill.amount ?? 0, (updatedBill.payee ?? ""), updatedBill.formattedDueDate])
            content.sound = UNNotificationSound.default
            content.categoryIdentifier = Bill.notificationCategoryID
            
            let triggerDateComponents = Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: setDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
            
            let notificationID = UUID().uuidString
            
            let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        updatedBill.notificationID = notificationID
                        updatedBill.remindDate = setDate
                    }
                    DispatchQueue.main.async {
                        completion(updatedBill)
                    }
                }
            }
            
            
            
            
        }
    }
    
    private func authorizeIfNeeded(completion: @escaping (Bool) -> ()) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .notDetermined:
                notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    completion(granted)
                }
            case .denied, .provisional, .ephemeral:
                completion(false)
            case .authorized:
                completion(true)
            @unknown default:
                completion(false)
            }
        }
    }
    
}
