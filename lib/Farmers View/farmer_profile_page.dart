import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/Farmers%20View/FireStore_Config.dart';
import 'package:linkedfarm/Farmers%20View/Sell_Item_Model.dart';
import 'package:linkedfarm/Farmers%20View/Enter_Sell_Item.dart';
import 'package:linkedfarm/Farmers%20View/OrderManagementScreen.dart';
import 'package:linkedfarm/Farmers%20View/advisor_hub_screen.dart';
import 'package:linkedfarm/Models/order_model.dart';
import 'package:linkedfarm/Models/course_model.dart';
import 'package:linkedfarm/Services/learning_service.dart';
import 'package:linkedfarm/Services/locale_provider.dart';
import 'package:linkedfarm/User%20Credential/log_in_page.dart';
import 'package:linkedfarm/Vendors%20View/NotificationCenterScreen.dart';
import 'package:linkedfarm/Farmers%20View/learning/course_detail_screen.dart';
import 'package:linkedfarm/Vendors%20View/product.dart';
import 'package:provider/provider.dart';
import 'package:linkedfarm/Services/io_compatibility.dart'
    if (dart.library.html) 'package:linkedfarm/Services/web_compatibility.dart';

// ─── Profile Page ────────────────────────────────────────────────────────────
class FarmerProfilePage extends StatefulWidget {
  const FarmerProfilePage({super.key});
  @override
  State<FarmerProfilePage> createState() => _FarmerProfilePageState();
}

