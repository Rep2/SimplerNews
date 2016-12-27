import Vapor
import HTTP
import Foundation
import Dispatch

final class Facebook {

    let clientId = "1222106867859667"
    let clientSecret = "0505e368b2c9112a82afb1129e0d71d7"

    func facebookLogin(request: Request) throws -> ResponseRepresentable {
        guard let accessToken = request.data["access_token"]?.string else {
            throw Abort.custom(status: .badRequest, message: "Parameter access_token:string is required")
        }

        let userId = try validateAccessToken(accessToken: accessToken, appAccessToken: getFacebookAppAccessToken())

        let apiAccessToken = UUID().uuidString

        DispatchQueue.global(qos: .utility).async {
            do {
                var user = try self.loginUser(userId: userId, accessToken: accessToken, apiAccessToken: apiAccessToken)

                try SendUser.sendUser(user: user)

                let userDetails = try self.fetchUserDetails(userId: userId, accessToken: accessToken)

                user.facebookJSON = userDetails

                try user.save()

                try SendUser.sendUser(user: user)
            } catch {
                print("Fetch details faield")
            }
        }

        return apiAccessToken
    }

    func getFacebookAppAccessToken() throws -> String {
        let response = try drop.client.post(
            "https://graph.facebook.com/oauth/access_token?" +
            "client_id=\(clientId)" +
            "&client_secret=\(clientSecret)" +
            "&grant_type=client_credentials")

        if let bytes = response.body.bytes, let body = try? String(bytes: bytes) {
            return body.replacingOccurrences(of: "access_token=", with: "")
        } else {
            throw Abort.custom(status: .badRequest, message: "Failed to fetch Facebook app access token")
        }
    }

    func validateAccessToken(accessToken: String, appAccessToken: String) throws -> String {
        let url =  "https://graph.facebook.com/debug_token?" +
            "input_token=\(accessToken)" +
            "&access_token=\(appAccessToken)"

        guard let escapedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw Abort.custom(status: .badRequest, message: "Failed to escape Facebook appAccessToken")
        }

        let response = try drop.client.get(escapedURL)

        guard let bytes = response.body.bytes else {
            throw Abort.custom(status: .badRequest, message: "Failed to parse Facebook response")
        }

        guard let body = try? JSONSerialization.jsonObject(with: Data(bytes: bytes), options: []) else {
            throw Abort.custom(status: .badRequest, message: "Failed to parse JSON Facebook response")
        }

        if let json = body as? [String : Any], let data = json["data"] as? [String : Any], let userId = data["user_id"] as? String {
            return userId
        } else {
            throw Abort.custom(status: .badRequest, message: "Failed to get user id")
        }
    }

    func loginUser(userId: String, accessToken: String, apiAccessToken: String) throws -> User {
        let response = try drop.client.get(
            "https://graph.facebook.com/v2.8/" +
                "\(userId)" +
            "?fields=email",
            headers: ["Authorization" : "Bearer \(accessToken)"])

        guard let bytes = response.body.bytes, let body = try? JSONSerialization.jsonObject(with: Data(bytes: bytes), options: []) else {
            throw Abort.custom(status: .badRequest, message: "Failed to parse Facebook user response")
        }

        if let body = body as? [String : Any], let email = body["email"] as? String {
            if let users = try? User.query().filter("email", email).run(), let user = users.first {
                user.accessToken = apiAccessToken

                return user
            } else {
                return User(email: email, accessToken: apiAccessToken)
            }
        } else {
            throw Abort.custom(status: .badRequest, message: "Failed to fetch users email")
        }
    }

    func fetchUserDetails(userId: String, accessToken: String) throws -> JSON {
        let response = try drop.client.get(
            "https://graph.facebook.com/v2.8/" +
            "\(userId)" +
            "?fields=email,name,gender,sports,age_range,languages,location,political,likes.limit(50)",
            headers: ["Authorization" : "Bearer \(accessToken)"])

        guard let bytes = response.body.bytes, let body = try? JSONSerialization.jsonObject(with: Data(bytes: bytes), options: []) else {
            throw Abort.custom(status: .badRequest, message: "Failed to parse Facebook user response")
        }

        if let body = body as? [String : Any], let likesBody = body["likes"] as? [String : Any], let likes = likesBody["data"] as? [[String : String]] {

            var pages = [JSON]()

            for like in likes {
                if let pageId = like["id"], let likedDate = like["created_time"], let page = try? fetchFacebookPage(pageId: pageId, accessToken: accessToken, likedDate: likedDate) {
                    pages.append(page)
                }
            }

            var details = userDetails(body: body, accessToken: accessToken)
            details["likes"] = try? JSON(node: pages)

            return try JSON(node: details)
        } else {
            throw Abort.badRequest
        }
    }

    func fetchFacebookPage(pageId: String, accessToken: String, likedDate: String) throws -> JSON {
        let response = try drop.client.get(
            "https://graph.facebook.com/v2.8/\(pageId)" +
            "?fields=about,category,description",
            headers: ["Authorization" : "Bearer \(accessToken)"])

        guard let bytes = response.body.bytes, let body = try? JSONSerialization.jsonObject(with: Data(bytes: bytes), options: []) else {
            throw Abort.custom(status: .badRequest, message: "Failed to parse Facebook page response")
        }

        guard var editableBody = body as? [String : String] else {
            throw Abort.custom(status: .badRequest, message: "Invalid facebook page response")
        }

        editableBody["liked_date"] = likedDate

        return try JSON(bytes: JSONSerialization.data(withJSONObject: editableBody, options: []).makeBytes())
    }

    func userDetails(body: [String : Any], accessToken: String) -> [String : NodeRepresentable] {
        var data = [String : NodeRepresentable]()

        data["name"] = body["name"] as? String
        data["gender"] = body["gender"] as? String
        data["facebook_id"] = body["id"] as? String
        data["access_token"] = accessToken

        return data
    }

}
