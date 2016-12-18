import Vapor
import HTTP

let youtubeAPIKey = "AIzaSyBSsdJSTQ3uvLOH1MgN6joX_cxfs4Tmflw"

final class ChannelsController: ResourceRepresentable {

    func index(request: Request) throws -> ResponseRepresentable {
        return try JSON(node: Channel.all().makeNode())
    }

    func create(request: Request) throws -> ResponseRepresentable {
        let channelName = try Channel.nameFromRequest(request: request)

        var channel = try youtubeAPIGetChannel(for: channelName)

        try channel.save()

        return channel
    }

    func show(request: Request, channel: Channel) throws -> ResponseRepresentable {
        return channel
    }

    func delete(request: Request, channel: Channel) throws -> ResponseRepresentable {
        try channel.delete()

        return ""
    }

    func youtubeAPIGetChannel(for name: String) throws -> Channel {
        let channelResponse = try drop.client.get("https://www.googleapis.com/youtube/v3/channels?part=contentDetails&key=\(youtubeAPIKey)&forUsername=\(name)")

        return try Channel.from(youtubeAPIChannelResponse: channelResponse, for: name)
    }


    func makeResource() -> Resource<Channel> {
        return Resource(
            index: index,
            store: create,
            show: show,
            destroy: delete
        )
    }
}
