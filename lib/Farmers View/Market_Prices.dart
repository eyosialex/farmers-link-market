import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:linkedfarm/Farmers%20View/FireStore_Config.dart';
import 'package:linkedfarm/Farmers%20View/Enter_Sell_Item.dart';
import 'package:linkedfarm/Farmers%20View/My_Products.dart';
import 'package:linkedfarm/Farmers%20View/OrderManagementScreen.dart';
import 'package:linkedfarm/Vendors%20View/product.dart';
import 'package:linkedfarm/Models/order_model.dart';

const _kGreen = Color(0xFF2E7D32);
const _kGreenLight = Color(0xFF4CAF50);
const _kBg = Color(0xFFF5F6FA);

// ─── Market Page ─────────────────────────────────────────────────────────────
class MarketPricesPage extends StatefulWidget {
  const MarketPricesPage({super.key});
  @override
  State<MarketPricesPage> createState() => _MarketPricesPageState();
}

class _MarketPricesPageState extends State<MarketPricesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _fs = FirestoreService();
  final _auth = FirebaseAuth.instance;
  int _selectedPrice = 0;

  static const _prices = [
    _CropPrice(
      name: 'Tomato',
      emoji: '🍅',
      unit: 'kg',
      price: 30,
      predicted: 34,
      change: 12,
      up: true,
    ),
    _CropPrice(
      name: 'Maize',
      emoji: '🌽',
      unit: 'quintal',
      price: 3000,
      predicted: 2940,
      change: -2,
      up: false,
    ),
    _CropPrice(
      name: 'Wheat',
      emoji: '🌾',
      unit: 'quintal',
      price: 3800,
      predicted: 4100,
      change: 8,
      up: true,
    ),
    _CropPrice(
      name: 'Teff',
      emoji: '🌿',
      unit: 'quintal',
      price: 6300,
      predicted: 6400,
      change: 2,
      up: true,
    ),
    _CropPrice(
      name: 'Coffee',
      emoji: '☕',
      unit: 'kg',
      price: 380,
      predicted: 360,
      change: -5,
      up: false,
    ),
    _CropPrice(
      name: 'Onion',
      emoji: '🧅',
      unit: 'kg',
      price: 50,
      predicted: 48,
      change: -4,
      up: false,
    ),
    _CropPrice(
      name: 'Potato',
      emoji: '🥔',
      unit: 'kg',
      price: 22,
      predicted: 25,
      change: 14,
      up: true,
    ),
  ];

  static const _cats = [
    _Cat(label: 'Seeds', icon: Icons.grass_outlined),
    _Cat(label: 'Fertilizer', icon: Icons.science_outlined),
    _Cat(label: 'Machinery', icon: Icons.agriculture_outlined),
    _Cat(label: 'Irrigation', icon: Icons.water_drop_outlined),
    _Cat(label: 'Pesticide', icon: Icons.bug_report_outlined),
    _Cat(label: 'Tools', icon: Icons.handyman_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _tabBar(),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [_sellTab(), _buyTab(), _pricesTab()],
          ),
        ),
      ],
    );
  }

  // ─── Tab bar ──────────────────────────────────────────────────────────────
  Widget _tabBar() => Container(
    color: Colors.white,
    child: TabBar(
      controller: _tab,
      indicatorColor: _kGreen,
      indicatorWeight: 2.5,
      labelColor: _kGreen,
      unselectedLabelColor: Colors.grey,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      tabs: const [
        Tab(icon: Icon(Icons.grass_outlined, size: 18), text: 'SELL'),
        Tab(icon: Icon(Icons.shopping_cart_outlined, size: 18), text: 'BUY'),
        Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'PRICES'),
      ],
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // SELL TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _sellTab() {
    final uid = _auth.currentUser?.uid ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Market Hub header
          const Text(
            'Market',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'Everything you need in one place.',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 14),

          // Hub nav cards
          _hubCard(
            emoji: '🌾',
            bg: const Color(0xFFE8F5E9),
            title: 'Sell Harvest',
            sub: 'Sell your crops to buyers',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SellItem()),
            ),
          ),
          _hubCard(
            emoji: '🛒',
            bg: const Color(0xFFF3E5F5),
            title: 'Buy Crops',
            sub: 'Buy crops from other farmers',
            onTap: () => _tab.animateTo(1),
          ),
          _hubCard(
            emoji: '🏪',
            bg: const Color(0xFFFFF3E0),
            title: 'Agri Store',
            sub: 'Buy tools, equipment & more',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductListScreen()),
            ),
          ),
          _hubCard(
            emoji: '📊',
            bg: const Color(0xFFE3F2FD),
            title: 'Market Prices',
            sub: "Check today's market prices",
            onTap: () => _tab.animateTo(2),
          ),
          _hubCard(
            emoji: '📦',
            bg: const Color(0xFFFCE4EC),
            title: 'Orders',
            sub: 'Manage incoming & outgoing orders',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderManagementScreen()),
            ),
          ),
          _hubCard(
            emoji: '📈',
            bg: const Color(0xFFE8EAF6),
            title: 'Sales History',
            sub: 'View your sales and earnings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyProductsScreen()),
            ),
          ),

          const SizedBox(height: 22),

          // MY CROPS
          const Text(
            'MY CROPS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SellItem()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Add New Product to Sell',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          StreamBuilder<List<OrderModel>>(
            stream: _fs.getOrdersBySeller(uid),
            builder: (ctx, snap) {
              final orders = snap.data ?? [];
              final pending = orders
                  .where((o) => o.transactionStatus == 'Pending Payment')
                  .length;
              return Row(
                children: [
                  Expanded(
                    child: _infoTile(
                      icon: Icons.grid_view_rounded,
                      bg: const Color(0xFFE8F5E9),
                      iconColor: _kGreen,
                      title: 'My Products',
                      sub: '${orders.length} active',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyProductsScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoTile(
                      icon: Icons.shopping_bag_outlined,
                      bg: const Color(0xFFE3F2FD),
                      iconColor: Colors.blue,
                      title: 'New Orders',
                      sub: pending > 0 ? '($pending)\nPending' : 'None',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrderManagementScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // REAL-TIME PRICES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'REAL-TIME LOCAL MARKET PRICES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.black54,
                ),
              ),
              GestureDetector(
                onTap: () => _tab.animateTo(2),
                child: const Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 11,
                    color: _kGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._prices.take(4).map(_priceTile),

          const SizedBox(height: 24),

          // MARKET OVERVIEW
          const Text(
            'MARKET OVERVIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          _overviewCard(_prices[_selectedPrice]),

          const SizedBox(height: 24),

          // CATEGORIES
          const Text(
            'CATEGORIES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _catChip(_cats[i]),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUY TAB — inline product grid (no nested Scaffold)
  // ══════════════════════════════════════════════════════════════════════════
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = '';

  static const _buyCategories = [
    'Cereals',
    'Pulses',
    'Vegetables',
    'Fruits',
    'Spices',
    'Coffee',
    'Oil Seeds',
    'Tubers',
    'Livestock',
    'Fertilizers',
    'Machinery',
    'Others',
  ];

  Widget _buyTab() {
    return StatefulBuilder(
      builder: (ctx, setLocalState) {
        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setLocalState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search products, brands...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // Category chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _buyCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final cat = _buyCategories[i];
                  final selected = cat == _selectedCategory;
                  return FilterChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: selected,
                    selectedColor: _kGreen,
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: selected ? _kGreen : Colors.grey.shade300,
                    ),
                    onSelected: (_) => setLocalState(
                      () => _selectedCategory = selected ? '' : cat,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            // Product grid
            Expanded(
              child: StreamBuilder<List<dynamic>>(
                stream: _fs.getAgriculturalItems(),
                builder: (ctx2, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _kGreen),
                    );
                  }
                  var items = snap.data ?? [];
                  // Filter
                  if (_searchQuery.isNotEmpty) {
                    items = items
                        .where(
                          (p) =>
                              p.name.toString().toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              p.description.toString().toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                        )
                        .toList();
                  }
                  if (_selectedCategory.isNotEmpty) {
                    items = items
                        .where((p) => p.category == _selectedCategory)
                        .toList();
                  }
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 56,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No products found',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _buyProductCard(items[i]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buyProductCard(dynamic p) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
      ),
      child: Container(
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
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: p.imageUrls != null && (p.imageUrls as List).isNotEmpty
                    ? Image.network(
                        (p.imageUrls as List).first.toString(),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _buyPlaceholder(),
                      )
                    : _buyPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.category.toString(),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${p.price} ETB',
                        style: const TextStyle(
                          color: _kGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (p.isLowStock == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Low Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
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

  Widget _buyPlaceholder() => Container(
    color: Colors.grey[100],
    child: const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey,
        size: 32,
      ),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PRICES TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _pricesTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ALL COMMODITIES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10),
        ..._prices.asMap().entries.map(
          (e) => GestureDetector(
            onTap: () => setState(() => _selectedPrice = e.key),
            child: Container(
              decoration: e.key == _selectedPrice
                  ? BoxDecoration(
                      border: Border.all(color: _kGreen, width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    )
                  : null,
              child: _priceTile(e.value),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'MARKET OVERVIEW',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10),
        _overviewCard(_prices[_selectedPrice]),
        const SizedBox(height: 16),
      ],
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // REUSABLE WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _hubCard({
    required String emoji,
    required Color bg,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 22),
        ],
      ),
    ),
  );

  Widget _infoTile({
    required IconData icon,
    required Color bg,
    required Color iconColor,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                sub,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _priceTile(_CropPrice p) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
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
        Text(p.emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${p.price} ETB / ${p.unit}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        CustomPaint(size: const Size(44, 20), painter: _TrendPainter(p.up)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Icon(
                  p.up
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 12,
                  color: p.up ? _kGreenLight : Colors.red,
                ),
                const SizedBox(width: 2),
                Text(
                  '${p.up ? '+' : ''}${p.change}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: p.up ? _kGreenLight : Colors.red,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _tab.animateTo(2),
              child: const Text(
                'View 7D History ›',
                style: TextStyle(fontSize: 9, color: _kGreen),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _overviewCard(_CropPrice p) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
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
        Row(
          children: [
            Text(p.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              p.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: p.up ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${p.up ? '+' : ''}${p.change}%',
                style: TextStyle(
                  color: p.up ? _kGreenLight : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _oCell('Current Price', '${p.price} ETB/${p.unit}'),
            _oCell(
              'Predicted (7D)',
              '${p.predicted} ETB  ${p.up ? '+' : ''}${p.change}%',
              hi: true,
            ),
            _oCell('Market', p.up ? 'Very Good ↑' : 'Falling ↓'),
          ],
        ),
      ],
    ),
  );

  Widget _oCell(String label, String val, {bool hi = false}) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: hi ? _kGreenLight : Colors.black87,
          ),
        ),
      ],
    ),
  );

  Widget _catChip(_Cat c) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(c.icon, color: _kGreen, size: 26),
      ),
      const SizedBox(height: 6),
      Text(
        c.label,
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      ),
    ],
  );
}

// ─── Data models ─────────────────────────────────────────────────────────────
class _CropPrice {
  final String name, emoji, unit;
  final int price, predicted, change;
  final bool up;
  const _CropPrice({
    required this.name,
    required this.emoji,
    required this.unit,
    required this.price,
    required this.predicted,
    required this.change,
    required this.up,
  });
}

class _Cat {
  final String label;
  final IconData icon;
  const _Cat({required this.label, required this.icon});
}

// ─── Trend curve painter ──────────────────────────────────────────────────────
class _TrendPainter extends CustomPainter {
  final bool up;
  const _TrendPainter(this.up);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = up ? const Color(0xFF4CAF50) : Colors.red
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    if (up) {
      path.moveTo(0, size.height);
      path.cubicTo(
        size.width * 0.3,
        size.height * 0.7,
        size.width * 0.6,
        size.height * 0.3,
        size.width,
        0,
      );
    } else {
      path.moveTo(0, 0);
      path.cubicTo(
        size.width * 0.3,
        size.height * 0.3,
        size.width * 0.6,
        size.height * 0.7,
        size.width,
        size.height,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrendPainter o) => o.up != up;
}
