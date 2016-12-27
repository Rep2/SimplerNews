import Vapor
import HTTP
import Foundation
import Dispatch

final class Google {

    let serverKey = "AIzaSyCBRqxdYBflBz764vRu6kjlBTx66VlROMM"

    func login(request: Request) throws -> ResponseRepresentable {
        guard let idToken = request.data["id_token"]?.string else {
            throw Abort.custom(status: .badRequest, message: "Parameter id_token:string is required")
        }

        let (userId, email) = try verifyUser(idToken: idToken)

        let accessToken = UUID().uuidString

        DispatchQueue.global(qos: .utility).async {
            do {
                var user = self.fetchUser(email: email, accessToken: accessToken)

                try SendUser.sendUser(user: user)

                let userProfile = try self.fetchUserProfile(userId: userId, user: user)
                user.googleJSON = userProfile

                try user.save()

                try SendUser.sendUser(user: user)
            } catch {
                print("Fetch details faield")
            }
        }

        return accessToken
    }

    func user(request: Request) throws -> ResponseRepresentable {
        guard let email = request.data["email"]?.string else {
            throw Abort.custom(status: .badRequest, message: "Parameter email:string is required")
        }

        let accessToken = UUID().uuidString

        return fetchUser(email: email, accessToken: accessToken)
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

    func fetchUser(email: String, accessToken: String) -> User {
        var user: User

        if let users = try? User.query().filter("email", email).run(), let oldUser = users.first {
            user = oldUser
            user.accessToken = accessToken
        } else {
            user = User(email: email, accessToken: accessToken)
        }

        return user
    }

    func fetchUserProfile(userId: String, user: User) throws -> JSON {
        let response = try drop.client.get("https://content.googleapis.com/plus/v1/people/" +
            "\(userId)?" +
            "key=\(serverKey)")

        guard let bytes = response.body.bytes, let _ = try? JSONSerialization.jsonObject(with: Data(bytes: bytes), options: []) else {
            throw Abort.custom(status: .badRequest, message: "Failed to parse Google user response")
        }

        return try JSON(bytes: bytes)
    }
}
