import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = "AIzaSyCltn91mSr1A_emvctgz-aMfBqSt_1qX-Q";

  /// Analyzes a crop image for pests, diseases, and treatment recommendations.
  static Future<String> analyzeCropImage(Uint8List imageBytes, String userQuestion) async {
    if (_apiKey.isEmpty || _apiKey.startsWith("YOUR")) {
      return "Gemini API Key not configured. AI diagnosis is unavailable.";
    }

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      final prompt = """
        You are an expert AI Agronomist. 
        Analyze the attached image of this crop and address the following user question: '$userQuestion'.
        
        Specifically:
        1. Identify any visible pests, fungal infections, or nutrient deficiencies.
        2. Recommend specific Pesticides, Herbicides, or Fungicides if needed.
        3. Provide clear instructions on how to treat the situation.
        
        Keep your advice professional and technical but easy for a farmer to follow.
      """;

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      return response.text ?? "Unable to analyze the image.";
    } catch (e) {
      return "Error during AI image analysis: $e";
    }
  }

  /// Immersive predictive advice for the farming simulation.
  static Future<String> getFarmingAdvice({
    required String soilType,
    required String cropName,
    required int day,
    required double moisture,
    required double nutrients,
    required double health,
  }) async {
    if (_apiKey.isEmpty || _apiKey.startsWith("YOUR")) {
      return "Gemini API Key not configured.";
    }

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      
      final prompt = """
        You are an expert AI Farming Advisor. 
        Current farm state:
        - Soil: $soilType, Crop: $cropName, Day: $day/5
        - Health: ${(health * 100).toInt()}%
        Give 5-day predictive advice.
      """;

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? "Unable to get advice.";
    } catch (e) {
      return "Error: $e";
    }
  }

  /// General chat interaction.
  static Future<String> getChatResponse(String prompt) async {
    if (_apiKey.isEmpty || _apiKey.startsWith("YOUR")) {
      return "Gemini API Key not configured.";
    }

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? "Unable to get response.";
    } catch (e) {
      return "Error: $e";
    }
  }
}
