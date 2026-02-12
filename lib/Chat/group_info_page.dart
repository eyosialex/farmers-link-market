import 'package:linkedfarm/Chat/chat_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linkedfarm/Services/io_compatibility.dart' if (dart.library.html) 'package:linkedfarm/Services/web_compatibility.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/User%20Credential/profile_page.dart';
import 'package:linkedfarm/User%20Credential/usermodel.dart';
import 'package:linkedfarm/Services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupInfoPage extends StatelessWidget {
  final String groupId;
  final String groupName;
  final List<String> memberIds;
  final List<String> adminIds;
  final String? groupIconUrl;
  final String type; // 'group' or 'channel'

  const GroupInfoPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.memberIds,
    required this.adminIds,
    this.groupIconUrl,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final ChatService chatService = ChatService();
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final bool isCurrentUserAdmin = adminIds.contains(currentUserId);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(type == 'channel' ? "Channel Info" : "Group Info"),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              children: [
                GestureDetector(
                  onTap: isCurrentUserAdmin ? () => _changeGroupPhoto(context, chatService) : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: type == 'channel' ? Colors.orange[100] : Colors.green[100],
                        backgroundImage: groupIconUrl != null ? NetworkImage(groupIconUrl!) : null,
                        child: groupIconUrl == null 
                          ? Icon(
                              type == 'channel' ? Icons.campaign : Icons.group,
                              size: 40,
                              color: type == 'channel' ? Colors.orange[700] : Colors.green[700],
                            )
                          : null,
                      ),
                      if (isCurrentUserAdmin)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  groupName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "${memberIds.length} ${type == 'channel' ? 'subscribers' : 'members'}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          // Members List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  type == 'channel' ? "SUBSCRIBERS" : "MEMBERS",
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (isCurrentUserAdmin)
                  TextButton.icon(
                    onPressed: () => _showAddMemberSheet(context, chatService),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add"),
                  ),
              ],
            ),
          ),

          // Members List
          Expanded(
            child: ListView.builder(
              itemCount: memberIds.length,
              itemBuilder: (context, index) {
                final String uid = memberIds[index];
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('Usersstore').doc(uid).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(title: Text("Loading..."));
                    }
                    if (!snapshot.hasData || snapshot.data?.data() == null) {
                      return const SizedBox();
                    }
                    var userData = snapshot.data!.data() as Map<String, dynamic>;
                    bool isMe = uid == currentUserId;
                    bool isTargetAdmin = adminIds.contains(uid);

                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(
                              userId: uid,
                              isMe: isMe,
                            ),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[50],
                        child: Text(userData['fullName'] != null && userData['fullName'].isNotEmpty 
                          ? userData['fullName'][0].toUpperCase()
                          : "?"),
                      ),
                      title: Row(
                        children: [
                          Text(userData['fullName']),
                          if (isTargetAdmin)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "ADMIN",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(userData['userType'] ?? "User"),
                      trailing: (isCurrentUserAdmin && !isMe)
                          ? IconButton(
                              icon: const Icon(Icons.person_remove, color: Colors.redAccent, size: 20),
                              onPressed: () => _confirmRemoval(context, chatService, uid, userData['fullName']),
                            )
                          : (type == 'channel' ? null : Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey[400])),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoval(BuildContext context, ChatService chatService, String uid, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Member"),
        content: Text("Are you sure you want to remove $name from this ${type == 'channel' ? 'channel' : 'group'}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              await chatService.removeMemberFromGroup(groupId, uid);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close Info page
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name removed")));
            },
            child: const Text("REMOVE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _changeGroupPhoto(BuildContext context, ChatService chatService) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      try {
        String url = await chatService.uploadMedia(File(pickedFile.path), 'group_icons');
        await chatService.updateGroupPhoto(groupId, url);
        Navigator.pop(context); // Refresh by closing
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Group photo updated")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update photo: $e")));
      }
    }
  }

  void _showAddMemberSheet(BuildContext context, ChatService chatService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMemberSheet(groupId: groupId, existingMembers: memberIds, chatService: chatService),
    );
  }
}

class _AddMemberSheet extends StatefulWidget {
  final String groupId;
  final List<String> existingMembers;
  final ChatService chatService;

  const _AddMemberSheet({required this.groupId, required this.existingMembers, required this.chatService});

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 4,
            width: 40,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const Text("Add Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for users...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.chatService.searchUsers(_query),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final users = snapshot.data!.docs.where((doc) => !widget.existingMembers.contains(doc.id)).toList();
                
                if (users.isEmpty) return const Center(child: Text("No new users found"));
                
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(userData['fullName'][0].toUpperCase()),
                      ),
                      title: Text(userData['fullName']),
                      subtitle: Text(userData['userType']),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add_alt_1, color: Colors.green),
                        onPressed: () async {
                          await widget.chatService.addMemberToGroup(widget.groupId, userDoc.id);
                          Navigator.pop(context); // Close sheet
                          Navigator.pop(context); // Close info to refresh
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${userData['fullName']} added")));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
