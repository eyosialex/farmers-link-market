import 'package:flutter/material.dart';
import 'package:linkedfarm/Dlivery%20View/tabs/command_tab.dart';
import 'package:linkedfarm/Dlivery%20View/tabs/requests_tab.dart';
import 'package:linkedfarm/Dlivery%20View/tabs/support_tab.dart';
import 'package:linkedfarm/Dlivery%20View/tabs/fleet_tab.dart';
import 'package:linkedfarm/Dlivery%20View/tabs/driver_profile.dart';

class HomeDelivery extends StatefulWidget {
  const HomeDelivery({super.key});

  @override
  State<HomeDelivery> createState() => _HomeDeliveryState();
}

class _HomeDeliveryState extends State<HomeDelivery> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const CommandTab(),
    const RequestsTab(),
    const FleetTab(),
    const SupportTab(),
    const DriverProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.greenAccent[400],
              unselectedItemColor: Colors.white24,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_rounded),
                  activeIcon: Icon(Icons.grid_view_rounded),
                  label: "COMMAND",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_shipping_outlined),
                  activeIcon: Icon(Icons.local_shipping_rounded),
                  label: "REQUESTS",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.hub_outlined),
                  activeIcon: Icon(Icons.hub_rounded),
                  label: "FLEET",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.support_agent_rounded),
                  activeIcon: Icon(Icons.support_agent_rounded),
                  label: "SUPPORT",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: "PROFILE",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
