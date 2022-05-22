//
//  MainMessagesView.swift
//  Meerkat
//
//  Created by Mustafa Pekdemir on 18.05.2022.
//

import SwiftUI
import SDWebImageSwiftUI
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

class MainMessagesViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    init() {
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
            
        }
        fetchCurrentUser()
        fetchRecentMessages()
    }
    @Published var recentMessages = [RecentMessage]()
    private func fetchRecentMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        FirebaseManager.shared.firestore.collection("recent_messages").document(uid).collection("messages").order(by: "timestamp").addSnapshotListener { querySnapshot, error in
            if let error = error {
                self.errorMessage = "Failed to listen for recent messages: \(error)"
                print(error)
                return
            }
            querySnapshot?.documentChanges.forEach({ change in
                let docId = change.document.documentID
                if let index = self.recentMessages.firstIndex(where: { rm in
                    return rm.documentId == docId
                }) {
                    self.recentMessages.remove(at: index)
                }
                self.recentMessages.insert(.init(documentId: docId, data: change.document.data()), at: 0)
//                self.recentMessages.append()
            })
            
        }
    }
    func fetchCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            self.errorMessage = "Could not find the uid."
            return}
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = "Failed to fetch current user: \(error)"
                print("Failed to fetch current user:", error)
                return
            }
            guard let data = snapshot?.data() else {
                self.errorMessage = "No Data found"
                return }
            self.chatUser = .init(data: data)
        }
    }
    @Published var isUserCurrentlyLoggedOut = false
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

struct MainMessagesView: View {
    @State var shouldShowLogOutOptions = false
    @State var shouldNavigateToChatLogView = false
    @ObservedObject private var viewModel = MainMessagesViewModel()
    var body: some View {
        NavigationView {
            VStack {
                
                customNavBar
                messagesView
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    ChatLogView(chatUser: self.chatUser)
                }
            }
            .overlay(
                newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
    }
    private var customNavBar: some View {
        HStack(spacing: 14) {
            WebImage(url: URL(string: viewModel.chatUser?.profileImageURL ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(50)
                .overlay(RoundedRectangle(cornerRadius: 44)
                    .stroke(Color(.label), lineWidth: 1))
                .shadow(radius: 5)
            VStack(alignment: .leading, spacing: 4) {
                let email = viewModel.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
                Text(email)
                    .font(.system(size: 24, weight: .bold))
                     HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("Online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
            }
            Spacer()
            Button {
                shouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding()
        .actionSheet(isPresented: $shouldShowLogOutOptions) {
            .init(title: Text("Settings"), message: Text("What Do You Want To Do?"), buttons: [
                .destructive(Text("Sign Out"), action: {
                    print("Handle sign out")
                    viewModel.handleSignOut()
                }),
                .cancel()
            ])
        }
        .fullScreenCover(isPresented: $viewModel.isUserCurrentlyLoggedOut, onDismiss: nil) {
            LoginView(didCompleteLoginProcess: {
                self.viewModel.isUserCurrentlyLoggedOut = false
                self.viewModel.fetchCurrentUser()
            })
        }
    }
private var messagesView: some View {
    ScrollView {
        ForEach(viewModel.recentMessages) { recentMessage in
            VStack {
                NavigationLink {
                    Text("Destination")
                } label: {
                    HStack(spacing: 14) {
                        WebImage(url: URL(string: recentMessage.profileImageURL))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipped()
                            .cornerRadius(64)
                            .overlay(RoundedRectangle(cornerRadius: 64).stroke(Color.black, lineWidth: 2))
                            .shadow(radius: 5)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recentMessage.email)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(.label))
                            Text(recentMessage.text)
                                .font(.system(size: 14))
                                .foregroundColor(Color(.darkGray))
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Text("22d")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                Divider()
                    .padding(.vertical, 8)
            }.padding(.horizontal)
        }.padding(.bottom, 50)
    }
}
    @State var shouldShowNewMessageScreen = false
    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ Start A New Conversation")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
                .background(Color.blue)
                .cornerRadius(24)
                .padding(.horizontal)
                .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            NewMessageView(didSelectNewUser: {user in
                print(user.email)
                self.shouldNavigateToChatLogView.toggle()
                self.chatUser = user
            })
        }
    }
    @State var chatUser: ChatUser?
}

    struct MainMessagesView_Previews: PreviewProvider {
        static var previews: some View {
            MainMessagesView()
        }
    }

