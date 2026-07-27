import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Services/farm_persistence_service.dart';
import '../models/game_state.dart';
import 'setup_screens.dart';
import 'farm_main_screen.dart';
import 'farm_theme.dart';

class MyLandsScreen extends StatelessWidget {
  const MyLandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final persistence = FarmPersistenceService();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: FarmTheme.bg,
      appBar: FarmTheme.appBar(
        context,
        l10n.myLandsProfile,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _showAddLandDialog(context),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: FarmTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(FarmTheme.radiusSm),
                  border: Border.all(color: FarmTheme.accent.withOpacity(0.3)),
                ),
                child: const Icon(Icons.add, color: FarmTheme.accent, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: FarmTheme.bgGradient),
        child: StreamBuilder<List<UserLand>>(
          stream: persistence.streamUserLands(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: FarmTheme.accent),
              );
            }

            final lands = snapshot.data ?? [];

            if (lands.isEmpty) {
              return _buildEmptyState(context, l10n);
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: lands.length,
              itemBuilder: (context, index) {
                return _buildLandCard(context, lands[index], l10n);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLandDialog(context),
        backgroundColor: FarmTheme.accent,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_location_alt, size: 20),
        label: Text(
          l10n.registerNewLand,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: FarmTheme.accent.withOpacity(0.07),
                shape: BoxShape.circle,
                border: Border.all(color: FarmTheme.accent.withOpacity(0.15), width: 1.5),
              ),
              child: const Icon(Icons.landscape_outlined, size: 52, color: FarmTheme.accent),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noLandsRegistered,
              style: FarmTheme.headingMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.startAddingPlot,
              style: FarmTheme.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FarmTheme.primaryButton(
              text: l10n.registerNewLand,
              icon: Icons.add_location_alt,
              fullWidth: false,
              onPressed: () => _showAddLandDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Land Card ─────────────────────────────────────────────────
  Widget _buildLandCard(BuildContext context, UserLand land, AppLocalizations l10n) {
    final isRunning = land.activeCrop != null &&
        land.currentDay < 5 &&
        land.growthProgress < 100;
    final isCompleted = land.activeCrop != null && !isRunning;
    final growthPct = land.growthProgress.clamp(0.0, 100.0) / 100.0;

    final statusColor = land.activeCrop == null
        ? FarmTheme.accentWarm
        : (isRunning ? FarmTheme.accent : FarmTheme.textMuted);
    final statusText = land.activeCrop == null
        ? l10n.readyPlanting
        : (isRunning
            ? '${land.activeCrop} · ${l10n.dayLabel(land.currentDay)}'
            : l10n.cycleCompleted);

    return GestureDetector(
      onTap: () async {
        final gameState = Provider.of<GameState>(context, listen: false);
        await gameState.loadFromLand(land);
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => land.activeCrop == null
                ? const SetupScreen()
                : const FarmMainScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: isRunning ? FarmTheme.cardHighlight : FarmTheme.card,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(FarmTheme.radiusSm),
                    ),
                    child: Icon(
                      isRunning
                          ? Icons.play_circle_filled
                          : (land.activeCrop == null
                              ? Icons.add_circle_outline
                              : Icons.check_circle),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(land.name.toUpperCase(), style: FarmTheme.headingMd),
                        const SizedBox(height: 3),
                        Text(
                          '${land.size} ${l10n.hectares} · ${land.soilType}',
                          style: FarmTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: FarmTheme.textMuted, size: 20),
                ],
              ),

              // ── Status badge ──
              const SizedBox(height: 14),
              _buildDivider(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isRunning) ...[
                    Text(
                      '${land.growthProgress.toInt()}%',
                      style: const TextStyle(
                        color: FarmTheme.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),

              // ── Growth bar (only when active) ──
              if (isRunning) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: growthPct,
                    backgroundColor: FarmTheme.border,
                    color: FarmTheme.accent,
                    minHeight: 5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(height: 1, color: FarmTheme.border);

  // ─── Add Land Bottom Sheet ──────────────────────────────────────
  void _showAddLandDialog(BuildContext context) {
    final nameController = TextEditingController();
    final sizeController = TextEditingController();
    String selectedSoil = 'Loamy';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FarmTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(FarmTheme.radiusXl)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final l10n = AppLocalizations.of(context)!;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: FarmTheme.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                Text(l10n.registerNewLand, style: FarmTheme.headingLg),
                const SizedBox(height: 4),
                Text('Enter details for your land plot.', style: FarmTheme.caption),
                const SizedBox(height: 24),

                _sheetField(l10n.landNameHint, nameController, TextInputType.text),
                const SizedBox(height: 16),
                _sheetField(l10n.sizeHectares, sizeController, TextInputType.number),
                const SizedBox(height: 20),

                Text(l10n.soilType, style: FarmTheme.label),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: FarmTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
                    border: Border.all(color: FarmTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: FarmTheme.surfaceAlt,
                      value: selectedSoil,
                      style: FarmTheme.body,
                      icon: const Icon(Icons.keyboard_arrow_down, color: FarmTheme.textMuted),
                      items: ['Loamy', 'Silt', 'Clay', 'Sandy'].map((s) {
                        final label = s == 'Loamy'
                            ? l10n.loamy
                            : (s == 'Silt'
                                ? l10n.silt
                                : (s == 'Clay' ? l10n.clay : l10n.sandy));
                        return DropdownMenuItem(
                          value: s,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedSoil = val!),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                FarmTheme.primaryButton(
                  text: l10n.saveLand,
                  icon: Icons.save_outlined,
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        sizeController.text.isEmpty) return;
                    final newLand = UserLand(
                      id: '',
                      name: nameController.text,
                      size: double.tryParse(sizeController.text) ?? 1.0,
                      soilType: selectedSoil,
                      updatedAt: DateTime.now(),
                    );
                    await FarmPersistenceService().saveLand(newLand);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController ctrl, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: FarmTheme.body,
      cursorColor: FarmTheme.accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: FarmTheme.textMuted, fontSize: 13),
        filled: true,
        fillColor: FarmTheme.surfaceAlt,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
          borderSide: const BorderSide(color: FarmTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
          borderSide: const BorderSide(color: FarmTheme.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
