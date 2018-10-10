//
//  ViewController.swift
//  NetMonitor
//
//  Created by Matt Brandt on 6/16/18.
//  Copyright © 2018 Walkingdog. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    var timer: Timer!
    var pingTimer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // fire timer every 30 minutes
        timer = Timer(fire: .init(timeIntervalSinceNow: 0), interval: 60 * 10, repeats: true, block: { (t) in
            self.runSpeedTest()
        })
        RunLoop.main.add(timer, forMode: .defaultRunLoopMode)

        pingTimer = Timer(fire: .init(timeIntervalSinceNow: 0), interval: 10, repeats: true, block: { (t) in
            self.runPingTest()
        })
        RunLoop.main.add(pingTimer, forMode: .defaultRunLoopMode)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func addEntry(time: Date, ping: Int, upload: Double, download: Double) {
        DispatchQueue.main.async {
            let appd = NSApp.delegate as! AppDelegate
            let moc = appd.moc
            let entry = SpeedTestResult(context: moc)
            entry.succeeded = true
            entry.ping = Int32(ping)
            entry.timestamp = time
            entry.upload = upload
            entry.download = download
            do {
                try moc.save()
            } catch {
                print("Save failed")
            }
            self.view.setNeedsDisplay(self.view.bounds)
        }
    }
    
    func addPingEntry(time: Date, ping: Int) {
        DispatchQueue.main.async {
            let appd = NSApp.delegate as! AppDelegate
            let moc = appd.moc
            let entry = SpeedTestResult(context: moc)
            entry.succeeded = true
            entry.ping = Int32(ping)
            entry.timestamp = time
            entry.upload = -1
            entry.download = -1
            do {
                try moc.save()
            } catch {
                print("Save failed")
            }
            self.view.setNeedsDisplay(self.view.bounds)
        }
    }
    
    func addInvalidEntry(time: Date) {
        DispatchQueue.main.async {
            let appd = NSApp.delegate as! AppDelegate
            let moc = appd.moc
            let entry = SpeedTestResult(context: moc)
            entry.succeeded = false
            entry.timestamp = time
            do {
                try moc.save()
            } catch {
                print("Save failed")
            }
            self.view.setNeedsDisplay(self.view.bounds)
        }
    }

    func runSpeedTest() {
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            let output = Pipe()
            let path = Bundle.main.bundlePath + "/Contents/Resources/speedtest-cli"
            
            task.standardOutput = output
            task.standardError = FileHandle(forWritingAtPath: "/dev/null")
            task.executableURL = URL(fileURLWithPath: path)
            task.arguments = ["--json"]
            let now = Date(timeIntervalSinceNow: 0)
            print("running at \(now)")
            do {
                try task.run()
                let data = output.fileHandleForReading.readDataToEndOfFile()
                let info = try JSON(data: data)
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let ping = info["ping"].int, let rx = info["download"].double, let tx = info["upload"].double,
                        let ts = info["timestamp"].string, let date = dateFormatter.date(from: ts) {
                    print("ping = \(ping), rx = \(rx), tx = \(tx), date = \(date)\n")
                    self.addEntry(time: date, ping: ping, upload: tx, download: rx)
                } else {
                    self.addInvalidEntry(time: now)
                    print("Speed Test Failed at \(now)")
                }
            } catch {
                print("JSON Decode failed at \(now)")
                self.addInvalidEntry(time: now)
            }
        }
    }
    
    enum PingError: Error {
        case stringDecodeError
    }
    
    func runPingTest() {
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            let output = Pipe()
            let path = "/sbin/ping"
            
            task.standardOutput = output
            task.standardError = FileHandle(forWritingAtPath: "/dev/null")
            task.executableURL = URL(fileURLWithPath: path)
            task.arguments = ["-c", "1", "8.8.8.8"]
            let now = Date(timeIntervalSinceNow: 0)
            do {
                try task.run()
                let data = output.fileHandleForReading.readDataToEndOfFile()
                guard let s = String(data: data, encoding: .ascii) else { throw PingError.stringDecodeError }
                let timeRe = RegularExpression(pattern: "time=([[:digit:]]*)")
                guard timeRe.matchesWithString(s) else { throw PingError.stringDecodeError }
                guard let ts = timeRe.match(1) else {throw PingError.stringDecodeError }
                guard let t = Int(ts) else { throw PingError.stringDecodeError }
                print("ping time = \(t)")
                self.addPingEntry(time: now, ping: t)
            } catch {
                print("ping failed")
                self.addInvalidEntry(time: now)
            }
        }
    }
}

