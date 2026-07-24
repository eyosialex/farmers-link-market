import 'package:flutter/material.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:linkedfarm/Farmers%20View/advice_feed.dart';
import 'package:linkedfarm/Farmers%20View/tabs/learning_center_tab.dart';
import 'package:linkedfarm/Farmers%20View/tabs/ai_agronomist_tab.dart';
import 'package:linkedfarm/Farmers%20View/tabs/farming_pulse_tab.dart';

class AdvisorHubScreen extends StatefulWidget {
  const AdvisorHubScreen({super.key});

  @override
  State<AdvisorHubScreen> createState() => _AdvisorHubScreenState();
}

class _AdvisorHubScreenState extends State<AdvisorHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text("Modern Advisor Hub", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(icon: const Icon(Icons.feed_rounded), text: l10n.expertAdviceTitle),
            Tab(icon: const Icon(Icons.school_rounded), text: l10n.tabLearn),
            Tab(icon: const Icon(Icons.auto_awesome_rounded), text: l10n.tabAiPro),
            Tab(icon: const Icon(Icons.analytics_rounded), text: l10n.tabPulse),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AdviceFeedScreen(), // The expert articles
          LearningCenterTab(),
          AiAgronomistProTab(),
          FarmingPulseTab(),
        ],
      ),
    );
  }
}
