import 'dart:async';
import 'package:linkedfarm/Services/io_compatibility.dart' if (dart.library.html) 'package:linkedfarm/Services/web_compatibility.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/Services/chat_service.dart';
import 'package:linkedfarm/Chat/chat_model.dart';
import 'package:linkedfarm/Chat/group_model.dart';
import 'package:linkedfarm/Chat/group_info_page.dart';
import 'package:linkedfarm/Chat/comments_page.dart';
import 'package:linkedfarm/Chat/image_preview_page.dart';
import 'package:linkedfarm/Chat/video_player_page.dart';
import 'package:linkedfarm/Chat/widgets/chat_input_field.dart';
import 'package:linkedfarm/Chat/widgets/message_bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isUploading = false;
  GroupModel? _group;

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  void _loadGroupDetails() {
    FirebaseFirestore.instance.collection('groups').doc(widget.groupId).snapshots().listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _group = GroupModel.fromMap(doc.data() as Map<String, dynamic>);
        });
      }
    });
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendGroupMessage(
        widget.groupId,
        _messageController.text,
        type: MessageType.text,
      );
      _messageController.clear();
    }
  }

  Future<void> _pickAndSendMedia() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'mp4', 'mp3', 'pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      String ext = result.files.single.extension?.toLowerCase() ?? '';
      
      setState(() => _isUploading = true);
      
      try {
        MessageType type = MessageType.text;
        if (['jpg', 'png', 'jpeg'].contains(ext)) type = MessageType.image;
        else if (ext == 'mp4') type = MessageType.video;
        else if (ext == 'mp3') type = MessageType.audio;
        else if (ext == 'pdf') type = MessageType.pdf;

        String url = await _chatService.uploadMedia(file, 'group_media');
        
        await _chatService.sendGroupMessage(
          widget.groupId,
          "[Media: $fileName]",
          type: type,
          mediaUrl: url,
          fileName: fileName,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  void _openGroupInfo() {
    if (_group == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupInfoPage(
          groupId: _group!.groupId,
          groupName: _group!.name,
          memberIds: _group!.members,
          adminIds: _group!.adminIds,
          groupIconUrl: _group!.groupIconUrl,
          type: _group!.type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool canSend = true;
    if (_group != null && _group!.isChannel) {
      canSend = _group!.isAdmin(_auth.currentUser!.uid);
    }

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _openGroupInfo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.groupName),
              if (_group != null)
                Text(
                  "${_group!.members.length} ${_group!.isChannel ? 'subscribers' : 'members'}",
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
            ],
          ),
        ),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _openGroupInfo,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (canSend)
            _buildMessageInput()
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: const Text(
                "Muted Channel (Only admins can post)",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getGroupMessages(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No messages yet.'));
        }

        // Sort messages in memory to avoid Firestore index requirement
        final docs = snapshot.data!.docs;
        docs.sort((a, b) {
          Timestamp t1 = a['timestamp'];
          Timestamp t2 = b['timestamp'];
          return t1.compareTo(t2);
        });

        return ListView(
          padding: const EdgeInsets.all(10),
          children: docs
              .map((document) => _buildMessageItem(document))
              .toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    bool isMe = data['senderId'] == _auth.currentUser!.uid;
    String? mediaUrl = data['mediaUrl'];
    String? typeStr = data['messageType'];

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (typeStr == MessageType.image.name && mediaUrl != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImagePreviewPage(imageUrl: mediaUrl),
                ),
              );
            } else if (typeStr == MessageType.video.name && mediaUrl != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerPage(
                    videoUrl: mediaUrl,
                    title: data['fileName'] ?? "Video",
                  ),
                ),
              );
            }
          },
          child: MessageBubble(
            data: data,
            isMe: isMe,
            senderName: data['senderEmail'],
          ),
        ),
        if (_group != null && _group!.isChannel)
          Padding(
            padding: EdgeInsets.only(left: isMe ? 0 : 50, right: isMe ? 50 : 0, bottom: 10),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommentsPage(
                      groupId: widget.groupId,
                      parentMessageId: document.id,
                      originalMessage: data['message'],
                      originalSenderName: data['senderEmail'],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.comment_outlined, size: 14, color: Colors.orange),
              label: const Text("Leave a comment", style: TextStyle(fontSize: 12, color: Colors.orange)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return ChatInputField(
      controller: _messageController,
      onSend: sendMessage,
      onAttach: _pickAndSendMedia,
      isUploading: _isUploading,
    );
  }
}
