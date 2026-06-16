//
//  activity_per_day.swift
//  InternCard
//
//  Created by idl on 2018. 10. 15..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import Foundation

class activity_per_day {
    
    let table: String = "activity_per_day"
    
    var no: String = ""
    var child_no: String = ""
    var action_thresholds_no: String = ""
    var intensity_summary: String = ""
    var intensity_average: String = ""
    var total_count: String = ""
    var start: String = ""
    var end: String = "" // 마지막 데이터의 다음 데이터의 시간
    var synced: String = ""

    func create() {
        do {
            let db = try SQLite()
            var sql: String = """
            CREATE TABLE IF NOT EXISTS `%@` (
            `no` INTEGER PRIMARY KEY AUTOINCREMENT,
            `child_no` INTEGER,
            `action_thresholds_no` INTEGER NULL,
            `intensity_summary` TEXT,
            `intensity_average` REAL,
            `total_count` INTEGER,
            `start` TEXT,
            `end` TEXT,
            `synced` INTEGER DEFAULT 0);
            """
            sql = String(format: sql, self.table)
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
    }
    
    func drop() {
        do {
            let db = try SQLite()
            try db.install(query: "DROP TABLE `" + self.table + "`;")
            try db.execute()
        } catch { print(error) }
    }
    
    func insert() {
        do {
            let db = try SQLite()
            let sql: String = "INSERT INTO `" + self.table + "` (`child_no`, `intensity_summary`, `intensity_average`, `total_count`, `start`, `end`, `synced`) VALUES ('" + self.child_no + "', '" + self.intensity_summary + "', '" + self.intensity_average + "', '" + self.total_count + "', '" + self.start + "', '" + self.end + "', '" + self.synced + "')"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
    }
    
    func update() {
        do {
            let db = try SQLite()
            let sql: String = "UPDATE `" + self.table + "` SET `child_no`='" + self.child_no + "', `intensity_summary`='" + self.intensity_summary + "', `intensity_average`='" + self.intensity_average + "', `total_count`='" + self.total_count + "', `start`='" + self.start + "', `end`='" + self.end + "', `synced`='" + self.synced + "' WHERE `no`='" + self.no + "'"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
    }

    func select_by_start(_ s: TimeInterval) -> Bool {
        var ret: Bool = false
        
        do {
            let db = try SQLite()
            let sql: String = "SELECT `no`, `child_no`, `intensity_summary`, `intensity_average`, `total_count`, `start`, `end`, `synced` FROM `" + self.table + "` WHERE `child_no`='" + self.child_no + "' AND `start`='" + String(Int(s)) + "' ORDER BY `no` DESC LIMIT 0, 1"
            try db.install(query: sql)
            try db.execute() { stmt in
                self.no = String(cString: sqlite3_column_text(stmt, 0))
                self.child_no = String(cString: sqlite3_column_text(stmt, 1))
                self.intensity_summary = String(cString: sqlite3_column_text(stmt, 2))
                self.intensity_average = String(cString: sqlite3_column_text(stmt, 3))
                self.total_count = String(cString: sqlite3_column_text(stmt, 4))
                self.start = String(cString: sqlite3_column_text(stmt, 5))
                self.end = String(cString: sqlite3_column_text(stmt, 6))
                self.synced = String(cString: sqlite3_column_text(stmt, 7))
                
                ret = true
            }
        } catch {
            print(error)
        }
        
        return ret
    }
    
    func get_summary_by_start(_ s: TimeInterval) -> [String:Int64]? {
        var ret: [String:Int64]? = nil
        
        do {
            let db = try SQLite()
            let sql: String = "SELECT `no`, `child_no`, `intensity_summary`, `intensity_average`, `total_count`, `start`, `end`, `synced` FROM `" + self.table + "` WHERE `child_no`='" + self.child_no + "' AND `start`='" + String(Int(s)) + "' ORDER BY `no` DESC LIMIT 0, 1"
            try db.install(query: sql)
            try db.execute() { stmt in
                self.no = String(cString: sqlite3_column_text(stmt, 0))
                self.child_no = String(cString: sqlite3_column_text(stmt, 1))
                self.intensity_summary = String(cString: sqlite3_column_text(stmt, 2))
                self.intensity_average = String(cString: sqlite3_column_text(stmt, 3))
                self.total_count = String(cString: sqlite3_column_text(stmt, 4))
                self.start = String(cString: sqlite3_column_text(stmt, 5))
                self.end = String(cString: sqlite3_column_text(stmt, 6))
                self.synced = String(cString: sqlite3_column_text(stmt, 7))
                
                ret = Utils.dictionary(json: self.intensity_summary) as? [String:Int64]
            }
        } catch {
            print(error)
        }
        
        return ret
    }
    
    func get_total_by_start(_ start: TimeInterval) -> Double {
        var ret: Double = 0.0
        
        do {
            let db = try SQLite()
            let sql: String = "SELECT `no`, `child_no`, `intensity_summary`, `intensity_average`, `total_count`, `start`, `end`, `synced` FROM `" + self.table + "` WHERE `child_no`='" + self.child_no + "' AND `start`='" + String(Int(start)) + "' ORDER BY `no` DESC LIMIT 0, 1"
            try db.install(query: sql)
            try db.execute() { stmt in
                self.no = String(cString: sqlite3_column_text(stmt, 0))
                self.child_no = String(cString: sqlite3_column_text(stmt, 1))
                self.intensity_summary = String(cString: sqlite3_column_text(stmt, 2))
                self.intensity_average = String(cString: sqlite3_column_text(stmt, 3))
                self.total_count = String(cString: sqlite3_column_text(stmt, 4))
                self.start = String(cString: sqlite3_column_text(stmt, 5))
                self.end = String(cString: sqlite3_column_text(stmt, 6))
                self.synced = String(cString: sqlite3_column_text(stmt, 7))
                
                ret = Double(self.intensity_average)! * Double(self.total_count)!
            }
        } catch {
            print(error)
        }
        
        return ret
    }

    var offset_utc: TimeInterval = 0.0
    var latest_utc: TimeInterval = 0.0

    // summarize daily
    func summarize_and_insert(progress: (TimeInterval)->()) {
        
        let aph: activity_per_hour = activity_per_hour()
        aph.child_no = self.child_no
        
        let df: DateFormatter = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // hourly data가 summarized 되었는지 알 수 있는 플래그나 규칙이 필요하다. => summarized 필드 추가
        // activity_per_hour.summary_start()를 통해 첫 hour 데이터의 offset_time을 구한다.
        self.offset_utc = aph.summary_offset()
        self.latest_utc = aph.summary_latest()
        
        print("offset_utc: " + df.string(from: Date(timeIntervalSince1970: self.offset_utc)))
        print("latest_utc: " + df.string(from: Date(timeIntervalSince1970: self.latest_utc)))

        // 하루의 start와 end를 구한다.
        var start: TimeInterval = self.getStartTime(date: Date(timeIntervalSince1970: self.offset_utc))
        var end: TimeInterval = start + 86400.0 // 하루 86400초를 더함

        print("start: " + df.string(from: Date(timeIntervalSince1970: start)))
        print("end: " + df.string(from: Date(timeIntervalSince1970: end)))

        while true {

            // 기존 데이터에 추가해야 하는 경우 체크
            let update_flag: Bool = self.select_by_start(start)
            
            // 강도 요약
            var summary: [String:Int64] = ["Action0":0, "Action1":0, "Action2":0, "Action3":0]
            
            // 강도 평균
            var sum: Double = 0
            var count: Int64 = 0

            var no_start: UInt64 = UInt64.max
            var no_end: UInt64 = 0
            
            // activity_per_hour에서 해당 child_no에 대해 start ~ end의 범위 내에 있는 데이터를 callback으로 하나씩 가져온다.
            aph.select_for_daily_summary(from: start, to: end) { ()->() in

                //print("select-start: " + df.string(from: Date(timeIntervalSince1970: Double(aph.start)!)))
                //print("select-end: " + df.string(from: Date(timeIntervalSince1970: Double(aph.end)!)))

                let no_current: UInt64 = UInt64(aph.no)!
                if no_current < no_start { no_start = no_current }
                if no_current > no_end { no_end = no_current }

                // loop를 돌면서.. intensity_summary 를 누적, intensity_average를 구하기 위한 sum과 count를 누적

                // 시간 강도 요약을 합산
                let hourly_summary = Utils.dictionary(json: aph.intensity_summary) as! [String:Int64]
                summary["Action0"]! += hourly_summary["Action0"]!
                summary["Action1"]! += hourly_summary["Action1"]!
                summary["Action2"]! += hourly_summary["Action2"]!
                summary["Action3"]! += hourly_summary["Action3"]!
                
                // 시간 평균에 합산
                sum = Double(aph.intensity_average)! * Double(aph.total_count)! + sum
                count = count + Int64(aph.total_count)!
            }
            
            // sql 입력
            self.intensity_summary = Utils.json(any: summary)!
            self.intensity_average = String(sum / Double(count))
            self.total_count = String(count)
            self.start = String(Int(start))
            self.end = String(Int(end))
            self.synced = "0"

            // 최종 결과를 insert/update
            if update_flag {
                self.update()
            } else {
                self.insert()
            }
            
            // 요약 된 hourly data의 summarized flag를 1로 세팅
            aph.update_as_summarized(from: no_start, to: no_end)
            
            // progress를 보여주기 위한 콜백
            progress(end)
            
            // 종료 조건: end가 latest_utc보다 크거나 같아지면 끝낸다.
            if end >= self.latest_utc { break }
            
            // next 준비
            // 3600초(1시간) 씩 더하면서 진행
            start = start + 86400.0
            end = end + 86400.0
        }
        
        print("daily summarization completed.")
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
        date = Calendar.current.date(byAdding: .hour, value: -h, to: date)!

        return date.timeIntervalSince1970
    }
    
    func update_as_synced(no at: String) {
        
        do {
            let db = try SQLite()
            let sql: String = "UPDATE `" + self.table + "` SET `synced`='1' WHERE `no`='" + at + "'"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
    }
    
    var sync_total: Int = 0
    var update_total: Int = 0
    
    func synchronize_with_remote(progress_sync: @escaping (Int)->(), progress_update: @escaping (Int)->()) {
        
        var synced_list: [String] = []
        
        // Local와 Remote의 child_no, start가 일치하면 같은 데이터이며, end가 일치하지 않으면 update가 필요하므로
        // 1. Local의 데이터들 중 synced가 0, child_no가 일치하는 데이터의 start, end 값을 select 해서 가져오고
        do {
            let db = try SQLite()

            self.sync_total = 0
            var sql: String = "SELECT COUNT(*) FROM `" + self.table + "` WHERE `child_no`='" + self.child_no + "' AND `synced`='0'"
            try db.install(query: sql)
            try db.execute() { stmt in
                self.sync_total = Int(sqlite3_column_int(stmt, 0))
            }

            var i: Int = 0

            sql = "SELECT `no`, `child_no`, `intensity_summary`, `intensity_average`, `total_count`, `start`, `end` FROM `" + self.table + "` WHERE `child_no`='" + self.child_no + "' AND `synced`='0' ORDER BY `no` ASC"
            try db.install(query: sql)
            try db.execute() { stmt in
                
                self.no = String(cString: sqlite3_column_text(stmt, 0))
                self.child_no = String(cString: sqlite3_column_text(stmt, 1))
                self.intensity_summary = String(cString: sqlite3_column_text(stmt, 2))
                self.intensity_average = String(cString: sqlite3_column_text(stmt, 3))
                self.total_count = String(cString: sqlite3_column_text(stmt, 4))
                self.start = String(cString: sqlite3_column_text(stmt, 5))
                self.end = String(cString: sqlite3_column_text(stmt, 6))

                // 2. Remote: activity_per_day.insert.api.php를 콜 (서버에서 child_no, start로 검색하여 데이터가 없으면self. insert 있으면 update한다.)
                if self.insert_to_remote() {
                    synced_list.append(self.no)
                }

                i += 1
                
                progress_sync(i)
            }
        } catch { print(error) }
        
        self.update_total = synced_list.count

        for i in 0..<synced_list.count {
            update_as_synced(no: synced_list[i])
            
            progress_update(i)
        }
    }
    
    func insert_to_remote() -> Bool {
        
        var ret: Bool = false
        
        // Session
        let defaultSession = URLSession(configuration: .default)

        guard let url = URL(string: "http://internkid.com/activity_per_day.insert.api.php?child_no=" + self.child_no + "&intensity_summary=" + Utils.base64_encode(text: self.intensity_summary) + "&intensity_average=" + self.intensity_average + "&total_count=" + self.total_count + "&start=" + self.start + "&end=" + self.end) else {
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
            
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                ret = true
            }
            
            dg0.leave()
        }
        dataTask.resume()
        dg0.wait()
        
        return ret
    }
}
