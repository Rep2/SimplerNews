import Vapor

final class User: Model {
    var id: Node?
    var exists: Bool = false

    var email: String
    var facebookJSON: JSON?
    var twitterJSON: JSON?
    var googleJSON: JSON?

    init(email: String, facebookJSON: JSON?, twitterJSON: JSON?, googleJSON: JSON?) {
        self.id = nil
        self.email = email
        self.facebookJSON = facebookJSON
        self.twitterJSON = twitterJSON
        self.googleJSON = googleJSON
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        email = try node.extract("email")
        twitterJSON = try node.extract("twitterJSON")
        facebookJSON = try node.extract("facebookJSON")
        googleJSON = try node.extract("googleJSON")
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id,
            "email" : email,
            "facebookJSON" : facebookJSON,
            "twitterJSON" : twitterJSON,
            "googleJSON" : googleJSON
            ])
    }

    static func prepare(_ database: Database) throws {}
    static func revert(_ database: Database) throws {}
}
