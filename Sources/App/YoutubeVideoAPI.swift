import Foundation
import Vapor

final class YoutubeVideoAPI {

    static var lastFetchDate = Date()

    static func youtubeAPIGetPlaylistVideos(playlistId: String) throws {
        let videosResponse = try drop.client.get("https://www.googleapis.com/youtube/v3/playlistItems?part=id,contentDetails&playlistId=\(playlistId)&key=AIzaSyBSsdJSTQ3uvLOH1MgN6joX_cxfs4Tmflw&maxResults=50")

        if let items = videosResponse.json?["items"]?.pathIndexableArray {
            for item in items {
                try videoFromYoutubeJSON(json: item)
            }
        }
    }

    static func videoFromYoutubeJSON(json: JSON) throws {
        guard let videoId = json["contentDetails"]?["videoId"]?.string, let videoPublishedAt = json["contentDetails"]?["videoPublishedAt"]?.string else {
            throw Abort.custom(status: .badRequest, message: "Youtube video item parsing failed")
        }

        let videoPublishedAtDate = try parseDate(date: videoPublishedAt)

        guard videoPublishedAtDate >= YoutubeVideoAPI.lastFetchDate else {
            return
        }

        var video = try fetchVideoDetails(id: videoId)

        try video.save()
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

}
