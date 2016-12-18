import Vapor
import VaporMongo
import Foundation

let drop = Droplet()

try drop.addProvider(VaporMongo.Provider.self)

drop.preparations.append(Channel.self)
drop.preparations.append(Video.self)

let channels = ChannelsController()
drop.resource("channels", channels)

let videos = VideosController()
drop.resource("videos", videos)

let timer = APICalls()


drop.run()
