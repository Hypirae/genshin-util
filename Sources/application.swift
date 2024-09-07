import Foundation
import ArgumentParser
import Just

@main
struct Main: AsyncParsableCommand {
    @Option(name: .shortAndLong, help: "Load items from a CSV file")
    var csv: String?

    @Option(name: .shortAndLong, help: "Load items from a wiki URL")
    var wiki: String?

    @Flag(name: .long, help: "Convert items to Lua")
    var toLua = false

    @Flag(name: .long, help: "Convert items to CSV")
    var toCsv = false

    func dataToString(_ data: Data) -> String {
        return String(data: data, encoding: .utf8)!
    }

    func parseLines(_ lines: [String]) -> [Item] {
        let pattern = "(\\['(.*?)'\\] = \\{ ([^{}]*?,?\\s?)? \\},)"
        let regex = (try? NSRegularExpression(pattern: pattern))!
        var items = [Item]()
        var captures = [String: String]()


        for line in lines {
            let matches = regex.matches(in: line, range: NSRange(line.startIndex..., in: line))

            // iterate through matches
            for match in matches {
                if match.numberOfRanges != 4 {
                    continue
                }

                let keyRange = Range(match.range(at: 2), in: line)!
                let valueRange = Range(match.range(at: 3), in: line)!
                let key = String(line[keyRange])
                let value = String(line[valueRange])

                captures[key] = value
            }
        }

        for (key, value) in captures {
            let name = key
            var id = ""
            var quality: String?
            var title: String?
            let values = value.components(separatedBy: ",")

            for value in values {
                let parts = value.components(separatedBy: "=")

                if parts.count != 2 {
                    continue
                }

                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                                            .trimmingCharacters(in: .init(charactersIn: "'"))

                if key == "id" {
                    id = value
                } else if key == "quality" {
                    quality = value
                } else if key == "title" {
                    title = value
                }
            }

            items.append(Item(name: name, quality: quality, title: title, id: id))
        }

        return items
    }

    func isolateRows(_ str: String) -> [String] {
        var lines = str.components(separatedBy: "\n")

        // remove first and last line
        lines.removeFirst()
        lines.removeLast()

        return lines
    }

    func load(csv file: URL) throws -> ItemCollection {
        let data = try Data(contentsOf: file)
        let lines = dataToString(data).components(separatedBy: .newlines)
        var items = [Item]()
        
        for line in lines {
            let components = line.components(separatedBy: ",")
            let name = components[0]
            let id = components[1]
            let quality = components[2]
            let title = components[3]
            
            let item = Item(name: name, quality: quality, title: title, id: id)
            items.append(item)
        }

        return ItemCollection(items: items)
    }

    func load(wiki url: URL) async -> ItemCollection {
        let response = Just.get(url)
        let body = response.content!
        let rows = isolateRows(dataToString(body))
        let items = parseLines(rows)

        return ItemCollection(items: items)
    }

    mutating func run() async throws {
        switch (csv, wiki) {
        case (.some(let file), .none):
            let url = URL(fileURLWithPath: file)
            let items = try load(csv: url)

            if toLua {
                print(items.toLua())
            } else if toCsv {
                print(items.toCsv())
            } else {
                print(items)
            }

        case (.none, .some(let url)):
            let url = URL(string: url)!
            let items = await load(wiki: url)

            if toLua {
                print(items.toLua())
            } else if toCsv {
                print(items.toCsv())
            } else {
                print(items)
            }
        default:
            print("Invalid arguments")
        }
    }
}