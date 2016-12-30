import Dispatch

public class APICalls {

    init() {
       callAPI()
    }

    func callAPI() {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1500) {
            try? YoutubeVideoAPI.fetchVideos()
            self.callAPI()
        }
    }
}
