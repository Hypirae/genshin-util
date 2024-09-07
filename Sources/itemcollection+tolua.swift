import Foundation 

extension ItemCollection {
    func makeValueString(_ item: Item) -> String {
        return "    ['\(item.name)'] = { id = \(item.id), quality = '\(item.quality ?? "")', title = '\(item.title ?? "")' },\n"
    }

    public func toLua() -> String {
        var lua = "return {\n"
        
        for item in items {
            lua += makeValueString(item)
        }

        lua += "}"

        return lua
    }
}