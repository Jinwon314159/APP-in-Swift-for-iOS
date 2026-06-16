//
//  weight.swift
//  InternCard
//
//  Created by idl on 2018. 10. 14..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import Foundation

class weight
{
    let table: String = "weight"
    
    var no: String = ""
    var child_no: String = ""
    var weight: String = ""
    var time: String = ""

    func create()
    {
        do {
            let db = try SQLite()
            var sql: String = """
            CREATE TABLE IF NOT EXISTS `%@`(
            `no` INTEGER PRIMARY KEY AUTOINCREMENT,
            `child_no` INTEGER,
            `weight` REAL,
            `time` TEXT DEFAULT CURRENT_TIMESTAMP);
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
            let sql: String = "INSERT INTO `weight`(`child_no`, `weight`) VALUES ('" + self.child_no + "', '" + self.weight + "');"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
        
    }

    func select_by_child_no()
    {
        do {
            let db = try SQLite()
            let sql: String = "SELECT `weight`, `time` FROM `" + self.table + "` WHERE `child_no`=" + self.child_no + " ORDER BY `no` DESC LIMIT 0, 1"
            try db.install(query: sql)
            try db.execute() { stmt in
                self.weight = String(cString: sqlite3_column_text(stmt, 0))
                self.time = String(cString: sqlite3_column_text(stmt, 1))
            }
        } catch { print(error) }
    }
}
