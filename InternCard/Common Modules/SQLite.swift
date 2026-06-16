//
//  SQLite.swift
//  InternCard
//
//  Created by idl on 2018. 6. 15..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import Foundation


class SQLite {
    enum SQLError: Error {
        case connectionError
        case queryError
        case otherError
    }
    
    enum ColumnType {
        case int
        case double
        case text
    }
    
    var db: OpaquePointer?
    var stmt: OpaquePointer?
    
    let path: String = {
        let fm = FileManager.default
        return fm.urls(for:.libraryDirectory, in:.userDomainMask).last!
            .appendingPathComponent("INTERNCARD.DB").path
    }()
    
    init() throws {
        guard sqlite3_open(path, &db) == SQLITE_OK
            else {
                throw SQLError.connectionError
        }
    }
    
    func install(query: String) throws {
        sqlite3_finalize(stmt)
        stmt = nil
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            return
        }
        throw SQLError.queryError
    }
    
    func bind(data:Any, withType type: ColumnType, at col: Int32 = 1) {
        switch type {
        case .int:
            if let value = data as? Int {
                sqlite3_bind_int(stmt, col, Int32(value))
            }
        case .double:
            if let value = data as? Double {
                sqlite3_bind_double(stmt, col, value)
            }
        case .text:
            if let value = data as? String {
                sqlite3_bind_text(stmt, col, value, -1, nil)
            }
        }
    }
    
    func execute(rowHandler:((OpaquePointer) -> Void)? = nil) throws {
        while true {
            switch sqlite3_step(stmt) {
            case SQLITE_DONE:
                return
            case SQLITE_ROW:
                rowHandler?(stmt!)
            default:
                print(sqlite3_errmsg(stmt))
                throw SQLError.otherError
            }
        }
    }
    
    deinit {
        sqlite3_finalize(stmt)
        sqlite3_close(db)
    }
    
    
    static func isTableExist(table: String) -> Bool {
        var ret: Bool = false
        do {
            let db = try SQLite()
            let sql = "SELECT name FROM sqlite_master WHERE type='table' AND name='" + table + "';"
            try db.install(query: sql)
            try db.execute(){ stmt in
                //let name: String = String(cString: sqlite3_column_text(db.stmt, 0))
                ret = true
            }
        } catch {
            print(error)
        }
        return ret
    }
}
