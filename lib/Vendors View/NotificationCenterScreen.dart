import 'package:flutter/material.dart';
import '../../Services/farm_persistence_service.dart';
import '../../Models/notification_model.dart';
import 'package:intl/intl.dart';
import 'package:linkedfarm/Shopper%20View/Sell_Input_Item.dart';
import 'package:linkedfarm/Vendors%20View/MyPurchasesScreen.dart';
import 'package:linkedfarm/Farmers%20View/OrderManagementScreen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final FarmPersistenceService _persistence = FarmPersistenceService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("NOTIFICATIONS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: "Mark all as read",
            onPressed: () => _markAllAsRead(),
          )
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _persistence.streamNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text("All caught up!", style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.bold)),
          const Text("No new notifications for you right now.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final bool isUnread = !notification.isRead;
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _persistence.deleteNotification(notification.id),
      child: GestureDetector(
        onTap: () {
          if (isUnread) _persistence.markNotificationAsRead(notification.id);
          
          if (notification.orderId != null) {
            // Check if user is a vendor or farmer to navigate correctly
            // For now, most order notifications go to Purchases or Management
            // We'll navigate to MyPurchasesScreen if it's a vendor-facing status, etc.
            // But a safer way is to navigate to the specific order summary if we had one.
            // For now, let's navigate to the main order lists.
            
            if (notification.title.contains("New Order") || notification.title.contains("Sale Completed")) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderManagementScreen()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyPurchasesScreen()),
              );
            }
          } else if (notification.productId != null) {
             // Navigate to product home or similar if needed
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread ? Colors.white : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: isUnread ? Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1.5) : null,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5, spreadRadius: 1)],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(notification.type, isUnread),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(notification.title, style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w500, fontSize: 15)),
                        Text(DateFormat('HH:mm').format(notification.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(notification.message, style: TextStyle(color: isUnread ? Colors.black87 : Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 5, left: 10),
                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildIcon(String type, bool unread) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'match':
        iconData = Icons.local_mall;
        color = Colors.orange;
        break;
      case 'activity':
        iconData = Icons.task_alt;
        color = Colors.green;
        break;
        default:
        iconData = Icons.campaign;
        color = Colors.orange[700]!;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  void _markAllAsRead() async {
    // Basic implementation: get all and loop mark as read
    // Ideal: Firestore server side or efficient batch
    final snapshot = await _persistence.streamNotifications().first;
    for (var n in snapshot) {
      if (!n.isRead) await _persistence.markNotificationAsRead(n.id);
    }
  }
}
