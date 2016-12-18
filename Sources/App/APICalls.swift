import Foundation

public class APICalls {

    init() {
        callAPI()
    }

    func callAPI() {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 10, execute: {
            try? YoutubeVideoAPI.fetchVideos()
            
            self.callAPI()
        })
    }
}
