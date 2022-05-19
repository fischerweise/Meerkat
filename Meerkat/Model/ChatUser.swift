//
//  ChatUser.swift
//  Meerkat
//
//  Created by Mustafa Pekdemir on 19.05.2022.
//

import Foundation

struct ChatUser: Identifiable {
    var id: String {uid}
    
    let uid, email, profileImageURL: String
    init(data: [String: Any]) {
        self.uid = data["uid"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.profileImageURL = data["profileImageURL"] as? String ?? ""
    }
}
