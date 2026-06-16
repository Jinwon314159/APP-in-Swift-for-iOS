//
//  config.swift
//  InternCard
//
//  Created by Caleb on 2018. 10. 14..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import Foundation

class config
{
    let table: String = "config"
    
    var no: String = ""
    var key: String = ""
    var value: String = ""
    
    func create()
    {
        do {
            let db = try SQLite()
            var sql: String = """
            CREATE TABLE IF NOT EXISTS `%@`(
            `no` INTEGER PRIMARY KEY AUTOINCREMENT,
            `key` TEXT,
            `value` TEXT);
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
    
    func insert() {
        do {
            let db = try SQLite()
            let sql: String = "INSERT INTO `" + self.table + "` (`key`, `value`) VALUES ('" + self.key + "', '" + self.value + "');"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
    }
    
    func update() {
        do {
            let db = try SQLite()
            let sql: String = "UPDATE `" + self.table + "` SET `value`='" + self.value + "' WHERE `key`='" + self.key + "';"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
    }
    
    func select_by_key() {
        do {
            let db = try SQLite()
            let sql: String = "SELECT `value` FROM `" + self.table + "` WHERE `key`='" + self.key + "';"
            try db.install(query: sql)
            try db.execute() { stmt in
                self.value = String(cString: sqlite3_column_text(stmt, 0))
            }
        } catch {
            print(error)
        }
    }
}
