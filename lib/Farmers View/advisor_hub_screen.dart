import 'package:flutter/material.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:linkedfarm/Farmers%20View/advice_feed.dart';
import 'package:linkedfarm/Farmers%20View/tabs/learning_center_tab.dart';
import 'package:linkedfarm/Farmers%20View/tabs/ai_agronomist_tab.dart';
import 'package:linkedfarm/Farmers%20View/tabs/farming_pulse_tab.dart';
import 'package:linkedfarm/Farmers%20View/land_map_page.dart';
import 'package:linkedfarm/Game/ui/game_dashboard.dart';

class AdvisorHubScreen extends StatefulWidget {
  /// Pass [initialTab] to open a specific tab directly (0=Advice,1=Learn,2=AI,3=Pulse,4=Land,5=Plan)
  final int initialTab;
  const AdvisorHubScreen({super.key, this.initialTab = 0});

  @override
  State<AdvisorHubScreen> createState() => _AdvisorHubScreenState();
}

class _AdvisorHubScreenState extends State<AdvisorHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 5),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Advisor Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.feed_rounded, size: 18),
              text: l10n.expertAdviceTitle,
            ),
            Tab(
              icon: const Icon(Icons.school_rounded, size: 18),
              text: l10n.tabLearn,
            ),
            Tab(
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              text: l10n.tabAiPro,
            ),
            Tab(
              icon: const Icon(Icons.analytics_rounded, size: 18),
              text: l10n.tabPulse,
            ),
            const Tab(icon: Icon(Icons.map_rounded, size: 18), text: 'Land'),
            const Tab(
              icon: Icon(Icons.agriculture_rounded, size: 18),
              text: 'Farm Plan',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AdviceFeedScreen(),
          LearningCenterTab(),
          AiAgronomistProTab(),
          FarmingPulseTab(),
          LandMapPage(),
          GameDashboard(),
        ],
      ),
    );
  }
}
