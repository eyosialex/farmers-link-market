import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/User%20Credential/log_in_page.dart';
import 'package:linkedfarm/Advisor%20View/my_articles.dart';
import 'package:linkedfarm/Advisor%20View/post_advice_screen.dart';
import 'package:linkedfarm/Chat/chat_list.dart';
import 'package:linkedfarm/Chat/chat_screen.dart';
import 'package:linkedfarm/Main%20Office/main_office_page.dart';
import 'package:linkedfarm/Vendors%20View/NotificationCenterScreen.dart';
import 'package:linkedfarm/Services/chat_service.dart';
import 'package:linkedfarm/User%20Credential/userfirestore.dart';
import 'package:linkedfarm/Farmers%20View/Market_Prices.dart';
import 'package:linkedfarm/Advisor%20View/manage_courses_screen.dart';
import 'package:intl/intl.dart';

class AdvisorHomePage extends StatefulWidget {
  const AdvisorHomePage({super.key});

  @override
  State<AdvisorHomePage> createState() => _AdvisorHomePageState();
}

class _AdvisorHomePageState extends State<AdvisorHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService();
  final UserRepository _userRepo = UserRepository();

  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LogInPage(onTap: () {})),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final currentUserId = user?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Sleek Sliver App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.green[800],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/advice.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.green[900]),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Back,",
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                        ),
                        Text(
                          user?.email?.split('@')[0].toUpperCase() ?? "Expert Advisor",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MainOfficePage())),
                icon: const Icon(Icons.business_rounded, color: Colors.white),
              ),
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationCenterScreen())),
                icon: const Icon(Icons.notifications_none, color: Colors.white),
              ),
              IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),

          // 2. Main Dashboard Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Advisor Stats Card
                  _buildStatsCard(currentUserId),
                  const SizedBox(height: 25),

                  // Consultation Preview Heading
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Consultations",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Icon(Icons.arrow_forward, size: 18, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildConsultationPreview(),

                  const SizedBox(height: 30),

                  // Quick Actions Grid
                  const Text(
                    "Quick Actions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 15),
                  _buildQuickActionsGrid(context),

                  const SizedBox(height: 30),

                  // Market Price Summary Widget
                  const Text(
                    "Market Overview",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 15),
                  _buildMarketOverviewCard(context),

                  const SizedBox(height: 50), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostAdviceScreen())),
        label: const Text("Post Advice", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange[700],
      ),
    );
  }

  Widget _buildStatsCard(String userId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Articles", _countArticles(userId), Colors.blue),
          _divider(),
          _buildStatItem("Total Likes", _countLikes(userId), Colors.red),
          _divider(),
          _buildStatItem("Score", Stream.value("4.8"), Colors.orange),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 30, width: 1, color: Colors.grey[200]);

  Widget _buildStatItem(String label, Stream<dynamic> stream, Color color) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        return Column(
          children: [
            Text(
              snapshot.hasData ? snapshot.data.toString() : "0",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        );
      },
    );
  }

  Stream<int> _countArticles(String userId) {
    return FirebaseFirestore.instance
        .collection('advice_posts')
        .where('authorId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> _countLikes(String userId) {
    return FirebaseFirestore.instance
        .collection('advice_posts')
        .where('authorId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          int total = 0;
          for (var doc in snap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            total += (data['likes'] ?? 0) as int;
          }
          return total;
        });
  }

  Widget _buildConsultationPreview() {
    return SizedBox(
      height: 110,
      child: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getUserChats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(child: Text("No active consultations", style: TextStyle(color: Colors.grey))),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.docs.length.clamp(0, 5),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final otherUserId = data['otherUserId'];
              
              return FutureBuilder(
                future: _userRepo.getUser(otherUserId),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox.shrink();
                  final user = userSnap.data!;
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(receiverUserEmail: user.fullName, receiverUserID: user.uid))),
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 15),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.green[100],
                            child: Text(user.fullName[0], style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.fullName.split(' ')[0],
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {'label': 'My Articles', 'icon': Icons.library_books, 'color': Colors.indigo, 'page': const MyArticlesScreen()},
      {'label': 'Chat List', 'icon': Icons.chat_bubble, 'color': Colors.green, 'page': const ChatListScreen()},
      {'label': 'Course Hub', 'icon': Icons.school, 'color': Colors.teal, 'onTap': () => _navigateToManageCourses(context)},
      {'label': 'Market Prices', 'icon': Icons.show_chart, 'color': Colors.orange, 'page': const MarketPricesPage()},
      {'label': 'AI Assistant', 'icon': Icons.auto_awesome, 'color': Colors.purple, 'onTap': () => _showAIAssistant(context)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.6,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: action['onTap'] ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => action['page'])),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action['icon'], color: action['color'], size: 28),
                const SizedBox(height: 8),
                Text(action['label'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarketOverviewCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
      ),
      child: Column(
        children: [
           const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Maize", style: TextStyle(fontWeight: FontWeight.w500)),
              Text("3,000 ETB", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const Divider(),
           const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Wheat", style: TextStyle(fontWeight: FontWeight.w500)),
              Text("3,800 ETB", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketPricesPage())),
            child: const Text("View All Prices"),
          ),
        ],
      ),
    );
  }

  void _showAIAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("AI Expert Assistant", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 10),
            Text("How can I help you today?", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            _buildAIOption("Draft an article on soil health", Icons.edit_note, Colors.blue),
            _buildAIOption("Analyze current market trends", Icons.trending_up, Colors.green),
            _buildAIOption("Tips for pest control", Icons.bug_report, Colors.orange),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostAdviceScreen())),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                child: const Text("Go to Post Editor"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToManageCourses(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCoursesScreen()));
  }

  Widget _buildAIOption(String text, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}

