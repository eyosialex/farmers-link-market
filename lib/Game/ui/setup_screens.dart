import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/soil_model.dart';
import '../models/crop_model.dart';
import '../models/game_state.dart';
import 'farm_main_screen.dart';
import 'farm_theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  Soil? selectedSoil;
  Crop? selectedCrop;
  double landSize = 1.0;
  DateTime plantingDate = DateTime.now();
  int step = 1; // 1 = Land details, 2 = Crop selection

  // Step labels
  static const _steps = ['Land Details', 'Crop Selection'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmTheme.bg,
      appBar: FarmTheme.appBar(
        context,
        step == 1 ? 'Setup Your Farm' : 'Select Your Crop',
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: FarmTheme.bgGradient),
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: step == 1
                    ? _buildLandDetails(key: const ValueKey('land'))
                    : _buildCropSelection(key: const ValueKey('crop')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step Indicator ────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final done = step > (i ~/ 2) + 1;
            return Expanded(
              child: Container(
                height: 2,
                color: done ? FarmTheme.accent : FarmTheme.border,
              ),
            );
          }
          final idx = i ~/ 2;
          final active = step == idx + 1;
          final done = step > idx + 1;
          final color = done || active ? FarmTheme.accent : FarmTheme.textMuted;
          return Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: active
                    ? FarmTheme.accent
                    : (done
                        ? FarmTheme.accent.withOpacity(0.2)
                        : FarmTheme.surface),
                shape: BoxShape.circle,
                border: Border.all(
                  color: done || active ? FarmTheme.accent : FarmTheme.border,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, size: 14, color: FarmTheme.accent)
                    : Text(
                        '${idx + 1}',
                        style: TextStyle(
                          color: active ? FarmTheme.bg : FarmTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 6),
            Text(_steps[idx],
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                )),
          ]);
        }),
      ),
    );
  }

  // ─── Step 1: Land Details ──────────────────────────────────────
  Widget _buildLandDetails({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intro card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: FarmTheme.card,
            child: Row(children: [
              const Icon(Icons.info_outline, color: FarmTheme.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Set your land size and preferred planting date. Soil type will be auto-detected via sensors.',
                  style: FarmTheme.caption,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Land size card
          FarmTheme.sectionHeader('LAND AREA'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: FarmTheme.card,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.square_foot, color: FarmTheme.accent, size: 18),
                      const SizedBox(width: 8),
                      Text('Total Area', style: FarmTheme.body),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: FarmTheme.pill,
                      child: Text(
                        '${landSize.toStringAsFixed(1)} ha',
                        style: const TextStyle(
                          color: FarmTheme.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: FarmTheme.accent,
                    inactiveTrackColor: FarmTheme.border,
                    thumbColor: FarmTheme.accent,
                    overlayColor: FarmTheme.accent.withOpacity(0.1),
                    valueIndicatorColor: FarmTheme.accent,
                    valueIndicatorTextStyle: const TextStyle(color: FarmTheme.bg, fontWeight: FontWeight.bold),
                  ),
                  child: Slider(
                    value: landSize,
                    min: 0.5,
                    max: 10.0,
                    divisions: 19,
                    label: '${landSize.toStringAsFixed(1)} ha',
                    onChanged: (val) => setState(() => landSize = val),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0.5 ha', style: FarmTheme.caption),
                    Text('10.0 ha', style: FarmTheme.caption),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Planting date card
          FarmTheme.sectionHeader('PLANTING DATE'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: plantingDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
                builder: (context, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: FarmTheme.accent,
                      surface: FarmTheme.surface,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => plantingDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: FarmTheme.card,
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FarmTheme.accentWarm.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(FarmTheme.radiusSm),
                  ),
                  child: const Icon(Icons.calendar_today, color: FarmTheme.accentWarm, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Planned Planting Date', style: FarmTheme.caption),
                    const SizedBox(height: 4),
                    Text(
                      '${plantingDate.day}/${plantingDate.month}/${plantingDate.year}',
                      style: FarmTheme.headingMd,
                    ),
                  ]),
                ),
                Text('CHANGE',
                    style: const TextStyle(
                      color: FarmTheme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    )),
              ]),
            ),
          ),

          const SizedBox(height: 36),
          FarmTheme.primaryButton(
            text: 'Next: Select Crop',
            icon: Icons.arrow_forward,
            onPressed: () => setState(() => step = 2),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Crop Selection ────────────────────────────────────
  Widget _buildCropSelection({Key? key}) {
    final defaultSoil = Soil.allSoils.firstWhere((s) => s.type == SoilType.loamy);
    selectedSoil ??= defaultSoil;

    final crops = Crop.allCrops;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header info
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: FarmTheme.card,
            child: Row(children: [
              const Icon(Icons.auto_awesome, color: FarmTheme.accentWarm, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '★ = recommended for your soil type',
                  style: FarmTheme.caption.copyWith(color: FarmTheme.accentWarm),
                ),
              ),
            ]),
          ),
        ),

        // Crop list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: crops.length,
            itemBuilder: (context, index) {
              final crop = crops[index];
              final isCompatible =
                  crop.preferredSoils.contains(selectedSoil!.type);
              final isSelected = selectedCrop == crop;

              return GestureDetector(
                onTap: () => setState(() => selectedCrop = crop),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: isSelected
                      ? FarmTheme.cardHighlight
                      : FarmTheme.card,
                  child: Row(children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCompatible
                            ? FarmTheme.accent.withOpacity(0.1)
                            : FarmTheme.accentRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(FarmTheme.radiusSm),
                      ),
                      child: Icon(
                        Icons.agriculture,
                        color: isCompatible ? FarmTheme.accent : FarmTheme.accentRed,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(crop.name, style: FarmTheme.headingMd),
                            if (isCompatible) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.star_rounded,
                                  color: FarmTheme.accentWarm, size: 14),
                            ],
                          ]),
                          const SizedBox(height: 3),
                          Text(crop.description, style: FarmTheme.caption,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          // Spec pills
                          Wrap(spacing: 6, children: [
                            _specPill('pH ${crop.minPh}–${crop.maxPh}', FarmTheme.accentBlue),
                            _specPill('W: ${crop.waterDemand.toStringAsFixed(1)}', FarmTheme.accent),
                            _specPill('${crop.totalGrowthDays}d', FarmTheme.accentWarm),
                          ]),
                        ],
                      ),
                    ),

                    // Check
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: FarmTheme.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: FarmTheme.bg, size: 14),
                      ),
                  ]),
                ),
              );
            },
          ),
        ),

        // Bottom action row
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          decoration: BoxDecoration(
            color: FarmTheme.surface,
            border: const Border(top: BorderSide(color: FarmTheme.border)),
          ),
          child: Row(children: [
            FarmTheme.ghostButton(
              text: '← Back',
              onPressed: () => setState(() => step = 1),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: selectedCrop == null ? null : _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FarmTheme.accent,
                  foregroundColor: FarmTheme.bg,
                  disabledBackgroundColor: FarmTheme.border,
                  disabledForegroundColor: FarmTheme.textMuted,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: const Text('Start Mission 🚀',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _specPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  void _startGame() {
    if (selectedSoil == null || selectedCrop == null) return;
    final gameState = Provider.of<GameState>(context, listen: false);
    gameState.startNewGame(
      gameState.currentLandId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      gameState.currentLandName ?? 'New Plot',
      selectedSoil!,
      selectedCrop!,
      landSize,
      plantingDate,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FarmMainScreen()),
    );
  }
}
