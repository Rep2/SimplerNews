import Dispatch

public class APICalls {

    init() {
       callAPI()
    }

    func callAPI() {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) {

            print("sadadsasd")
            self.callAPI()
        }
       // try? YoutubeVideoAPI.fetchVideos()
    }
}
