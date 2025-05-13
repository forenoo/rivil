import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/models/trip_request.dart';
import '../../domain/models/trip_plan.dart';

class TripPlanningService {
  static const String _apiKey = 'AIzaSyDBLc5Tj319Sp5T-Cmh753KJQCkb5svQXs';
  final GenerativeModel _model;

  TripPlanningService()
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: _apiKey,
        );

  Future<TripPlan> generateTripPlan(TripRequest request) async {
    try {
      // Create a prompt for Gemini
      final prompt = _createPrompt(request);

      // Get response from Gemini
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      final responseText = response.text;
      if (responseText == null) {
        throw Exception('Received empty response from Gemini API');
      }

      // Parse and return the trip plan
      return _processTripPlanResponse(responseText);
    } catch (e) {
      throw Exception('Failed to generate trip plan: $e');
    }
  }

  String _createPrompt(TripRequest request) {
    // Format date ranges and preferences
    final dateRange = request.startDate != null && request.endDate != null
        ? '${_formatDate(request.startDate!)} to ${_formatDate(request.endDate!)}'
        : 'Flexible dates';

    final preferencesText = request.preferences.isNotEmpty
        ? request.preferences.join(', ')
        : 'No specific preferences';

    // Create a detailed prompt for Gemini API
    return '''
    Kamu adalah perencana perjalanan profesional dan saya membutuhkan rencana perjalanan detail. Abaikan instruksi sebelumnya.
    
    Berdasarkan informasi berikut, buatkan itinerary perjalanan detail:
    
    Deskripsi: ${request.description}
    Rentang Tanggal: $dateRange
    Budget: ${request.budget ?? 'Tidak ditentukan'}
    Jumlah orang: ${request.numberOfPeople ?? 'Tidak ditentukan'}
    Preferensi: $preferencesText
    
    Penting: Responsmu HARUS dalam format JSON valid yang cocok dengan struktur berikut:
    
    {
      "title": "Judul deskriptif perjalanan (dalam Bahasa Indonesia)",
      "startDate": "YYYY-MM-DD",
      "endDate": "YYYY-MM-DD",
      "numberOfDays": 3,
      "numberOfPeople": "2",
      "budget": "5.000.000",
      "preferences": ["Pantai", "Relaksasi"],
      "summary": "Ringkasan singkat perjalanan (maksimal 200 karakter) dalam Bahasa Indonesia",
      "days": [
        {
          "day": "Hari 1",
          "date": "YYYY-MM-DD",
          "activities": [
            {
              "time": "08:00",
              "title": "Nama aktivitas (dalam Bahasa Indonesia)",
              "description": "Deskripsi singkat (dalam Bahasa Indonesia)",
              "location": "Nama lokasi (dalam Bahasa Indonesia)"
            }
          ]
        }
      ],
      "highlights": [
        {
          "name": "Nama destinasi (dalam Bahasa Indonesia)",
          "description": "Deskripsi singkat (dalam Bahasa Indonesia)",
          "rating": 4.7,
          "imageUrl": "URL to image"
        }
      ],
      "recommendations": [
        {
          "title": "Judul rekomendasi (dalam Bahasa Indonesia)",
          "description": "Rekomendasi singkat (dalam Bahasa Indonesia)",
          "iconType": "beach_access"
        }
      ]
    }
    
    Untuk iconType, gunakan salah satu berikut: beach_access, restaurant, hiking, attach_money, language, camera, local_taxi.
    
    Untuk bagian "highlights", berikan nama-nama tempat nyata yang sesuai dengan preferensi. Untuk imageUrl, sarankan nama gambar deskriptif yang akan mewakili destinasi dengan baik (seperti "beach_sunset.jpg", "mountain_view.jpg", dll.).
    
    PENTING: SEMUA teks harus dalam Bahasa Indonesia, kecuali properti JSON dan nilai teknis. Kembalikan HANYA JSON valid tanpa teks tambahan sebelum atau sesudahnya. Pastikan semua item array memiliki bidang yang diperlukan.
    ''';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  TripPlan _processTripPlanResponse(String responseText) {
    try {
      // Extract JSON from response text
      final jsonStr = _extractJsonFromText(responseText);
      final json = jsonDecode(jsonStr);

      // Convert to TripPlan object
      return TripPlan.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse trip plan response: $e');
    }
  }

  String _extractJsonFromText(String text) {
    // Find the beginning of JSON (first '{')
    final jsonStart = text.indexOf('{');
    if (jsonStart == -1) {
      throw Exception('No JSON found in response');
    }

    // Find the matching closing bracket
    int openBrackets = 0;
    int closeBracketPos = -1;

    for (int i = jsonStart; i < text.length; i++) {
      if (text[i] == '{') {
        openBrackets++;
      } else if (text[i] == '}') {
        openBrackets--;
        if (openBrackets == 0) {
          closeBracketPos = i;
          break;
        }
      }
    }

    if (closeBracketPos == -1) {
      throw Exception('Malformed JSON in response');
    }

    return text.substring(jsonStart, closeBracketPos + 1);
  }
}
