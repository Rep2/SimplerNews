import Vapor
import HTTP

final class Channel: Model {

    var id: Node?
    var exists: Bool = false

    var name: String
    var youtubeChannelId: String
    var uploadPlaylsitId: String

    static func from(youtubeAPIChannelResponse: Response, for name: String) throws -> Channel{
        if let items = youtubeAPIChannelResponse.json?["items"] {
            if let youtubeChannelId = items["id"]?[0]?.string, let uploadPlaylistId = items["contentDetails"]?["relatedPlaylists"]?["uploads"]?[0]?.string {
                return Channel(name: name, youtubeChannelId: youtubeChannelId, uploadPlaylsitId: uploadPlaylistId)
            }
        }

        throw Abort.custom(status: .badRequest, message: "Youtube did not return valid response for given channel name \(name)")
    }

    init(name: String, youtubeChannelId: String, uploadPlaylsitId: String) {
        self.id = nil
        self.name = name
        self.youtubeChannelId = youtubeChannelId
        self.uploadPlaylsitId = uploadPlaylsitId
    }

    static func nameFromRequest(request: Request) throws -> String {
        guard let name = request.data["channel_name"]?.string else {
            throw Abort.custom(status: .badRequest, message: "Parameter channel_name:string is required")
        }

        guard try Channel.query().filter("name", name).first() == nil else {
            throw Abort.custom(status: Status.conflict, message: "Channel with name \(name) already exists")
        }

        return name
    }


    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
        youtubeChannelId = try node.extract("youtube_channel_id")
        uploadPlaylsitId = try node.extract("upload_playlist_id")
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id,
            "name" : name,
            "youtube_channel_id" : youtubeChannelId,
            "upload_playlist_id" : uploadPlaylsitId
            ])
    }

    func jsonFormAPI() throws -> Node {
        return try Node(node: [
            "Id" : 0,
            "Name" : name,
            "YoutubeChannelId" : youtubeChannelId,
            "UploadPlaylistId" : uploadPlaylsitId
            ])
    }

    static func prepare(_ database: Database) throws {}
    static func revert(_ database: Database) throws {}
}
