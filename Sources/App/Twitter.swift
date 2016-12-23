import Vapor
import HTTP
import Foundation

final class Twitter  {

    func twitterLogin(request: Request) throws -> ResponseRepresentable {
        guard let bytes = request.body.bytes, let json = try JSONSerialization.jsonObject(with: Data(bytes: bytes), options: .allowFragments) as? [String : Any] else {
            throw Abort.custom(status: .badRequest, message: "Expected JSON body")
        }

        guard let email = json["email"] as? String, let _ = json["access_token"] as? String else {
            throw Abort.custom(status: .badRequest, message: "JSON body with email and access_token expected")
        }

        let accessToken = UUID().uuidString

        if let users = try? User.query().filter("email", email).run(), var user = users.first {
            user.twitterJSON = try JSON(bytes: bytes)
            user.accessToken = accessToken

            try user.save()

            return try JSON(node: user.makeNode())
        } else {
            return User(email: email, accessToken: accessToken, twitterJSON: try? JSON(bytes: bytes))
        }
    }
    
}
