import Vapor
import HTTP
import Foundation

class VideosController: ResourceRepresentable {

    func index(request: Request) throws -> ResponseRepresentable {
        return try JSON(node: Video.all().makeNode())
    }

    func create(request: Request) throws -> ResponseRepresentable {
        let channels = try Channel.all()

        for channel in channels {
            try? YoutubeVideoAPI.youtubeAPIGetPlaylistVideos(playlistId: channel.uploadPlaylsitId)
        }

        YoutubeVideoAPI.lastFetchDate = Date()

        return ""
    }

    func show(request: Request, video: Video) throws -> ResponseRepresentable {
        return video
    }

    func delete(request: Request, video: Video) throws -> ResponseRepresentable {
        try video.delete()

        return ""
    }

    func makeResource() -> Resource<Video> {
        return Resource(
            index: index,
            store: create,
            show: show,
            destroy: delete
        )
    }
}
