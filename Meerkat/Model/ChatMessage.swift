//
//  ChatMessage.swift
//  Meerkat
//
//  Created by Mustafa Pekdemir on 22.05.2022.
//

import Foundation
import FirebaseFirestoreSwift

struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let fromId, toId, text: String
    let timestamp: Date
}
