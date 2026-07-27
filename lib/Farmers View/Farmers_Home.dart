import 'package:linkedfarm/Farmers%20View/Enter_Sell_Item.dart';
import 'package:linkedfarm/Vendors%20View/product.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/User%20Credential/log_in_page.dart';
import 'package:linkedfarm/Farmers%20View/Market_Prices.dart';
import 'package:linkedfarm/Farmers%20View/My_Products.dart';
import 'package:linkedfarm/Farmers%20View/advisor_hub_screen.dart';
import 'package:linkedfarm/Farmers%20View/advice_feed.dart';
import 'package:linkedfarm/Farmers%20View/tabs/learning_center_tab.dart';
import 'package:linkedfarm/Farmers%20View/tabs/ai_agronomist_tab.dart';
import 'package:linkedfarm/Farmers%20View/tabs/farming_pulse_tab.dart';
import 'package:linkedfarm/Farmers%20View/land_map_page.dart';
import 'package:linkedfarm/Game/ui/game_dashboard.dart';
import 'package:linkedfarm/Farmers%20View/Sell_Item_Model.dart';
import 'package:linkedfarm/Chat/chat_list.dart';
import 'package:linkedfarm/Vendors%20View/NotificationCenterScreen.dart';
import 'package:linkedfarm/Services/farm_persistence_service.dart';
import 'package:linkedfarm/Services/notification_service.dart';
import 'package:linkedfarm/Services/weather_service.dart';
import 'package:linkedfarm/Models/notification_model.dart';
import 'package:linkedfarm/Models/order_model.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:linkedfarm/Farmers%20View/FireStore_Config.dart';
import 'package:linkedfarm/Farmers%20View/farmer_profile_page.dart';
import 'package:linkedfarm/Farmers%20View/OrderManagementScreen.dart';
import 'dart:async';

const _kGreen = Color(0xFF2E7D32);
const _kGreenLight = Color(0xFF4CAF50);
const _kBg = Color(0xFFF5F6FA);

// ═══════════════════════════════════════════════════════════════════════════
// SHELL — persistent bottom nav wrapping all 5 tabs
// ═══════════════════════════════════════════════════════════════════════════
class FarmersHomePage extends StatefulWidget {
  const FarmersHomePage({super.key});
  @override
  State<FarmersHomePage> createState() => _FarmersHomePageState();
}

class _FarmersHomePageState extends State<FarmersHomePage> {
  final _persistence = FarmPersistenceService();
  StreamSubscription? _notifSub;
  int _lastUnread = 0;
  bool _isFirstLoad = true;
  DateTime _lastNotifTime = DateTime.now();
  int _navIndex = 0;

  static const _tabs = [
    _HomeBody(),
    _AdvisorTab(),
    MarketPricesPage(),
    ChatListScreen(),
    FarmerProfilePage(),
  ];

