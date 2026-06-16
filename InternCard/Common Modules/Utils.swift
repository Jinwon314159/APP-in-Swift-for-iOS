//
//  Utills.swift
//  InternCard
//
//  Created by idl on 2018. 10. 18..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import Foundation
import Charts


class Utils {
    
    static func base64_encode(text: String) -> String {
        return Data(text.utf8).base64EncodedString()
    }
    
    static func base64_decode(encoded: String) -> String {
        let decoded: Data = Data(base64Encoded: encoded)!
        return String(data: decoded, encoding: .utf8)!
    }
    
    static func json(any object: Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
    static func dictionary(json text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try (JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])!
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    static func dictionary_array(json text: String) -> [[String: Any]]? {
        if let data = text.data(using: .utf8) {
            do {
                return try (JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]])!
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }

}

class HourValueFormatter: NSObject, IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return String(Int(value)) + "h"
    }
}

class DayValueFormatter: NSObject, IAxisValueFormatter {
    
    var label_x: [TimeInterval] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    
    func stringForValue(_ value: TimeInterval, axis: AxisBase?) -> String {
        let i: Int = Int(value)
        let date: Date = Date(timeIntervalSince1970: label_x[i])
        
        let df = DateFormatter()
        df.dateFormat = "E"
        df.locale = Locale(identifier: "ko-KR")
        
        let d: Int = Calendar.current.component(.day, from: date)
        let dow: String = df.string(from: date)
        
        return dow + "\n" + String(d) + "일"
    }
}
