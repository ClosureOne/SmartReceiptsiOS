//
//  TripCSVGenerator.swift
//  SmartReceipts
//
//  Created by Bogdan Evsenev on 03/12/2017.
//  Copyright © 2017 Will Baumann. All rights reserved.
//

import Foundation

class TripCSVGenerator: ReportCSVGenerator {
    override func generateTo(path: String) -> Bool {
        do { try generateContent().write(to: path.asFileURL) }
        catch {
            Logger.error("CSV write error: \(error.localizedDescription)")
           return false
        }
        return true
    }
    
    private func generateContent() -> Data {
        let content = NSMutableString()
        appendReceiptsTable(content)
        appendDistancesTable(content)
        return (content as String).byteOrderMarked
    }
    
    private func appendReceiptsTable(_ content: NSMutableString) {
        let receiptTable = ReportCSVTable(content: content, columns: receiptColumns())!
        receiptTable.includeHeaders = WBPreferences.includeCSVHeaders()
        
        var recs = receipts()
        if WBPreferences.printDailyDistanceValues() {
            let dReceipts = DistancesToReceiptsConverter.convertDistances(distances()) as! [WBReceipt]
            recs.append(contentsOf: dReceipts)
            recs.sort(by: { $1.date.compare($0.date) == .orderedAscending })
        }
        receiptTable.append(withRows: recs)
    }
    
    private func appendDistancesTable(_ content: NSMutableString) {
        if !WBPreferences.printDistanceTable() { return }
        let dists = distances()
        if dists.isEmpty { return }
        content.append("\n\n")
        let receiptTable = ReportCSVTable(content: content, columns: distanceColumns())!
        receiptTable.includeHeaders = WBPreferences.includeCSVHeaders()
        receiptTable.append(withRows: dists)
    }
}