  static const _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.agriculture_rounded, label: 'Farm'),
    _NavItem(icon: Icons.storefront_outlined, label: 'Market'),
    _NavItem(icon: Icons.school_outlined, label: 'News'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _startNotificationListener();
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  void _startNotificationListener() {
    _notifSub = _persistence.streamNotifications().listen((list) {
      final unread = list.where((n) => !n.isRead).length;
      if (_isFirstLoad) {
        _lastUnread = unread;
        _isFirstLoad = false;
        return;
      }
      if (unread > _lastUnread) {
        final now = DateTime.now();
        if (now.difference(_lastNotifTime) > const Duration(seconds: 2)) {
          NotificationService.playNotificationSound();
          _lastNotifTime = now;
        }
      }
      _lastUnread = unread;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: IndexedStack(index: _navIndex, children: _tabs),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final sel = i == _navIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _navIndex = i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _navItems[i].icon,
                        color: sel ? _kGreen : Colors.grey[400],
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _navItems[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          color: sel ? _kGreen : Colors.grey[400],
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HOME BODY — tab 0
// ═══════════════════════════════════════════════════════════════════════════
class _HomeBody extends StatefulWidget {
  const _HomeBody();
  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  final _auth = FirebaseAuth.instance;
  final _fs = FirestoreService();
  final _persistence = FarmPersistenceService();
  String _userName = '';
  String _userLocation = '';
  WeatherData? _weather;
  bool _weatherLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadWeather();
  }

  Future<void> _loadUser() async {
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
          _userName = (d['fullName'] ?? d['name'] ?? 'Farmer')
              .toString()
              .split(' ')
              .first;
          _userLocation = d['location'] ?? d['city'] ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadWeather() async {
    final w = await WeatherService.fetchCurrentWeather(9.0054, 38.7636);
    if (mounted)
      setState(() {
        _weather = w ?? WeatherService.getSimulatedWeather(DateTime.now().day);
        _weatherLoading = false;
      });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  IconData _wIcon(String? c) {
    switch ((c ?? '').toLowerCase()) {
      case 'rain':
      case 'drizzle':
        return Icons.water_drop;
      case 'clouds':
        return Icons.cloud;
      case 'thunderstorm':
        return Icons.electric_bolt;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_sunny;
    }
  }

  Color _wColor(String? c) {
    switch ((c ?? '').toLowerCase()) {
      case 'rain':
      case 'drizzle':
        return Colors.blue;
      case 'clouds':
        return Colors.blueGrey;
      case 'thunderstorm':
        return Colors.deepPurple;
      case 'snow':
        return Colors.lightBlue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      color: _kGreen,
      onRefresh: () async {
        await _loadUser();
        await _loadWeather();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(),
            _greeting2(),
            _heroBanner(),
            _summary(l10n),
            _quickActions(l10n),
            _recentActivity(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _kGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.eco, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        const Text(
          'LinkedFarm',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _kGreen,
          ),
        ),
        const Spacer(),
        StreamBuilder<List<AppNotification>>(
          stream: _persistence.streamNotifications(),
          builder: (ctx, snap) {
            final unread = (snap.data ?? []).where((n) => !n.isRead).length;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.black87,
                    size: 26,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationCenterScreen(),
                    ),
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );

  // ── Greeting + weather ─────────────────────────────────────────────────────
  Widget _greeting2() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    _userName.isEmpty ? 'Farmer' : _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Ready to grow more today?',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _weatherCard(),
      ],
    ),
  );

  Widget _weatherCard() {
    if (_weatherLoading)
      return Container(
        width: 110,
        height: 70,
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
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kGreen),
          ),
        ),
      );
    final cond = _weather?.condition ?? 'Sunny';
    return Container(
      width: 115,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_wIcon(cond), color: _wColor(cond), size: 22),
              const SizedBox(width: 6),
              Text(
                '${_weather?.temp.toStringAsFixed(0) ?? '--'}°C',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(cond, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          if (_userLocation.isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.location_on, size: 10, color: Colors.grey[400]),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    _userLocation,
                    style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Hero banner ────────────────────────────────────────────────────────────
  Widget _heroBanner() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/farm_headers.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.black.withOpacity(0.58), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 22,
              right: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Let's make\nfarming easier\ntogether.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: _kGreenLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ── Today's summary ────────────────────────────────────────────────────────
  Widget _summary(AppLocalizations l10n) {
    final uid = _auth.currentUser?.uid ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Summary",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrderManagementScreen(),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Text(
                    'View all',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<List<OrderModel>>(
            stream: _fs.getOrdersBySeller(uid),
            builder: (_, snap) {
              final orders = snap.data ?? [];
              final newO = orders
                  .where((o) => o.transactionStatus == 'Pending Payment')
                  .length;
              final pend = orders
                  .where((o) => o.transactionStatus == 'Awaiting Verification')
                  .length;
              final sales = orders
                  .where((o) => o.transactionStatus == 'Delivered')
                  .fold<double>(0, (s, o) => s + o.totalPrice);
              return StreamBuilder<List<dynamic>>(
                stream: _fs.getAgriculturalItemsBySeller(uid),
                builder: (_, snap2) {
                  final harvest = (snap2.data ?? []).fold<num>(
                    0,
                    (s, i) => s + ((i.quantity as num?) ?? 0),
                  );
                  return Row(
                    children: [
                      _sCard(
                        icon: Icons.account_balance_wallet_outlined,
                        bg: const Color(0xFFE8F5E9),
                        ic: _kGreen,
                        label: 'Sales',
                        value: '${sales.toStringAsFixed(0)} ETB',
                        sub: orders.isNotEmpty
                            ? '+${orders.length} orders'
                            : 'No sales',
                        sc: _kGreenLight,
                      ),
                      const SizedBox(width: 10),
                      _sCard(
                        icon: Icons.shopping_bag_outlined,
                        bg: const Color(0xFFE3F2FD),
                        ic: Colors.blue,
                        label: 'Orders',
                        value: '$newO New',
                        sub: '$pend pending',
                        sc: Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      _sCard(
                        icon: Icons.agriculture_outlined,
                        bg: const Color(0xFFFFF8E1),
                        ic: Colors.orange,
                        label: 'Harvest',
                        value: '$harvest kg',
                        sub: 'This week',
                        sc: Colors.orange,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sCard({
    required IconData icon,
    required Color bg,
    required Color ic,
    required String label,
    required String value,
    required String sub,
    required Color sc,
  }) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: ic, size: 18),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(fontSize: 9, color: sc),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );

  // ── Quick actions ──────────────────────────────────────────────────────────
  Widget _quickActions(AppLocalizations l10n) {
    final actions = [
      _QA(
        label: l10n.sellProduce,
        sub: 'Sell your crops',
        icon: Icons.grass,
        bg: const Color(0xFFF0FBF0),
        color: _kGreen,
        page: SellItem(),
      ),
      _QA(
        label: 'Orders',
        sub: 'View & manage',
        icon: Icons.inventory_2_outlined,
        bg: const Color(0xFFFFF3E0),
        color: Colors.orange,
        page: const OrderManagementScreen(),
      ),
      _QA(
        label: l10n.marketPrices,
        sub: "Today's prices",
        icon: Icons.bar_chart_rounded,
        bg: const Color(0xFFE3F2FD),
        color: Colors.blue,
        page: const MarketPricesPage(),
      ),
      _QA(
        label: l10n.messages,
        sub: 'Chat with buyers',
        icon: Icons.chat_bubble_outline_rounded,
        bg: const Color(0xFFEDE7F6),
        color: Colors.deepPurple,
        page: const ChatListScreen(),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: actions
                .map(
                  (a) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => a.page),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: a.bg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(a.icon, color: a.color, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  a.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  a.sub,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Recent activity ────────────────────────────────────────────────────────
  Widget _recentActivity() {
    final uid = _auth.currentUser?.uid ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrderManagementScreen(),
                  ),
                ),
                child: const Text(
                  'View all',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<OrderModel>>(
            stream: _fs.getOrdersBySeller(uid),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(color: _kGreen),
                  ),
                );
              }
              final orders = snap.data ?? [];
              if (orders.isEmpty)
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        color: Colors.grey[300],
                        size: 36,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'No recent activity yet.',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                );
              return Column(
                children: orders.take(3).map((o) {
                  final emoji = o.productCategory == 'Vegetables'
                      ? '🍅'
                      : o.productCategory == 'Fruits'
                      ? '🍎'
                      : o.productCategory == 'Grains'
                      ? '🌾'
                      : '🌿';
                  final diff = DateTime.now().difference(o.createdAt);
                  final ago = diff.inMinutes < 60
                      ? '${diff.inMinutes} min ago'
                      : diff.inHours < 24
                      ? '${diff.inHours}h ago'
                      : '${diff.inDays}d ago';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${o.productName} order from',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                o.vendorName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          ago,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Helper models ────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _QA {
  final String label, sub;
  final IconData icon;
  final Color bg, color;
  final Widget page;
  const _QA({
    required this.label,
    required this.sub,
    required this.icon,
    required this.bg,
    required this.color,
    required this.page,
  });
}

// ─── _FarmTab — My Products without its own Scaffold ─────────────────────────
class _FarmTab extends StatefulWidget {
  const _FarmTab();
  @override
  State<_FarmTab> createState() => _FarmTabState();
}

class _FarmTabState extends State<_FarmTab> {
  final _fs = FirestoreService();
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid ?? '';
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              const Text(
                'My Farm',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.black87),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SellItem()),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AgriculturalItem>>(
            stream: _fs.getAgriculturalItemsBySeller(uid),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _kGreen),
                );
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.grass_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No products listed yet.',
                        style: TextStyle(color: Colors.grey[400], fontSize: 15),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SellItem()),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (_, i) => _productCard(items[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _productCard(AgriculturalItem item) {
    final statusColor = item.isOutOfStock
        ? Colors.grey
        : item.isLowStock
        ? Colors.orange
        : Colors.green;
    final statusLabel = item.isOutOfStock
        ? 'Closed'
        : item.isLowStock
        ? 'Low Stock'
        : 'Active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: item.imageUrls != null && item.imageUrls!.isNotEmpty
              ? Image.network(
                  item.imageUrls!.first,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.green[50],
                    child: const Icon(Icons.grass, color: _kGreen),
                  ),
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: Colors.green[50],
                  child: const Icon(Icons.grass, color: _kGreen),
                ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.price} ETB / ${item.unit}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item.views} 👁',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit')
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SellItem(productToEdit: item),
                    ),
                  );
                if (v == 'delete') _fs.deleteAgriculturalItem(item.id!);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _AdvisorTab — Advisor Hub without its own Scaffold ──────────────────────
class _AdvisorTab extends StatefulWidget {
  const _AdvisorTab();
  @override
  State<_AdvisorTab> createState() => _AdvisorTabState();
}

class _AdvisorTabState extends State<_AdvisorTab>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Farm Hub',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tab,
                isScrollable: true,
                indicatorColor: Colors.amber,
                indicatorWeight: 3,
                labelColor: _kGreen,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.feed_rounded, size: 16), text: 'Advice'),
                  Tab(
                    icon: Icon(Icons.school_rounded, size: 16),
                    text: 'Learn',
                  ),
                  Tab(
                    icon: Icon(Icons.auto_awesome_rounded, size: 16),
                    text: 'AI Pro',
                  ),
                  Tab(
                    icon: Icon(Icons.analytics_rounded, size: 16),
                    text: 'Pulse',
                  ),
                  Tab(icon: Icon(Icons.map_rounded, size: 16), text: 'Land'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              AdviceFeedScreen(),
              LearningCenterTab(),
              AiAgronomistProTab(),
              FarmingPulseTab(),
              LandMapPage(),
            ],
          ),
        ),
      ],
    );
  }
}
