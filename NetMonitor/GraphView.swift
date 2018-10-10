//
//  GraphView.swift
//  NetMonitor
//
//  Created by Matt Brandt on 6/17/18.
//  Copyright © 2018 Walkingdog. All rights reserved.
//

import Cocoa

let downloadColor = NSColor(calibratedRed: 1, green: 0, blue: 0, alpha: 1)
let uploadColor = NSColor(calibratedRed: 0, green: 0.5, blue: 0, alpha: 1)
let pingColor = NSColor.lightGray
let errorColor = NSColor(calibratedRed: 1, green: 0.5, blue: 0.5, alpha: 1)

extension CGRect {
    init(center: CGPoint, radius: CGFloat) {
        self.init(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }
}

class GraphView: NSView {
    
    @IBOutlet weak var datePicker: NSDatePicker!
    
    var results: [SpeedTestResult] = []
    
    override func awakeFromNib() {
        datePicker.dateValue = Date(timeIntervalSinceNow: 0)
        super.awakeFromNib()
    }
    
    @IBAction func dateChanged(sender: NSDatePicker) {
        setNeedsDisplay(bounds)
    }
    
    func startOfDay(_ date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.month, .day, .year], from: date)
        
        components.hour = 0
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)!
    }
    
    func nextDay(_ date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.month, .day, .year], from: date.addingTimeInterval(24 * 60 * 60))
        
        components.hour = 0
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)!
    }
    
    func previousDay(_ date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.month, .day, .year], from: date.addingTimeInterval(-24 * 60 * 60))
        
        components.hour = 0
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)!
    }
    
    func timeToX(_ date: Date) -> CGFloat {
        let midnight = startOfDay(date)
        let time = date.timeIntervalSince(midnight)
        let fullDay: CGFloat = 24.0 * 60.0 * 60.0
        let ratio = CGFloat(time) / fullDay
        let x = 100.0 + ratio * (bounds.width - 200)
        return x
    }
    
    func uploadToY(_ upload: Double) -> CGFloat {
        return CGFloat(upload) / 5000000.0 * (bounds.height - 200) + 100
    }
    
    func downloadToY(_ download: Double) -> CGFloat {
        return CGFloat(download) / 15000000.0 * (bounds.height - 200) + 100
    }

    func pingToY(_ ping: Int32) -> CGFloat {
        return CGFloat(ping) / 3000.0 * (bounds.height - 200) + 100
    }
    
    func drawXAxis() {
        if let context = NSGraphicsContext.current?.cgContext {
            let hourX = (bounds.size.width - 200) / 24.0
            NSColor.black.set()
            for hour in 1...23 {
                let x = CGFloat(hour) * hourX + 100
                context.move(to: CGPoint(x: x, y: 100))
                context.addLine(to: CGPoint(x: x, y: 90))
                context.strokePath()
                let text = NSString(format: "%d:00", hour)
                let w = text.size(withAttributes: [:]).width
                text.draw(at: NSPoint(x: x - w / 2, y: 70), withAttributes: [:])
            }
        }
    }
    
    func drawDownloadAxis() {
        if let context = NSGraphicsContext.current?.cgContext {
            let mbY = (bounds.size.height - 200) / 15.0
            downloadColor.set()
            for mb in 1...14 {
                let y = CGFloat(mb) * mbY + 100
                context.move(to: CGPoint(x: 100, y: y))
                context.addLine(to: CGPoint(x: 90, y: y))
                context.strokePath()
               let text = NSString(format: "%d", mb)
                let h = text.size(withAttributes: [:]).height
                text.draw(at: NSPoint(x: 75, y: y - h / 2), withAttributes: [.foregroundColor: downloadColor])
            }
        }
        
    }
    
    func drawUploadAxis() {
        if let context = NSGraphicsContext.current?.cgContext {
            let mbY = (bounds.size.height - 200) / 5
            uploadColor.set()
            for mb in 1...4 {
                let y = CGFloat(mb) * mbY + 100
                context.move(to: CGPoint(x: 60, y: y))
                context.addLine(to: CGPoint(x: 50, y: y))
                context.strokePath()
               let text = NSString(format: "%d", mb)
                let h = text.size(withAttributes: [:]).height
                text.draw(at: NSPoint(x: 40, y: y - h / 2), withAttributes: [.foregroundColor: uploadColor])
            }
        }
        
    }
    
    func drawPingAxis() {
        if let context = NSGraphicsContext.current?.cgContext {
            let x = bounds.size.width + bounds.origin.x - 100
            let mbY = (bounds.size.height - 200) / 3000
            pingColor.set()
            for mb in [100.0, 1000.0, 2000.0] {
                let y = CGFloat(mb) * mbY + 100
                context.move(to: CGPoint(x: x, y: y))
                context.addLine(to: CGPoint(x: x + 10, y: y))
                context.strokePath()
                let text = NSString(format: "%g", mb)
                let h = text.size(withAttributes: [:]).height
                text.draw(at: NSPoint(x: x + 15, y: y - h / 2), withAttributes: [.foregroundColor: pingColor])
            }
        }
        
    }
    
    func drawLegend() {
        let download: NSString = "-- DOWNLOAD-- "
        let upload: NSString = "-- UPLOAD --"
        let ping: NSString = "-- PING --"
        
        let legend = [(100, download, downloadColor), (300, upload, uploadColor), (500, ping, pingColor)]
        for (x, text, color) in legend {
            text.draw(at: NSPoint(x: x, y: 40), withAttributes: [.foregroundColor: color])
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        refreshResults()
        
        let box = bounds.insetBy(dx: 100, dy: 100)
        let context = NSGraphicsContext.current?.cgContext
        
        drawLegend()
        
        NSColor.black.set()
        context?.move(to: CGPoint(x: box.origin.x, y: box.origin.y + box.height))
        context?.addLine(to: box.origin)
        context?.addLine(to: CGPoint(x: box.origin.x + box.width, y: box.origin.y))
        context?.strokePath()
        drawXAxis()

        downloadColor.set()
        context?.move(to: CGPoint(x: 100, y: downloadToY(12000000)))
        context?.addLine(to: CGPoint(x: box.maxX, y: downloadToY(12000000)))
        drawDownloadAxis()
        context?.strokePath()

        uploadColor.set()
        context?.move(to: CGPoint(x: 100, y: uploadToY(1000000)))
        context?.addLine(to: CGPoint(x: box.maxX, y: uploadToY(1000000)))
        context?.strokePath()
        drawUploadAxis()

        pingColor.set()
        context?.move(to: CGPoint(x: 100, y: pingToY(100)))
        context?.addLine(to: CGPoint(x: box.maxX, y: pingToY(100)))
        context?.strokePath()
        drawPingAxis()

        for result in results {
            let x = timeToX(result.timestamp!)
            if result.succeeded && result.download >= 0 {
                let y = downloadToY(result.download)
                downloadColor.set()
                context?.fillEllipse(in: CGRect(center: CGPoint(x: x, y: y), radius: 3))
            } else if !result.succeeded {
                errorColor.set()
                var box = bounds.insetBy(dx: 102, dy: 102)
                box.origin.x = x
                box.size.width = 2
                box.fill()
            }
        }

        for result in results {
            let x = timeToX(result.timestamp!)
            if result.succeeded && result.download >= 0 {
                let y = uploadToY(result.upload)
                uploadColor.set()
                context?.fillEllipse(in: CGRect(center: CGPoint(x: x, y: y), radius: 3))
            }
            
        }

        for result in results {
            let x = timeToX(result.timestamp!)
            if result.succeeded && result.download >= 0 {
                let y = pingToY(result.ping)
                pingColor.set()
                context?.fillEllipse(in: CGRect(center: CGPoint(x: x, y: y), radius: 3))
            }
        }

        for result in results {
            let x = timeToX(result.timestamp!)
            if result.succeeded && result.download < 0 {
                let y = pingToY(result.ping)
                NSColor.blue.set()
                context?.fillEllipse(in: CGRect(center: CGPoint(x: x, y: y), radius: 1))
            }
        }
        context?.strokePath()
    }

    func refreshResults() {
        let managedObjectContext = (NSApp.delegate as! AppDelegate).moc
        let fetchRequest = NSFetchRequest<SpeedTestResult>(entityName: "SpeedTestResult")
        let day = datePicker.dateValue
        let dayStart = startOfDay(day)
        let dayEnd = nextDay(day)
        let predicate = NSPredicate(format: "timestamp between {%@, %@}", argumentArray: [dayStart, dayEnd])
        let sort = NSSortDescriptor(key: "timestamp", ascending: true)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sort]
        do {
            let fetchedResults = try managedObjectContext.fetch(fetchRequest)
            print("fetched \(fetchedResults.count) results")
            results = fetchedResults
        } catch let error as NSError {
            print(error.description)
        }

    }
}
