//
//  height.swift
//  InternCard
//
//  Created by idl on 2018. 10. 14..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import Foundation

class height
{
    let table: String = "height"
    
    var no: String = ""
    var child_no: String = ""
    var height: String = ""
    var time: String = ""
    
    func create()
    {
        do {
            let db = try SQLite()
            var sql: String = """
            CREATE TABLE IF NOT EXISTS `%@`(
            `no` INTEGER PRIMARY KEY AUTOINCREMENT,
            `child_no` INTEGER,
            `height` REAL,
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
            try db.install(query: "DROP TABLE `height`;")
            try db.execute()
        } catch { print(error) }
    }
    
    func insert()
    {
        do {
            let db = try SQLite()
            let sql: String = "INSERT INTO `height`(`child_no`, `height`) VALUES ('" + self.child_no + "', '" + self.height + "');"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }

    }
    
    func select_by_child_no()
    {
        do {
            let db = try SQLite()
            let sql: String = "SELECT `height`, `time` FROM `height` WHERE `child_no`=" + self.child_no + " ORDER BY `no` DESC LIMIT 0, 1"
            try db.install(query: sql)
            try db.execute() { stmt in
                self.height = String(cString: sqlite3_column_text(stmt, 0))
                self.time = String(cString: sqlite3_column_text(stmt, 1))
            }
        } catch { print(error) }
    }
}
