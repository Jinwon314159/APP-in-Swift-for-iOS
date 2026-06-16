//
//  CaronDevice.swift
//  InternCard
//
//  Created by idl on 2018. 10. 14..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import Foundation

class caron_device
{
    let table: String = "caron_device"
    
    var no: String = ""
    var remote_no: String = ""
    var child_no: String = ""
    var mac_address: String = ""
    var serial_number: String = ""

    func create()
    {
        do {
            let db = try SQLite()
            var sql: String = """
            CREATE TABLE IF NOT EXISTS `%@`(
            `no` INTEGER PRIMARY KEY AUTOINCREMENT,
            `remote_no` INTEGER DEFAULT 0,
            `child_no` INTEGER,
            `mac_address` TEXT,
            `serial_number` TEXT);
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
    
    func select_by_child_no() -> Bool {
        var ret: Bool = false
        do {
            let db = try SQLite()
            let sql: String = "SELECT `mac_address`, `serial_number` FROM `" + self.table + "` WHERE `child_no`='" + self.child_no + "' ORDER BY `no` DESC LIMIT 0, 1"
            try db.install(query: sql)
            try db.execute() { stmt in
                self.mac_address = String(cString: sqlite3_column_text(stmt, 0))
                self.serial_number = String(cString: sqlite3_column_text(stmt, 1))
                ret = true
            }
        } catch { print(error) }
        return ret
    }
}
