import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'soil_model.dart';
import 'crop_model.dart';
import '../logic/game_engine.dart';
import '../../Services/weather_service.dart';
import '../../Services/farm_persistence_service.dart';

class DailyLog {
  final String id;
  final int day;
  final String? photoUrl;
  final String? notes;
  
  // Sensor Data
  final double moisture;
  final double pH;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double temperature; // from Weather
  final String? detectedSoilType; // NEW: Auto-detected or manually entered
  final bool isManualSoilEntry; // NEW: Track if user manually entered soil type

  DailyLog({
    required this.id,
    required this.day,
    this.photoUrl,
    this.notes,
    required this.moisture,
    required this.pH,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.temperature,
    this.detectedSoilType,
    this.isManualSoilEntry = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': day,
    'photoUrl': photoUrl,
    'notes': notes,
    'moisture': moisture,
    'pH': pH,
    'nitrogen': nitrogen,
    'phosphorus': phosphorus,
    'potassium': potassium,
    'temperature': temperature,
    'detectedSoilType': detectedSoilType,
    'isManualSoilEntry': isManualSoilEntry,
  };

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      id: json['id'],
      day: json['day'],
      photoUrl: json['photoUrl'],
      notes: json['notes'],
      moisture: (json['moisture'] as num).toDouble(),
      pH: (json['pH'] as num).toDouble(),
      nitrogen: (json['nitrogen'] as num).toDouble(),
      phosphorus: (json['phosphorus'] as num).toDouble(),
      potassium: (json['potassium'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      detectedSoilType: json['detectedSoilType'],
      isManualSoilEntry: json['isManualSoilEntry'] ?? false,
    );
  }
}

class GameState extends ChangeNotifier {
  final FarmPersistenceService _persistence = FarmPersistenceService();
  String? _currentLandId;
  String? _currentLandName;

  String? get currentLandId => _currentLandId;
  String? get currentLandName => _currentLandName;

  Soil? _selectedSoil;
  Crop? _selectedCrop;
  int _currentDay = 0;
  double _soilMoisture = 0.5;
  double _soilNutrients = 0.5;
  double _growthProgress = 0.0;
  double _healthScore = 1.0;
  
  // New Reality Factors
  double _energy = 100.0;
  double _budget = 1000.0;
  double _soilReadiness = 0.0; // 0.0 to 1.0 (Plowing, Leveling progress)
  double _landSize = 1.0; // in hectares
  DateTime? _plantingDate;

  // AI & Risk Factors
  double _pestRisk = 0.0;
  double _diseaseRisk = 0.0;
  double _weedPressure = 0.0;

  // Activity Scores (0.0 to 5.0)
  double _landPrepScore = 0.0;
  double _cropSelectionScore = 0.0;
  final double _plantingTimeScore = 0.0;
  double _inputManagementScore = 0.0;
  
  bool _isGameOver = false;
  List<String> _gameLog = [];
  List<Map<String, dynamic>> _customActivities = [];
  final List<Map<String, dynamic>> _history = [];
  
  String _currentWeather = "Sunny";
  double _currentTemp = 25.0;

  // Getters
  Soil? get selectedSoil => _selectedSoil;
  Crop? get selectedCrop => _selectedCrop;
  int get currentDay => _currentDay;
  double get soilMoisture => _soilMoisture;
  double get soilNutrients => _soilNutrients;
  double get growthProgress => _growthProgress;
  double get healthScore => _healthScore;
  double get energy => _energy;
  double get budget => _budget;
  double get soilReadiness => _soilReadiness;
  double get landSize => _landSize;
  DateTime? get plantingDate => _plantingDate;
  List<Map<String, dynamic>> get customActivities => _customActivities;

  double get pestRisk => _pestRisk;
  double get diseaseRisk => _diseaseRisk;
  double get weedPressure => _weedPressure;

  double get landPrepScore => _landPrepScore;
  double get cropSelectionScore => _cropSelectionScore;
  double get plantingTimeScore => _plantingTimeScore;
  double get inputManagementScore => _inputManagementScore;

