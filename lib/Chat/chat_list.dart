import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/Chat/chat_screen.dart';
import 'package:linkedfarm/Services/chat_service.dart';
import 'package:linkedfarm/User%20Credential/userfirestore.dart';
import 'package:flutter/material.dart';
import 'package:linkedfarm/Chat/create_group_screen.dart';
import 'package:linkedfarm/Chat/group_chat_page.dart';
import 'package:linkedfarm/User%20Credential/profile_page.dart';
import 'package:linkedfarm/User%20Credential/usermodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final UserRepository _userRepo = UserRepository();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isSearching 
          ? null 
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: FutureBuilder<UserModel?>(
                future: _userRepo.getUser(FirebaseAuth.instance.currentUser!.uid),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  String? photoUrl = user?.photoUrl;
                  String initial = (user?.fullName != null && user!.fullName.isNotEmpty) 
                    ? user.fullName[0].toUpperCase() 
                    : "?";

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(
                            userId: FirebaseAuth.instance.currentUser!.uid,
                            isMe: true,
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null 
                        ? Text(initial, style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold))
                        : null,
                    ),
                  );
                },
              ),
            ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Search members...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => setState(() {}),
              )
            : const Text("Chat"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: () => _showCreateGroupDialog(),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "MESSAGES"),
            Tab(text: "GROUPS"),
          ],
          indicatorColor: Colors.orange[400],
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: _isSearching ? _buildSearchResults() : TabBarView(
        controller: _tabController,
        children: [
          _buildChatList(),
          _buildGroupList(),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.searchUsers(_searchController.text),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var users = snapshot.data!.docs;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user['fullName']),
              subtitle: Text(user['userType']),
              onLongPress: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      userId: user.id,
                      isMe: user.id == FirebaseAuth.instance.currentUser!.uid,
                    ),
                  ),
                );
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      receiverUserEmail: user['email'],
                      receiverUserID: user.id,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getUserChats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("No messages yet");
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildChatListItem(doc);
          },
        );
      },
    );
  }

  Widget _buildGroupList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getUserGroups(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("No groups yet");
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final isChannel = data['type'] == 'channel';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isChannel ? Colors.orange[100] : Colors.green[100],
                  child: Icon(
                    isChannel ? Icons.campaign : Icons.group,
                    color: isChannel ? Colors.orange[800] : Colors.green[800],
                  ),
                ),
                title: Text(
                  doc['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  doc['lastMessage'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatDate(doc['timestamp']),
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupChatPage(
                        groupId: doc.id,
                        groupName: doc['name'],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChatListItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String otherUserId = data['otherUserId'];
    String lastMessage = data['lastMessage'] ?? "";
    Timestamp timestamp = data['timestamp'];

    return FutureBuilder(
      future: _userRepo.getUser(otherUserId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox.shrink(); // Loading state hidden
        }

        final user = userSnapshot.data!;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[100],
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : "?",
                style: TextStyle(color: Colors.green[800]),
              ),
            ),
            title: Text(
              user.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            trailing: Text(
              _formatDate(timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    receiverUserEmail: user.fullName,
                    receiverUserID: user.uid,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
  void _showCreateGroupDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
    );
  }
}
