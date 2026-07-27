import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/game_state.dart';
import '../../Services/weather_service.dart';

class DailyTrackerScreen extends StatefulWidget {
  const DailyTrackerScreen({super.key});

  @override
  State<DailyTrackerScreen> createState() => _DailyTrackerScreenState();
}

class _DailyTrackerScreenState extends State<DailyTrackerScreen> {
  bool _isSensorConnected = false;
  bool _isLoadingSensor = false;
  DailyLog? _tempLog;
  final TextEditingController _notesController = TextEditingController();
  
  // Soil type detection (auto-only)
  String? _detectedSoilType;


  void _connectSensor() async {
    setState(() {
      _isLoadingSensor = true;
    });
    
    // Simulate "Cable Connection" delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final gameState = Provider.of<GameState>(context, listen: false);
    final simulatedLog = gameState.simulateSensorReading();
    
    setState(() {
      _tempLog = simulatedLog;
      _detectedSoilType = simulatedLog.detectedSoilType; // Store detected type
      _isSensorConnected = true;
      _isLoadingSensor = false;
    });
    
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.sensorConnectedMsg(_detectedSoilType ?? 'Unknown')),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveLog() async {
    if (_tempLog == null) return;
    
    final gameState = Provider.of<GameState>(context, listen: false);
    
    // Create final log with notes and auto-detected soil type
    final finalLog = DailyLog(
      id: _tempLog!.id,
      day: _tempLog!.day,
      photoUrl: null, // No photo - sensor only
      notes: _notesController.text,
      moisture: _tempLog!.moisture,
      pH: _tempLog!.pH,
      nitrogen: _tempLog!.nitrogen,
      phosphorus: _tempLog!.phosphorus,
      potassium: _tempLog!.potassium,
      temperature: _tempLog!.temperature,
      detectedSoilType: _detectedSoilType,
      isManualSoilEntry: false,
    );
    
    // Save to Firestore (automatic)
    await gameState.addDailyLog(finalLog);
    
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.dailyLogSavedMsg),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dayTrackerTitle(gameState.currentDay)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          const SizedBox(width: 16),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[700]!, Colors.green[500]!],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sensors, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sensorDataCollection,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                          Text(
                            l10n.connectCableDetail,
                            style: TextStyle(color: Colors.green[100], fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(l10n.soilSensorCable),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Semantics(
                    label: "Sensor Status: ${_isSensorConnected ? l10n.statusConnected : l10n.statusDisconnected}",
                    child: Row(
                      children: [
                        Icon(Icons.cable, color: _isSensorConnected ? Colors.green : Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isSensorConnected ? l10n.statusConnected : l10n.statusDisconnected,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isSensorConnected ? Colors.green[700] : Colors.grey[700],
                            ),
                          ),
                        ),
                        if (_isLoadingSensor)
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        else if (!_isSensorConnected)
                          ElevatedButton(
                            onPressed: _connectSensor,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                            child: Text(l10n.connect, style: const TextStyle(color: Colors.white)),
                          ),
                      ],
                    ),
                  ),
                  if (_tempLog != null) ...[
                    const Divider(height: 30),
                    _buildSensorGrid(l10n, _tempLog!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Detected Soil Type (Auto-Only)
            if (_detectedSoilType != null) ...[
              _buildSectionHeader(l10n.soilType),
              Semantics(
                label: "Auto-detected soil type is ${_detectedSoilType!}",
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.brown[100]!, Colors.brown[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.brown[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.terrain, color: Colors.brown[700], size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Auto-Detected",
                              style: TextStyle(fontSize: 11, color: Colors.brown[600], fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _detectedSoilType!,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown[900]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.connectCableDetail, // Reusing detail string or similar
                              style: TextStyle(fontSize: 11, color: Colors.brown[500]),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle, color: Colors.green[600], size: 28),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // 3. Notes
            _buildSectionHeader(l10n.observations),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: l10n.enterNotes,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSensorConnected ? _saveLog : null,
                icon: const Icon(Icons.save),
                label: Text(l10n.saveDailyLog),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSensorGrid(AppLocalizations l10n, DailyLog log) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _buildSensorValue(l10n.moisture, "${log.moisture.toStringAsFixed(1)}%", Colors.green[700]!),
        _buildSensorValue("pH", log.pH.toStringAsFixed(1), Colors.orange[700]!),
        _buildSensorValue(l10n.temp, "${log.temperature.toStringAsFixed(1)}°C", Colors.orange),
        _buildSensorValue(l10n.nitrogen, "${log.nitrogen.toStringAsFixed(0)} mg", Colors.brown),
        _buildSensorValue(l10n.phosphorus, "${log.phosphorus.toStringAsFixed(0)} mg", Colors.brown),
        _buildSensorValue(l10n.potassium, "${log.potassium.toStringAsFixed(0)} mg", Colors.brown),
      ],
    );
  }

  Widget _buildSensorValue(String label, String value, Color color) {
    return Semantics(
      label: "$label: $value",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
