//
//  FriendsView.swift
//  Jamminverz
//
//  Friends system for connecting with other producers
//

import SwiftUI

struct FriendsView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @State private var selectedTab = "friends"
    @State private var searchText = ""
    @State private var friends: [Friend] = []
    @State private var pendingRequests: [Friend] = []
    @State private var searchResults: [Friend] = []
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Selector
                tabSelector
                
                // Content
                ScrollView {
                    switch selectedTab {
                    case "friends":
                        friendsList
                    case "requests":
                        requestsList
                    case "search":
                        searchView
                    default:
                        EmptyView()
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            loadFriends()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("FRIENDS")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundColor(.white)
                
                Text("Connect with other producers")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Friend count
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(friends.count)")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.green)
                Text("FRIENDS")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var tabSelector: some View {
        HStack(spacing: 32) {
            TabButton(title: "FRIENDS", isSelected: selectedTab == "friends") {
                selectedTab = "friends"
            }
            
            TabButton(title: "REQUESTS", isSelected: selectedTab == "requests") {
                selectedTab = "requests"
                if !pendingRequests.isEmpty {
                    Text("\(pendingRequests.count)")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(10)
                        .offset(x: -8, y: -8)
                }
            }
            
            TabButton(title: "FIND FRIENDS", isSelected: selectedTab == "search") {
                selectedTab = "search"
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
    }
    
    private var friendsList: some View {
        VStack(spacing: 12) {
            if friends.isEmpty {
                emptyFriendsState
            } else {
                ForEach(friends) { friend in
                    FriendRow(friend: friend) {
                        // View profile action
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    private var requestsList: some View {
        VStack(spacing: 12) {
            if pendingRequests.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.badge.clock")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Pending Requests")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.gray)
                }
                .padding(.top, 100)
            } else {
                ForEach(pendingRequests) { request in
                    FriendRequestRow(
                        friend: request,
                        onAccept: { acceptRequest(request) },
                        onDecline: { declineRequest(request) }
                    )
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    private var searchView: some View {
        VStack(spacing: 20) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search by username...", text: $searchText)
                    .foregroundColor(.white)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        searchUsers()
                    }
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            
            // Search Results
            if !searchResults.isEmpty {
                VStack(spacing: 12) {
                    ForEach(searchResults) { user in
                        SearchResultRow(user: user) {
                            sendFriendRequest(user)
                        }
                    }
                }
                .padding(.horizontal, 24)
            } else if !searchText.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No users found")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.gray)
                }
                .padding(.top, 100)
            }
        }
        .padding(.top, 20)
    }
    
    private var emptyFriendsState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Friends Yet")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(.white)
            
            Text("Search for other producers to connect")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Button(action: {
                selectedTab = "search"
            }) {
                Text("FIND FRIENDS")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(30)
            }
        }
        .padding(.top, 100)
    }
    
    private func loadFriends() {
        // Mock data
        friends = [
            Friend(id: "1", username: "beatmaker23", displayName: "BeatMaker", avatar: "🎵", isOnline: true),
            Friend(id: "2", username: "synthwave_pro", displayName: "SynthWave Pro", avatar: "🎹", isOnline: false),
            Friend(id: "3", username: "lofi_vibes", displayName: "Lofi Vibes", avatar: "🎧", isOnline: true)
        ]
        
        pendingRequests = [
            Friend(id: "4", username: "trap_lord", displayName: "Trap Lord", avatar: "🔥", isOnline: true)
        ]
    }
    
    private func searchUsers() {
        // Mock search
        searchResults = [
            Friend(id: "5", username: "producer_mike", displayName: "Producer Mike", avatar: "🎤", isOnline: false),
            Friend(id: "6", username: "bass_head", displayName: "Bass Head", avatar: "🔊", isOnline: true)
        ]
    }
    
    private func sendFriendRequest(_ user: Friend) {
        searchResults.removeAll { $0.id == user.id }
    }
    
    private func acceptRequest(_ request: Friend) {
        friends.append(request)
        pendingRequests.removeAll { $0.id == request.id }
    }
    
    private func declineRequest(_ request: Friend) {
        pendingRequests.removeAll { $0.id == request.id }
    }
}

// MARK: - Friend Model
struct Friend: Identifiable {
    let id: String
    let username: String
    let displayName: String
    let avatar: String
    let isOnline: Bool
}

// MARK: - Friend Row
struct FriendRow: View {
    let friend: Friend
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Avatar
                ZStack(alignment: .bottomTrailing) {
                    Text(friend.avatar)
                        .font(.system(size: 30))
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                    
                    // Online indicator
                    Circle()
                        .fill(friend.isOnline ? Color.green : Color.gray)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text("@\(friend.username)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Friend Request Row
struct FriendRequestRow: View {
    let friend: Friend
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Text(friend.avatar)
                .font(.system(size: 30))
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                
                Text("@\(friend.username) wants to be friends")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.green)
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let user: Friend
    let onAddFriend: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Text(user.avatar)
                .font(.system(size: 30))
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                
                Text("@\(user.username)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onAddFriend) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.green)
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    FriendsView(
        taskStore: TaskStore(),
        currentTab: .constant("friends")
    )
}