  bool get isGameOver => _isGameOver;
  List<String> get gameLog => _gameLog;
  List<Map<String, dynamic>> get history => _history;
  String get currentWeather => _currentWeather;
  double get currentTemp => _currentTemp;

  // Visual Getters for "Real World" feeling
  bool get isWilting => _soilMoisture < (_selectedCrop?.waterDemand ?? 0.5) * 0.4;
  Color get plantColor {
    if (_healthScore < 0.4) return Colors.brown[400]!;
    if (_healthScore < 0.7) return Colors.yellow[700]!;
    return Colors.green[600]!;
  }

  double get visualStage {
    if (_growthProgress < 20) return 1; // Seedling
    if (_growthProgress < 50) return 2; // Vegetative
    if (_growthProgress < 80) return 3; // Flowering
    return 4; // Mature
  }

  IconData get plantIcon {
    if (visualStage == 1) return Icons.eco_outlined; // Seedling
    if (visualStage == 2) return Icons.eco; // Vegetative
    if (visualStage == 3) return Icons.local_florist; // Flowering
    return Icons.agriculture; // Mature
  }

  List<DailyLog> _dailyLogs = [];
  List<DailyLog> get dailyLogs => _dailyLogs;

  Future<void> addDailyLog(DailyLog log) async {
    _dailyLogs.add(log);
    
    // Impact of "Sensor Check" / "Analysis"
    _energy = (_energy - 5.0).clamp(0.0, 100.0); // Cost of detailed analysis
    _gameLog.insert(0, "Day $_currentDay: Logged sensor data & crop photo.");
    
    notifyListeners();
    
    // Save to Firestore
    await _saveDailyLogToFirestore(log);
    _syncToFirestore();
  }
  
  // Firestore: Save daily log
  Future<void> _saveDailyLogToFirestore(DailyLog log) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('farmGame')
          .doc('dailyLogs')
          .collection('logs')
          .doc(log.id)
          .set(log.toJson());
      
