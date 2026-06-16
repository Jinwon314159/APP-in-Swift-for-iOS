//
//  ActivityPerHour.swift
//  InternCard
//
//  Created by idl on 2018. 10. 14..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import Foundation

class activity_per_hour {
    
    let table: String = "activity_per_hour"
    
    var no: String = ""
    var child_no: String = ""
    var action_thresholds_no: String = ""
    var intensity_summary: String = ""
    var intensity_average: String = ""
    var total_count: String = ""
    var raw_data: String = ""
    var start: String = ""
    var end: String = "" // 마지막 데이터의 다음 데이터의 시간
    var summarized: String = "0"
    var synced: String = "0"
    
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
            `raw_data` TEXT,
            `start` TEXT,
            `end` TEXT,
            `summarized` INTEGER DEFAULT 0,
            `synced` INTEGER DEFAULT 0);
            """
            sql = String(format: sql, self.table)
            try db.install(query: sql)
            try db.execute()
        } catch {
            print(error)
        }
    }
    
    func drop() {
        do {
            let db = try SQLite()
            try db.install(query: "DROP TABLE `" + self.table + "`;")
            try db.execute()
        } catch {
            print(error)
        }
    }
    
    func insert() {
        do {
            let db = try SQLite()
            let sql: String = "INSERT INTO `" + self.table + "` (`child_no`, `intensity_summary`, `intensity_average`, `total_count`, `raw_data`, `start`, `end`, `summarized`, `synced`) VALUES ('" + self.child_no + "', '" + self.intensity_summary + "', '" + self.intensity_average + "', '" + self.total_count + "', '" + self.raw_data + "', '" + self.start + "', '" + self.end + "', '" + self.summarized + "', '" + self.synced + "')"
            try db.install(query: sql)
            try db.execute()
        } catch {
            print(error)
        }
    }
    
    func update() {
        do {
            let db = try SQLite()
            let sql: String = "UPDATE `" + self.table + "` SET `child_no`='" + self.child_no + "', `intensity_summary`='" + self.intensity_summary + "', `intensity_average`='" + self.intensity_average + "', `total_count`='" + self.total_count + "', `raw_data`='" + self.raw_data + "', `start`='" + self.start + "', `end`='" + self.end + "', `summarized`='" + self.summarized + "', `synced`='" + self.synced + "' WHERE `no`='" + self.no + "';"
            try db.install(query: sql)
            try db.execute()
        } catch {
            print(error)
        }
    }
    
    
    func select_by_no() -> Bool {
        var ret: Bool = false
        
        do {
            let db = try SQLite()
            let sql: String = "SELECT `child_no`, `intensity_summary`, `intensity_average`, `total_count`, `raw_data`, `start`, `end`, `summarized`, `synced` FROM `" + self.table + "` WHERE `no`='" + self.no + "'"
            try db.install(query: sql)
            try db.execute() { stmt in
                self.child_no = String(cString: sqlite3_column_text(stmt, 0))
                self.intensity_summary = String(cString: sqlite3_column_text(stmt, 1))
                self.intensity_average = String(cString: sqlite3_column_text(stmt, 2))
                self.total_count = String(cString: sqlite3_column_text(stmt, 3))
                self.raw_data = String(cString: sqlite3_column_text(stmt, 4))
                self.start = String(cString: sqlite3_column_text(stmt, 5))
                self.end = String(cString: sqlite3_column_text(stmt, 6))
                self.summarized = String(cString: sqlite3_column_text(stmt, 7))
                self.synced = String(cString: sqlite3_column_text(stmt, 8))

                ret = true
            }
        } catch {
            print(error)
        }
        
        return ret
    }
    
    func update_as_summarized(from: UInt64, to: UInt64) {
        
        let no_start: String = String(from)
        let no_end: String = String(to)

        do {
            let db = try SQLite()
            let sql: String = "UPDATE `" + self.table + "` SET `summarized`='1' WHERE `child_no`='" + self.child_no + "' AND `no`>='" + no_start + "' AND `no`<='" + no_end + "';"
            try db.install(query: sql)
            try db.execute()
        } catch { print(error) }
    }
    
    func summary_offset() -> TimeInterval {
        var ret: TimeInterval = 0.0
        do {
            let db = try SQLite()
            let sql: String = "SELECT `start` FROM `" + self.table + "` WHERE `child_no`='" + self.child_no + "' AND `summarized`='0' ORDER BY `no` ASC LIMIT 0, 1"
            try db.install(query: sql)
            try db.execute() { stmt in
                ret = Double(String(cString: sqlite3_column_text(stmt, 0)))!
            }
        } catch { print(error) }
        return ret
    }
    
    func summary_latest() -> TimeInterval {
        var ret: TimeInterval = 0.0
        do {
            let db = try SQLite()
            let sql: String = "SELECT `end` FROM `" + self.table + "` WHERE `child_no`='" + self.child_no + "' AND `summarized`='0' ORDER BY `no` DESC LIMIT 0, 1"
            try db.install(query: sql)
            try db.execute() { stmt in
                ret = Double(String(cString: sqlite3_column_text(stmt, 0)))!
            }
        } catch { print(error) }
        return ret
    }

    func select_for_daily_summary(from: TimeInterval, to: TimeInterval, callback: @escaping ()->()) {
        do {
            let db = try SQLite()
            let sql: String = "SELECT `no`, `child_no`, `intensity_summary`, `intensity_average`, `total_count`, `start`, `end`, `summarized`, `synced` FROM `" + self.table + "` WHERE `child_no`='" + self.child_no + "' AND `start`>='" + String(Int64(from)) + "' AND `start`<'" + String(Int64(to)) + "' ORDER BY `no` ASC"
            try db.install(query: sql)
            try db.execute() { stmt in
                self.no = String(cString: sqlite3_column_text(stmt, 0))
                self.child_no = String(cString: sqlite3_column_text(stmt, 1))
                self.intensity_summary = String(cString: sqlite3_column_text(stmt, 2))
                self.intensity_average = String(cString: sqlite3_column_text(stmt, 3))
                self.total_count = String(cString: sqlite3_column_text(stmt, 4))
                self.start = String(cString: sqlite3_column_text(stmt, 5))
                self.end = String(cString: sqlite3_column_text(stmt, 6))
                self.summarized = String(cString: sqlite3_column_text(stmt, 7))
                self.synced = String(cString: sqlite3_column_text(stmt, 8))

                callback()
            }
        } catch { print(error) }
    }

    func select_by_start(_ s: TimeInterval) -> Bool {
        var ret: Bool = false
        
        do {
            let db = try SQLite()
            let sql: String = "SELECT `no`, `child_no`, `intensity_summary`, `intensity_average`, `total_count`, `raw_data`, `start`, `end`, `summarized`, `synced` FROM `" + self.table + "` WHERE `child_no`='" + self.child_no + "' AND `start`='" + String(Int64(s)) + "'"
            try db.install(query: sql)
            try db.execute() { stmt in
                self.no = String(cString: sqlite3_column_text(stmt, 0))
                self.child_no = String(cString: sqlite3_column_text(stmt, 1))
                self.intensity_summary = String(cString: sqlite3_column_text(stmt, 2))
                self.intensity_average = String(cString: sqlite3_column_text(stmt, 3))
                self.total_count = String(cString: sqlite3_column_text(stmt, 4))
                self.raw_data = String(cString: sqlite3_column_text(stmt, 5))
                self.start = String(cString: sqlite3_column_text(stmt, 6))
                self.end = String(cString: sqlite3_column_text(stmt, 7))
                self.summarized = String(cString: sqlite3_column_text(stmt, 8))
                self.synced = String(cString: sqlite3_column_text(stmt, 9))

                ret = true
            }
        } catch {
            print(error)
        }
        
        return ret
    }
    
    // 입력의 중복을 막기 위해 초반에 스킵해야 하는 데이터의 개수
    var skip_count: Int = 0
    // 입력하고자 하는 데이터의 중복을 제거한 시간 범위
    var offset_utc: TimeInterval = 0
    var latest_utc: TimeInterval = 0
    
    // 이미 입력된 데이터의 마지막 시간대를 확인하고 입력하고자 하는 데이터의 offset_time과 대조하여 offset_time을 재설정한다.
    func set_utc_range(offset: TimeInterval, latest: TimeInterval) {
        
        self.skip_count = 0
        self.offset_utc = offset
        self.latest_utc = latest
        
        // 마지막 시간대 확인은 쿼리를 날려서 whrere `child_no`='self.child_no' order by `no` desc로.. 그리고 raw_data의 배열 중 가장 마지막 데이터의 last_utc를 읽는다.
        do {
            let db = try SQLite()
            let sql: String = "SELECT `end` FROM `" + self.table + "` WHERE `child_no`='" + self.child_no + "' ORDER BY `no` DESC LIMIT 0, 1"
            try db.install(query: sql)
            try db.execute() { stmt in
                let end: TimeInterval = TimeInterval(String(cString: sqlite3_column_text(stmt, 0)))!
                if end > offset {
                    self.skip_count = Int((end - offset) / 60.0)
                    self.offset_utc = end
                }
            }
        } catch { print(error) }
    }
    
    func getStartTime(date: Date) -> TimeInterval {
        var date = date
        
        let ns: Int = Calendar.current.component(.nanosecond, from: date)
        date = Calendar.current.date(byAdding: .nanosecond, value: -ns, to: date)!
        
        let s: Int = Calendar.current.component(.second, from: date)
        date = Calendar.current.date(byAdding: .second, value: -s, to: date)!
        
        let m: Int = Calendar.current.component(.minute, from: date)
        date = Calendar.current.date(byAdding: .minute, value: -m, to: date)!
        
        return date.timeIntervalSince1970
    }
    
    // summarize hourly
    func summarize_and_insert(caron_data: Data, caron_total_count: Int, progress: (TimeInterval)->()) {
        
        let df: DateFormatter = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"

        //print("offset_utc: " + df.string(from: Date(timeIntervalSince1970: self.offset_utc)))
        //print("latest_utc: " + df.string(from: Date(timeIntervalSince1970: self.latest_utc)))
        
        // To DO: action_thresholds_no를 로컬/리모트에서 불러오기

        // date
        let d: Date = Date(timeIntervalSince1970: self.offset_utc)

        // 한 시간의 시작 시간과 끝 시간 (분 단위)
        var start: TimeInterval = self.getStartTime(date: d)
        var end: TimeInterval = start + 3600.0

        // 현재 시간
        var current: TimeInterval = self.offset_utc

        // current index
        var i: Int = self.skip_count

        // 기존 데이터에 추가해야 하는 경우 체크
        var update_flag: Bool = self.select_by_start(start)
        
        var data_start: TimeInterval = start
        var data_end: TimeInterval = end
        
        while true
        {
            //print("start: " + df.string(from: Date(timeIntervalSince1970: start)))
            //print("end: " + df.string(from: Date(timeIntervalSince1970: end)))

            if data_start < self.offset_utc { data_start = self.offset_utc }
            if data_end > self.latest_utc { data_end = self.latest_utc }
            
            var summary: [String:Int64] = ["Action0":0, "Action1":0, "Action2":0, "Action3":0]

            var sum: Double = 0
            var count: Int64 = 0
            var data_count: Int64 = 0

            if update_flag
            {
                // 기존 데이터에 추가해야 하는 경우
                summary = Utils.dictionary(json: self.intensity_summary) as! [String : Int64]
                sum = Double(self.intensity_average)! * Double(self.total_count)!
            }
            
            let s: Int = i

            // 데이터 하나 씩 처리
            while true
            {
                //print("current: " + df.string(from: Date(timeIntervalSince1970: current)))

                let value: UInt8 = ([UInt8](caron_data))[i]
                //print(String(value))
                
                // summary에 누적
                if value >= 0 && value < 4 {
                    summary["Action0"]! += 1
                }
                if value >= 4 && value < 120 {
                    //print("[" + String(i) + "] " + String(Int(value)))
                    summary["Action1"]! += 1
                }
                if value >= 120 && value <= 200 {
                    //print("[" + String(i) + "] " + String(Int(value)))
                    summary["Action2"]! += 1
                }
                if value >= 200 && value <= 255 {
                    //print("[" + String(i) + "] " + String(Int(value)))
                    summary["Action3"]! += 1
                }

                // 평균을 내기 위한 sum과 count
                sum += Double(value)
                data_count += 1
                
                // next 데이터 준비
                // 다음 인덱스와 그에 해당하는 시간
                i +=  1
                current += 60.0

                if current >= end || i >= caron_total_count { // 해당 시간대의 마지막에 도달했거나, i가 caron_total_count에 도달했을 경우
                    break
                }
            }
            
            let e: Int = i
            
            // 실제 입력되는 데이터의 시작 시간과 끝 시간
            let data: [String:Any] = [
                "start":Int64(data_start),
                "count":data_count,
                "end":Int64(data_end),
                "raw_data":(caron_data[s..<e]).base64EncodedString()]

            // sql 입력
            if update_flag {
                count = Int64(self.total_count)! + data_count

                self.intensity_summary = Utils.json(any: summary)!
                self.intensity_average = String(sum / Double(count))
                self.total_count = String(count)

                var data_array: [[String:Any]] = Utils.dictionary_array(json: self.raw_data)!
                data_array.append(data)
                self.raw_data = Utils.json(any: data_array)!

                self.start = String(Int64(start))
                self.end = String(Int64(data_end))
                self.summarized = "0"
                self.synced = "0"
                
                self.update()
                
                update_flag = false

            } else {
                //print("sum=" + String(sum))
                //print("count=" + String(count))
                //print("data_count=" + String(data_count))

                count = data_count
                
                self.intensity_summary = Utils.json(any: summary)!
                self.intensity_average = String(sum / Double(count))
                //print("intensity_average=" + String(self.intensity_average))
                self.total_count = String(count)
                
                self.raw_data = Utils.json(any: [data])!
                
                self.start = String(Int64(start))
                self.end = String(Int64(data_end))
                self.summarized = "0"
                self.synced = "0"
                
                self.insert()
            }
            

            progress(end)

            
            if end >= self.latest_utc {
                break
            }
            
            // next 준비
            // 3600초(1시간) 씩 더하면서 진행
            start = start + 3600.0
            end = end + 3600.0
            
            data_start = start
            data_end = end
        }
        
        assert(i == caron_total_count)
        
        print("hourly summarization completed.")
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
            
            sql = "SELECT `no`, `child_no`, `intensity_summary`, `intensity_average`, `total_count`, `raw_data`, `start`, `end` FROM `" + self.table + "` WHERE `child_no`='" + self.child_no + "' AND `synced`='0' ORDER BY `no` ASC"
            try db.install(query: sql)
            try db.execute() { stmt in
                
                self.no = String(cString: sqlite3_column_text(stmt, 0))
                self.child_no = String(cString: sqlite3_column_text(stmt, 1))
                self.intensity_summary = String(cString: sqlite3_column_text(stmt, 2))
                self.intensity_average = String(cString: sqlite3_column_text(stmt, 3))
                self.total_count = String(cString: sqlite3_column_text(stmt, 4))
                self.raw_data = String(cString: sqlite3_column_text(stmt, 5))
                self.start = String(cString: sqlite3_column_text(stmt, 6))
                self.end = String(cString: sqlite3_column_text(stmt, 7))
                
                // 2. Remote: activity_per_hour.insert.api.php를 콜 (서버에서 child_no, start로 검색하여 데이터가 없으면 insert, 있으면 update한다.)
                if self.insert_to_remote() {
                    synced_list.append(self.no)
                }
                
                i += 1
                
                progress_sync(i)
            }
        } catch { print(error) }
        
        
        self.update_total = synced_list.count
        
        for i in 0..<synced_list.count
        {
            update_as_synced(no: synced_list[i])
            
            progress_update(i)
        }
    }
    
    func insert_to_remote() -> Bool {
        
        var ret: Bool = false
        
        // Session
        let defaultSession = URLSession(configuration: .default)
        
        guard let url = URL(string: "http://internkid.com/activity_per_hour.insert.api.php?child_no=" + self.child_no + "&intensity_summary=" + Utils.base64_encode(text: self.intensity_summary) + "&intensity_average=" + self.intensity_average + "&total_count=" + self.total_count + "&start=" + self.start + "&end=" + self.end) else {
            print("URL is nil")
            return false
        }
        
        // Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(("raw_data=" + self.raw_data).utf8)

        
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
