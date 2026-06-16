//
//  intern_weather.swift
//  InternCard
//
//  Created by idl on 2018. 10. 14..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import UIKit

class intern_weather
{
    var table = "intern_weather"
    
    var no: String = ""
    var user_no: String = ""
    var tears: String = ""
    var time: String = ""

    func create()
    {
        do {
            let db = try SQLite()
            var sql: String = """
            CREATE TABLE IF NOT EXISTS `%@`(
            `no` INTEGER PRIMARY KEY AUTOINCREMENT,
            `user_no` INTEGER,
            `tears` INTEGER,
            `time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
            """
            sql = String(format: sql, self.table)
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
    }
    
    func drop()
    {
        do {
            let db = try SQLite()
            try db.install(query: "DROP TABLE `intern_weather`;")
            try db.execute()
        } catch { print(error) }
    }
    
    func insert()
    {
        do {
            let db = try SQLite()
            try db.install(query: "INSERT INTO `" + self.table + "` (`user_no`, `tears`) VALUES ('" + self.user_no + "', '" + self.tears + "');")
            try db.execute()
        } catch { print(error) }
    }

    func insert_remote(user_no: String, tears: String) -> Bool
    {
        var ret: Bool = false
        
        // Session
        let defaultSession = URLSession(configuration: .default)
        
        guard let url = URL(string: "http://internkid.com/intern_weather.insert.api.php?user_no=" + user_no + "&tears=" + tears) else {
            print("URL is nil")
            return false
        }
        
        // Request
        let request = URLRequest(url: url)
        
        let dg0: DispatchGroup! = DispatchGroup()
        dg0.enter()
        
        // dataTask
        let dataTask = defaultSession.dataTask(with: request) { data, response, error in
            
            // getting Data Error
            guard error == nil else {
                print("Error occur: \(String(describing: error))")
                dg0.leave()
                return
            }
            
            // response
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                ret = true
            } else {
                ret = false
                dg0.leave()
                return
            }
            
            dg0.leave()
        }
        dataTask.resume()
        dg0.wait()
        
        return ret
    }
    
    func select_last() {
        do {
            let db = try SQLite()
            try db.install(query: "SELECT `no`, `user_no`, `tears`, `time` FROM `" + self.table + "` ORDER BY `no` LIMIT 0, 1")
            try db.execute() { stmt in
                self.no = String(cString: sqlite3_column_text(stmt, 0))
                self.user_no = String(cString: sqlite3_column_text(stmt, 1))
                self.tears = String(cString: sqlite3_column_text(stmt, 2))
                self.time = String(cString: sqlite3_column_text(stmt, 3))
            }
        } catch {
            print(error)
        }
    }
    
    func getStartTime(date: Date) -> TimeInterval {
        var date = date
        
        let ns: Int = Calendar.current.component(.nanosecond, from: date)
        date = Calendar.current.date(byAdding: .nanosecond, value: -ns, to: date)!
        
        let s: Int = Calendar.current.component(.second, from: date)
        date = Calendar.current.date(byAdding: .second, value: -s, to: date)!
        
        let m: Int = Calendar.current.component(.minute, from: date)
        date = Calendar.current.date(byAdding: .minute, value: -m, to: date)!
        
        let h: Int = Calendar.current.component(.hour, from: date)
        date = Calendar.current.date(byAdding: .hour, value: -h + 4, to: date)!
        
        if h < 4 {
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }

        return date.timeIntervalSince1970
    }
}
