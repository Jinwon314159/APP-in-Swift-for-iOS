//
//  user.swift
//  InternCard
//
//  Created by idl on 2018. 10. 14..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import Foundation

class user
{
    let table: String = "user"
    
    var no: String = ""
    var remote_no: String = ""
    var oauth2_provider: String = ""
    var uid: String = ""
    var client_id: String = ""
    var level: String = ""

    func create()
    {
        do {
            let db = try SQLite()
            var sql: String = """
            CREATE TABLE IF NOT EXISTS `%@`(
            `no` INTEGER PRIMARY KEY AUTOINCREMENT,
            `remote_no` INTEGER DEFAULT 0,
            `oauth2_provider` TEXT,
            `uid` TEXT,
            `client_id` TEXT,
            `level` INTEGER DEFAULT 0);
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
            try db.install(query: "DROP TABLE `" + self.table + "`;")
            try db.execute()
        } catch { print(error) }
    }
    
    func insert()
    {
        do {
            let db = try SQLite()
            try db.install(query: "INSERT INTO `" + self.table + "` (`remote_no`, `oauth2_provider`, `uid`, `client_id`, `level`) VALUES ('" + self.remote_no + "', '" + self.oauth2_provider + "', '" + self.uid + "', '" + self.client_id + "', '" + self.level + "');")
            try db.execute()
        } catch { print(error) }
    }
    
    func update()
    {
        do {
            let db = try SQLite()
            try db.install(query: "UPDATE `" + self.table + "` SET `oauth2_provider`='" + self.oauth2_provider + "', `uid`='" + self.uid + "', `client_id`='" + self.client_id + "', `level`='" + self.level + "' WHERE `remote_no`='" + self.remote_no + "';")
            try db.execute()
        } catch { print(error) }
    }
    
    func select_last() -> Bool {
        var ret: Bool = false
        do {
            let db = try SQLite()
            let sql: String = "SELECT `no`, `remote_no`, `oauth2_provider`, `uid`, `client_id`, `level` FROM `user` ORDER BY `no` DESC LIMIT 0, 1;"
            
            try db.install(query: sql)
            try db.execute() { stmt in
                self.no = String(cString: sqlite3_column_text(stmt, 0))
                self.remote_no = String(cString: sqlite3_column_text(stmt, 1))
                self.oauth2_provider = String(cString: sqlite3_column_text(stmt, 2))
                self.uid = String(cString: sqlite3_column_text(stmt, 3))
                self.client_id = String(cString: sqlite3_column_text(stmt, 4))
                self.level = String(cString: sqlite3_column_text(stmt, 5))

                ret = true
            }
        } catch {
            print(error)
            ret = false
        }
        
        return ret
    }
}
