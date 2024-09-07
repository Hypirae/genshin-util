import Foundation

extension ItemCollection {
    func toCsv() -> String {
        var csv = "name,id,quality,title\n"
        
        for item in items {
            csv += "\(item.name),\(item.id),\(item.quality ?? ""),\(item.title ?? "")\n"
        }
        
        return csv
    }
}