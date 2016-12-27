import Vapor
import HTTP
import Foundation

final class Google {

    let serverKey = "AIzaSyCBRqxdYBflBz764vRu6kjlBTx66VlROMM"

    func login(request: Request) throws -> ResponseRepresentable {
        guard let idToken = request.data["id_token"]?.string else {
            throw Abort.custom(status: .badRequest, message: "Parameter id_token:string is required")
        }

        let (userId, email) = try verifyUser(idToken: idToken)

        return try fetchUserProfile(userId: userId, email: email)
    }

    func verifyUser(idToken: String) throws -> (String, String) {
        let response = try drop.client.get("https://www.googleapis.com/oauth2/v3/tokeninfo?" +
            "id_token=\(idToken)")

        guard let bytes = response.body.bytes, let body = try? JSONSerialization.jsonObject(with: Data(bytes: bytes), options: []) else {
            throw Abort.custom(status: .badRequest, message: "Failed to parse Google verification response")
        }

        if let body = body as? [String : String], let userId = body["sub"], let email = body["email"] {
            return (userId, email)
        } else {
            throw Abort.custom(status: .badRequest, message: "Failed to get Google user id")
        }
    }

    func fetchUserProfile(userId: String, email: String) throws -> User {
        let response = try drop.client.get("https://content.googleapis.com/plus/v1/people/" +
            "\(userId)?" +
            "key=\(serverKey)")

        guard let bytes = response.body.bytes, let body = try? JSONSerialization.jsonObject(with: Data(bytes: bytes), options: []) else {
            throw Abort.custom(status: .badRequest, message: "Failed to parse Google user response")
        }

        if let _ = body as? [String : Any] {
            let accessToken = UUID().uuidString

            var user: User

            if let users = try? User.query().filter("email", email).run(), let oldUser = users.first {
                user = oldUser
                user.accessToken = accessToken
            } else {
                user = User(email: email, accessToken: accessToken)
            }

            user.googleJSON = try JSON(bytes: bytes)

            try user.save()

            return user
        } else {
            throw Abort.custom(status: .badRequest, message: "Failed to get Google user profile")
        }
    }
}