      debugPrint('✅ Daily log saved to Firestore: ${log.id}');
    } catch (e) {
      debugPrint('❌ Error saving daily log to Firestore: $e');
    }
  }
  
  // Firestore: Load all daily logs
  Future<void> loadDailyLogsFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('farmGame')
          .doc('dailyLogs')
          .collection('logs')
          .orderBy('day', descending: false)
          .get();
      
      _dailyLogs = snapshot.docs
          .map((doc) => DailyLog.fromJson(doc.data()))
          .toList();
      
      notifyListeners();
      debugPrint('✅ Loaded ${_dailyLogs.length} daily logs from Firestore');
    } catch (e) {
      debugPrint('❌ Error loading daily logs from Firestore: $e');
    }
  }


  // Simulates reading from a "Connect Cable" sensor
  DailyLog simulateSensorReading() {
    // Base values from current soil state
    double baseMoisture = _soilMoisture * 100; // Display as %
    double baseN = _soilNutrients * 100;
    double baseP = _soilNutrients * 80;
    double baseK = _soilNutrients * 90;
    double currentPH = _selectedSoil?.phLevel ?? 6.5;
    
    // INTELLIGENT SOIL TYPE DETECTION
    // Analyzes pH, moisture retention, and nutrient levels to suggest soil type
    String detectedType = _detectSoilType(currentPH, baseMoisture, baseN);
    
    return DailyLog(
      id: DateTime.now().toIso8601String(), 
      day: _currentDay,
      moisture: baseMoisture,
      pH: currentPH,
      nitrogen: baseN,
      phosphorus: baseP,
      potassium: baseK,
      temperature: _currentTemp,
      detectedSoilType: detectedType,
      isManualSoilEntry: false, // This is auto-detected
    );
  }
  
  // AI-based soil type detection algorithm
  String _detectSoilType(double pH, double moisture, double nitrogen) {
    // Clay: High moisture retention (>70%), slightly acidic to neutral pH (6.0-7.0), high nutrients
    if (moisture > 70 && pH >= 6.0 && pH <= 7.0 && nitrogen > 60) {
      return "Clay";
    }
    
    // Sandy: Low moisture retention (<40%), acidic pH (5.5-6.5), low nutrients
    if (moisture < 40 && pH >= 5.5 && pH < 6.5 && nitrogen < 50) {
      return "Sandy";
    }
    
    // Loamy: Balanced moisture (50-70%), neutral pH (6.5-7.5), high nutrients
    if (moisture >= 50 && moisture <= 70 && pH >= 6.5 && pH <= 7.5 && nitrogen > 70) {
      return "Loamy";
    }
    
    // Silt: Moderate-high moisture (60-80%), slightly acidic pH (6.0-6.8), moderate nutrients
    if (moisture >= 60 && moisture <= 80 && pH >= 6.0 && pH < 6.8) {
      return "Silt";
    }
    
    // Default: Use current soil type if detection is uncertain
    return _selectedSoil?.name ?? "Unknown";
  }

  void startNewGame(String landId, String landName, Soil soil, Crop crop, double size, DateTime date) {
    _currentLandId = landId;
    _currentLandName = landName;
    _selectedSoil = soil;
    _selectedCrop = crop;
    _landSize = size;
    _plantingDate = date;
    _currentDay = 1;
    _soilMoisture = soil.waterRetention;
    _soilNutrients = soil.nutrientRichness;
    _growthProgress = 0.0;
    _healthScore = 1.0;
    _energy = 100.0;
    _budget = 1000.0;
    _soilReadiness = 1.0;
    _landPrepScore = 5.0;
    
    // Initial AI Logic for Score
    _cropSelectionScore = (crop.preferredSoils.contains(soil.type)) ? 5.0 : 3.0;
    if (soil.phLevel < crop.minPh || soil.phLevel > crop.maxPh) {
      _cropSelectionScore -= 1.5;
    }

    _isGameOver = false;
    _customActivities = [];
    _gameLog = ["Day 1: Started your farming journey on $size ha of ${soil.name} soil."];
    _history.clear();
    _history.add({
      'day': 1,
      'growth': 0.0,
      'moisture': _soilMoisture,
      'nutrients': _soilNutrients,
      'health': _healthScore,
    });
    notifyListeners();
    _syncToFirestore();
  }

  void nextDay() {
    if (_isGameOver || _selectedCrop == null || _selectedSoil == null) return;

    // Get Weather from Service (Using Simulation as fallback for now)
    final weatherUpdate = WeatherService.getSimulatedWeather(_currentDay);
    
    _currentWeather = weatherUpdate.condition;
    _currentTemp = weatherUpdate.temp;
    double rainfall = weatherUpdate.rainfall;
    double windSpeed = weatherUpdate.windSpeed;

    final result = GameEngine.calculateDailyProgress(
      currentDay: _currentDay,
      crop: _selectedCrop!,
      soil: _selectedSoil!,
      moisture: _soilMoisture,
      nutrients: _soilNutrients,
      health: _healthScore,
      rainfall: rainfall,
      temp: _currentTemp,
      windSpeed: windSpeed,
    );

    _currentDay++;
    _soilMoisture = result.newMoisture;
    _soilNutrients = result.newNutrients;
    _growthProgress += result.growthIncrement;
    _healthScore = result.newHealth;
    
    // Update Risks from Engine
    _pestRisk = result.pestRisk;
    _diseaseRisk = result.diseaseRisk;
    _weedPressure = result.weedPressure;

    _gameLog.insert(0, "Day $_currentDay: ${result.statusMessage} (Temp: ${_currentTemp.toStringAsFixed(1)}°C)");
    
    _history.add({
      'day': _currentDay,
      'growth': _growthProgress,
      'moisture': _soilMoisture,
      'nutrients': _soilNutrients,
      'health': _healthScore,
      'weather': _currentWeather,
      'pestRisk': _pestRisk,
      'diseaseRisk': _diseaseRisk,
    });

    // Daily energy recovery
    _energy = (_energy + 35.0).clamp(0.0, 100.0);

    if (_growthProgress >= 100.0 || _currentDay >= 5) {
      _isGameOver = true;
      _gameLog.insert(0, "Complete: Your 5-day predictive window has concluded!");
    }

    notifyListeners();
    _syncToFirestore();
  }

  void plow() {
    if (_energy >= 10) {
      _energy -= 10;
      _soilReadiness = (_soilReadiness + 0.5).clamp(0.0, 1.0);
      _landPrepScore = (_soilReadiness * 5.0).clamp(0.0, 5.0);
      _gameLog.insert(0, "Day $_currentDay: You plowed the field plots.");
      notifyListeners();
      _syncToFirestore();
    }
  }

  void levelSoil() {
    if (_energy >= 10) {
      _energy -= 10;
      _soilReadiness = (_soilReadiness + 0.5).clamp(0.0, 1.0);
      _landPrepScore = (_soilReadiness * 5.0).clamp(0.0, 5.0);
      _gameLog.insert(0, "Day $_currentDay: You leveled the soil beds.");
      notifyListeners();
      _syncToFirestore();
    }
  }

  void irrigate() {
    // Manual irrigation is disabled in Rain-Only Farming mode. 
    // Data is pulled automatically from the Weather API precipitation field.
    _gameLog.insert(0, "Note: This is a rain-only farm. Manual watering is disabled.");
    notifyListeners();
  }

  void fertilize() {
    if (_energy >= 15) {
      _energy -= 15;
      _soilNutrients = (_soilNutrients + 0.2).clamp(0.0, 1.0);
      _inputManagementScore = (_inputManagementScore + 0.5).clamp(0.0, 5.0);
      _gameLog.insert(0, "Day $_currentDay: You applied organic fertilizer.");
      notifyListeners();
      _syncToFirestore();
    }
  }

  Future<void> loadFromLand(UserLand land) async {
    _currentLandId = land.id;
    _currentLandName = land.name;
    _landSize = land.size;
    
    _selectedSoil = Soil.allSoils.firstWhere((s) => s.name == land.soilType, orElse: () => Soil.allSoils.first);
    if (land.activeCrop != null) {
      _selectedCrop = Crop.allCrops.firstWhere((c) => c.name == land.activeCrop, orElse: () => Crop.allCrops.first);
    }
    
    _currentDay = land.currentDay;
    _growthProgress = land.growthProgress;
    _soilMoisture = land.moisture;
    _soilNutrients = land.nutrients;
    _healthScore = land.health;
    
    _isGameOver = (_currentDay >= 5 || _growthProgress >= 100.0);
    _customActivities = List<Map<String, dynamic>>.from(land.customActivities);
    _gameLog = ["Plot resumed: ${land.name}"];
    notifyListeners();
  }

  Future<void> _syncToFirestore() async {
    if (_currentLandId == null) return;
    
    final land = UserLand(
      id: _currentLandId!,
      name: _currentLandName ?? "My Plot",
      size: _landSize,
      soilType: _selectedSoil?.name ?? "Loamy",
      activeCrop: _selectedCrop?.name,
      currentDay: _currentDay,
      growthProgress: _growthProgress,
      moisture: _soilMoisture,
      nutrients: _soilNutrients,
      health: _healthScore,
      customActivities: _customActivities,
      updatedAt: DateTime.now(),
    );
    
    await _persistence.saveLand(land);
  }

  void addCustomActivity(String type, String title, String description) {
    _customActivities.add({
      'type': type, // 'daily', 'weekly', 'monthly'
      'title': title,
      'description': description,
      'isCompleted': false,
      'day': _currentDay,
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
    _syncToFirestore();
  }

  void removeCustomActivity(int index) {
    if (index >= 0 && index < _customActivities.length) {
      _customActivities.removeAt(index);
      notifyListeners();
      _syncToFirestore();
    }
  }

  void toggleActivityCompletion(int index) {
    if (index >= 0 && index < _customActivities.length) {
      _customActivities[index]['isCompleted'] = !(_customActivities[index]['isCompleted'] ?? false);
      notifyListeners();
      _syncToFirestore();
    }
  }

  List<Map<String, dynamic>> get completedActivities => _customActivities.where((a) => a['isCompleted'] == true).toList();
}
