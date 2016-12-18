import Foundation
import Vapor
import HTTP

final class YoutubeVideoAPI {

    static var lastFetchDate = Date()

    static func fetchVideos() throws {
        let channels = try Channel.all()

        var allVideos = [Video]()

        for channel in channels {
            if let videos = try? YoutubeVideoAPI.youtubeAPIGetPlaylistVideos(playlistId: channel.uploadPlaylsitId) {
                allVideos.append(contentsOf: videos)
            }
        }

        YoutubeVideoAPI.lastFetchDate = Date()

        try sendChannelsToBaseAPI(channels: Channel.all())
        try sendVideosToBaseAPI(videos: allVideos)
    }

    static func youtubeAPIGetPlaylistVideos(playlistId: String) throws -> [Video] {
        let videosResponse = try drop.client.get("https://www.googleapis.com/youtube/v3/playlistItems?part=id,contentDetails&playlistId=\(playlistId)&key=AIzaSyBSsdJSTQ3uvLOH1MgN6joX_cxfs4Tmflw&maxResults=50")

        var videos = [Video]()

        if let items = videosResponse.json?["items"]?.pathIndexableArray {
            for item in items {
                if let video = try? videoFromYoutubeJSON(json: item) {
                    videos.append(video)
                }
            }
        }

        return videos
    }

    static func videoFromYoutubeJSON(json: JSON) throws -> Video {
        guard let videoId = json["contentDetails"]?["videoId"]?.string, let videoPublishedAt = json["contentDetails"]?["videoPublishedAt"]?.string else {
            throw Abort.custom(status: .badRequest, message: "Youtube video item parsing failed")
        }

        let videoPublishedAtDate = try parseDate(date: videoPublishedAt)

        guard videoPublishedAtDate >= YoutubeVideoAPI.lastFetchDate else {
            throw Abort.custom(status: .badRequest, message: "Video parsing failed")
        }

        var video = try fetchVideoDetails(id: videoId)

        try video.save()

        return video
    }

    static func fetchVideoDetails(id: String) throws -> Video {
        let videoResponse = try drop.client.get("https://www.googleapis.com/youtube/v3/videos?part=id,snippet,statistics,topicDetails&id=\(id)&key=\(youtubeAPIKey)")

        return try Video.fromYoutubeResponse(response: videoResponse)
    }

    static func parseDate(date: String) throws -> Date {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        guard let videoPublishedAtDate = dateFormater.date(from: date) else {
            throw Abort.custom(status: .badRequest, message: "Date \(date) could not be formated")
        }
        
        return videoPublishedAtDate
    }

    static func sendVideosToBaseAPI(videos: [Video]) throws {
        let body = try Body.data(JSON(node: videos).makeBytes())

        let response = try drop.client.post("http://simplernewstest.azurewebsites.net/api/Video/InsertBulk", headers: ["Content-Type" : "application/json"], body: body)

        print(response)
    }

    static func sendChannelsToBaseAPI(channels: [Channel]) throws {
        let json = channels.map { try? $0.jsonFormAPI() }.flatMap { $0 }
        let body = try Body.data(JSON(node: json).makeBytes())

        _ = try drop.client.post("http://simplernewstest.azurewebsites.net/api/YoutubeChannel/InsertOrUpdateBulk", headers: ["Content-Type" : "application/json"], body: body)
    }


}
