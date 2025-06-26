import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Import the official package

class GeminiService {
  late final GenerativeModel _model;
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  GeminiService() {
    if (_apiKey.isEmpty) {
      // print('WARNING: Gemini API key is missing. AI functionality might not work.');
      // You should ensure your UI handles this by disabling AI features or showing an error.
      // Optionally, you can throw an exception or set a flag here.
    } else {
      // Initialize the GenerativeModel with the desired model and your API key
      _model = GenerativeModel(
        model:
            'gemini-2.0-flash', // **UPDATED: Changed from gemini-1.0-flash to gemini-2.0-flash**
        apiKey: _apiKey,
      );
    }
  }

  Future<String> getGeminiResponse(String prompt) async {
    if (_apiKey.isEmpty) {
      return 'Error: Gemini API key is missing. Cannot send AI request.';
    }

    // Prepare the content for the model as a list of Content objects
    final content = [Content.text(prompt)];

    try {
      // Call the generateContent method provided by the SDK
      final response = await _model.generateContent(content);

      // Extract the text from the response
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        // **UNCOMMENTED: Print statement for debugging**
        // print('Gemini AI Response Error: No text found in response. Raw data: ${response.toMap()}');
        return 'Error: Could not get a meaningful response from AI.';
      }
    } on GenerativeAIException catch (e) {
      // Catch specific errors from the Generative AI package
      // **UNCOMMENTED: Print statement for debugging**
      // print('Gemini AI Exception: ${e.message}');
      return 'Error: AI request failed: ${e.message}';
    } catch (e) {
      // Catch any other unexpected errors
      // **UNCOMMENTED: Print statement for debugging**
      // print('Gemini API Unexpected Exception: $e');
      return 'Error: An unexpected error occurred while connecting to AI.';
    }
  }
}