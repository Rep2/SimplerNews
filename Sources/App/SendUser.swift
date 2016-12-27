import Vapor
import HTTP

final class SendUser {

    static func sendUser(user: User) throws {
        let body = try Body.data(JSON(node: user).makeBytes())

        let response = try drop.client.post("http://simplernewstest.azurewebsites.net/api/User/UpdateInfo", headers: ["Content-Type" : "application/json"], body: body)

        print(response)
    }

}
