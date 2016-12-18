import Vapor
import HTTP

final class Video: Model {

    var id: Node?
    var exists: Bool = false

    let json: JSON

    static func fromYoutubeResponse(response: Response) throws -> Video {
        guard let items = response.json?["items"] else {
            throw Abort.custom(status: .badRequest, message: "Failed to parse video details response")
        }

        return Video(json: items.pathIndexableArray?.first ?? items)
    }

    init(json: JSON) {
        self.id = nil
        self.json = json
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        json = try node.extract("json")
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id,
            "json" : json
            ])
    }

    static func prepare(_ database: Database) throws {}
    static func revert(_ database: Database) throws {}

}
