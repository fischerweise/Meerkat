//
//  RecentMessage.swift
//  Meerkat
//
//  Created by Mustafa Pekdemir on 22.05.2022.
//

import Foundation
import Firebase

struct RecentMessage: Identifiable {
    var id: String {documentId}
    let documentId: String
    let text, email: String
    let fromId, toId: String
    let profileImageURL: String
    let timestamp: Timestamp
   
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.text = data["text"] as? String ?? ""
        self.fromId = data["fromId"] as? String ?? ""
        self.toId = data["toId"] as? String ?? ""
        self.profileImageURL = data["profileImageURL"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
    }
}
