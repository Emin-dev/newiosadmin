import Foundation

/// CSV export of the rows on screen. Ported from the old panel, including its
/// guard against spreadsheet formula injection.
public enum CSV {
    public static func make(_ records: [AdminRecord], translate: (String) -> String = { $0 }) -> String {
        var lines = [row([translate("ID"), translate("Title"), translate("Details"), translate("Status"), translate("Value"), translate("Created")])]
        let iso = ISO8601DateFormatter()
        for record in records {
            lines.append(row([
                record.id,
                record.title,
                record.subtitle,
                record.status.map { translate($0.key) } ?? "",
                record.trailing ?? "",
                iso.string(from: record.createdAt),
            ]))
        }
        return lines.joined(separator: "\r\n") + "\r\n"
    }

    static func row(_ cells: [String]) -> String {
        cells.map(escape).joined(separator: ",")
    }

    /// Quotes every cell and neutralises cells a spreadsheet would run as a formula.
    public static func escape(_ raw: String) -> String {
        var cell = raw
        if let first = cell.first, "=+-@\t\r".contains(first) {
            cell = "'" + cell
        }
        return "\"" + cell.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
