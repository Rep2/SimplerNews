import Vapor
import VaporMongo
import Foundation

let drop = Droplet()

try drop.addProvider(VaporMongo.Provider.self)

drop.preparations.append(Channel.self)
drop.preparations.append(Video.self)
drop.preparations.append(User.self)

let channels = ChannelsController()
drop.resource("channels", channels)

let videos = VideosController()
drop.resource("videos", videos)

drop.post("facebook") { request in
    try Facebook().facebookLogin(request: request)
}

drop.post("facebook/user") { request in
    try Facebook().facebookUser(request: request)
}

drop.post("facebook/user_details") { request in
    try Facebook().facebookGetUserDetails(request: request)
}

drop.post("twitter") { request in
    try Twitter().twitterLogin(request: request)
}

let timer = APICalls()

drop.run()