class _FarmerProfilePageState extends State<FarmerProfilePage>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _fs = FirestoreService();
  final _learning = LearningService();

  late TabController _tab;

  // profile data
  String _fullName = '';
  String _bio = '';
  String _photoUrl = '';
  bool _loadingProfile = true;

  static const _kBlue = Color(0xFF1565C0);
  static const _kBg = Color(0xFFF5F6FA);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Usersstore')
          .doc(uid)
          .get();
      if (doc.exists && mounted) {
        final d = doc.data()!;
        setState(() {
          _fullName = d['fullName'] ?? d['name'] ?? 'Farmer';
          _bio =
              d['bio'] ?? 'Strategic farm manager and agricultural producer.';
          _photoUrl = d['photoUrl'] ?? d['profileImage'] ?? '';
          _loadingProfile = false;
        });
      } else {
        setState(() => _loadingProfile = false);
      }
    } catch (_) {
      setState(() => _loadingProfile = false);
    }
  }

  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LogInPage(onTap: null)),
        (_) => false,
      );
    }
  }

  // ── Settings bottom sheet ────────────────────────────────────────────────
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final lp = Provider.of<LocaleProvider>(context, listen: false);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: const Text('English / አማርኛ / Oromiffa'),
                onTap: () {
                  Navigator.pop(context);
                  _pickLanguage(lp);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none_rounded),
                title: const Text('Notifications'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationCenterScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _pickLanguage(LocaleProvider lp) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Select Language',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Divider(),
            ListTile(
              leading: const Text('🇬🇧'),
              title: const Text('English'),
              onTap: () {
                lp.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇪🇹'),
              title: const Text('አማርኛ'),
              onTap: () {
                lp.setLocale(const Locale('am'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇪🇹'),
              title: const Text('Oromiffa'),
              onTap: () {
                lp.setLocale(const Locale('om'));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (_, __) => [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: _tab,
              isScrollable: true,
              labelColor: _kBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: _kBlue,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Product'),
                Tab(text: 'Course'),
                Tab(text: 'Orders'),
                Tab(text: 'Land'),
                Tab(text: 'Plan'),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tab,
        children: [
          _ProductTab(fs: _fs),
          _CourseTab(learning: _learning),
          _OrdersTab(fs: _fs),
          _LandTab(),
          _PlanTab(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Top bar: settings icon | Profile title | bell icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: _kBlue),
                onPressed: _openSettings,
              ),
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _kBlue,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: _kBlue,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationCenterScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Avatar
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.grey[200],
            backgroundImage: _photoUrl.isNotEmpty
                ? NetworkImage(_photoUrl)
                : null,
            child: _photoUrl.isEmpty
                ? const Icon(Icons.person, size: 44, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 12),
          // Name + Edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _loadingProfile ? '...' : _fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit, size: 13),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bio
          Text(
            _bio,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SliverPersistentHeader delegate for pinned TabBar ───────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);
  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;
  @override
  Widget build(_, __, ___) => Container(
    color: Colors.white,
    child: Column(children: [const Divider(height: 1), tabBar]),
  );
  @override
  bool shouldRebuild(_TabBarDelegate o) => o.tabBar != tabBar;
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 1 — Product  (farmer's listed products, 2-col grid)
// ════════════════════════════════════════════════════════════════════════════
class _ProductTab extends StatelessWidget {
  final FirestoreService fs;
  const _ProductTab({required this.fs});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<AgriculturalItem>>(
      stream: fs.getAgriculturalItemsBySeller(uid),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return _emptyState(
            context,
            icon: Icons.grass_outlined,
            message: 'No products listed yet.',
            action: 'List a Product',
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => SellItem()),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _ProductCard(item: items[i], fs: fs),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final AgriculturalItem item;
  final FirestoreService fs;
  const _ProductCard({required this.item, required this.fs});

  Color _statusColor(AgriculturalItem p) {
    if (p.isOutOfStock) return Colors.grey;
    if (p.isLowStock) return Colors.orange;
    return Colors.green;
  }

  String _statusLabel(AgriculturalItem p) {
    if (p.isOutOfStock) return 'Closed';
    if (p.isLowStock) return 'Pending';
    return 'Active';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: _buildImage(),
                ),
                // 3-dot menu
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      onSelected: (v) {
                        if (v == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SellItem(productToEdit: item),
                            ),
                          );
                        } else if (v == 'delete') {
                          fs.deleteAgriculturalItem(item.id!);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.remove_red_eye_outlined,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${item.views} Views',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.thumb_up_alt_outlined,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${item.likes} Likes',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'STATUS: ',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _statusColor(item),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _statusLabel(item),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(item),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (item.imageUrls != null && item.imageUrls!.isNotEmpty) {
      return Image.network(
        item.imageUrls!.first,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (item.localImagePaths != null && item.localImagePaths!.isNotEmpty) {
      return getImageFromFile(item.localImagePaths!.first);
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    color: Colors.grey[100],
    child: const Icon(Icons.image_outlined, color: Colors.grey, size: 36),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 2 — Course  (courses from learning service)
// ════════════════════════════════════════════════════════════════════════════
class _CourseTab extends StatelessWidget {
  final LearningService learning;
  const _CourseTab({required this.learning});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Course>>(
      stream: learning.streamAllCourses(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final courses = snap.data ?? [];
        if (courses.isEmpty) {
          return _emptyState(
            context,
            icon: Icons.school_outlined,
            message: 'No courses available yet.',
            action: 'Browse Advisor Hub',
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => const AdvisorHubScreen(initialTab: 1),
              ),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemCount: courses.length,
          itemBuilder: (_, i) => _CourseCard(course: courses[i]),
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: course.thumbnailUrl.startsWith('http')
                    ? Image.network(
                        course.thumbnailUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _coursePlaceholder(),
                      )
                    : Image.asset(
                        course.thumbnailUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _coursePlaceholder(),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        '${course.rating}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: course.isPremium
                              ? Colors.amber[50]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          course.isPremium ? 'Premium' : 'Free',
                          style: TextStyle(
                            fontSize: 9,
                            color: course.isPremium
                                ? Colors.orange[700]
                                : Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coursePlaceholder() => Container(
    color: Colors.green[50],
    child: const Icon(Icons.school, color: Colors.green, size: 36),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 3 — Orders  (incoming sell orders)
// ════════════════════════════════════════════════════════════════════════════
class _OrdersTab extends StatelessWidget {
  final FirestoreService fs;
  const _OrdersTab({required this.fs});

  Color _statusColor(String s) {
    switch (s) {
      case 'Delivered':
        return Colors.green;
      case 'In Transit':
        return Colors.blue;
      case 'Cancelled':
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<OrderModel>>(
      stream: fs.getOrdersBySeller(uid),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snap.data ?? [];
        if (orders.isEmpty) {
          return _emptyState(
            context,
            icon: Icons.receipt_long_outlined,
            message: 'No orders yet.',
            action: 'Manage Orders',
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const OrderManagementScreen()),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final o = orders[i];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(
                    o.transactionStatus,
                  ).withOpacity(0.12),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: _statusColor(o.transactionStatus),
                    size: 20,
                  ),
                ),
                title: Text(
                  o.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'From: ${o.vendorName}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${o.totalPrice.toStringAsFixed(0)} ETB',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          o.transactionStatus,
                        ).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        o.transactionStatus,
                        style: TextStyle(
                          fontSize: 9,
                          color: _statusColor(o.transactionStatus),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrderManagementScreen(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 4 — Land  (opens land map inline in profile)
// ════════════════════════════════════════════════════════════════════════════
class _LandTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.map_outlined,
                size: 48,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Land Boundary Mapper',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Draw and save your farm land boundaries on an interactive map.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdvisorHubScreen(initialTab: 4),
                ),
              ),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open Land Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 5 — Plan  (farm simulation / game plan)
// ════════════════════════════════════════════════════════════════════════════
class _PlanTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.agriculture_rounded,
                size: 48,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Farm Plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan your virtual farm, simulate crops and track growth with AI-powered insights.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdvisorHubScreen(initialTab: 5),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Open Farm Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared empty state ───────────────────────────────────────────────────────
Widget _emptyState(
  BuildContext context, {
  required IconData icon,
  required String message,
  required String action,
  required VoidCallback onTap,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1565C0),
              side: const BorderSide(color: Color(0xFF1565C0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(action),
          ),
        ],
      ),
    ),
  );
}
