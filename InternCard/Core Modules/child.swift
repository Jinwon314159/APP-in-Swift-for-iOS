//
//  child.swift
//  InternCard
//
//  Created by idl on 2018. 10. 14..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import Foundation

class child
{
    let table = "child"
    
    var no: String = ""
    var remote_no: String = ""
    var name: String = ""
    var gender: String = ""
    var birth: String = ""
    var user_no: String = ""

    func create()
    {
        do {
            let db = try SQLite()
            var sql: String = """
            CREATE TABLE IF NOT EXISTS `%@`(
            `no` INTEGER PRIMARY KEY AUTOINCREMENT,
            `remote_no` INTEGER DEFAULT 0,
            `name` TEXT,
            `gender` CHAR,
            `birth` TEXT,
            `user_no` INTEGER);
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
            let sql: String = "INSERT INTO `" + self.table + "` (`remote_no`, `name`, `gender`, `birth`, `user_no`) VALUES ('" + self.remote_no + "', '" + self.name + "', '" + self.gender + "', '" + self.birth + "', '" + self.user_no + "');"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
    }
    
    // child의 remote_no만 가지고 callback으로 넘어가면 됨
    func select_for_summary(callback: @escaping ()->()) {
        do {
            let db = try SQLite()
            let sql: String = "SELECT `remote_no` FROM `" + self.table + "` ORDER BY `no` ASC"
            try db.install(query: sql)
            try db.execute() { stmt in
                self.remote_no = String(cString: sqlite3_column_text(stmt, 0))
                callback()
            }
        } catch { print(error) }
    }
    
    func select_by_remote_no()
    {
        do {
            let db = try SQLite()
            let sql:String! = "SELECT `name`, `gender`, `birth`, `user_no` FROM `" + self.table + "` WHERE `remote_no`='" + self.remote_no + "' ORDER BY `no` DESC LIMIT 0, 1"
            try db.install(query: sql)
            try db.execute() { stmt in
                self.name = String(cString: sqlite3_column_text(stmt, 0))
                self.gender = String(cString: sqlite3_column_text(stmt, 1))
                self.birth = String(cString: sqlite3_column_text(stmt, 2))
                self.user_no = String(cString: sqlite3_column_text(stmt, 3))
            }
        } catch { print(error) }
    }
}
