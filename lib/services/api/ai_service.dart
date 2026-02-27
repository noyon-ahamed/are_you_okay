import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

final aiServiceProvider = Provider<GeminiAIService>((ref) => GeminiAIService());

class GeminiAIService {
  static const String _apiKey = 'AIzaSyBffselD4Uhe5bzLLEXjgxxGZRZoOK6GBQ';

  late final GenerativeModel _model;
  late ChatSession _chat;

  GeminiAIService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'তুমি একজন বাংলাদেশি স্বাস্থ্য সহকারী AI। তোমার নাম "স্বাস্থ্য সহকারী"।\n'
        'তুমি বাংলায় উত্তর দেবে (ইউজার ইংরেজিতে জিজ্ঞেস করলে ইংরেজিতেও দিতে পারো)।\n'
        'তুমি সাধারণ স্বাস্থ্য পরামর্শ, মানসিক স্বাস্থ্য সাপোর্ট, এবং প্রাথমিক চিকিৎসা তথ্য দেবে।\n'
        'গুরুত্বপূর্ণ: তুমি কোনো ডাক্তার নও। গুরুতর সমস্যার জন্য সবসময় ডাক্তারের কাছে যেতে বলবে।\n'
        'তোমার উত্তর সংক্ষিপ্ত, স্পষ্ট, এবং সহানুভূতিশীল হবে।\n'
        'বাংলাদেশের জরুরি নম্বর: 999 (জাতীয়), 199 (অ্যাম্বুলেন্স), 109 (নারী হেল্পলাইন)।',
      ),
      generationConfig: GenerationConfig(
        maxOutputTokens: 1024,
        temperature: 0.7,
      ),
    );
    _chat = _model.startChat();
  }

  /// Send a message and get a response
  Future<String> sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      final text = response.text;
      if (text == null || text.isEmpty) {
        return 'দুঃখিত, উত্তর পাওয়া যায়নি। আবার চেষ্টা করুন।';
      }
      return text;
    } catch (e) {
      debugPrint('Gemini AI error: $e');
      if (e.toString().contains('blocked') || e.toString().contains('safety')) {
        return 'দুঃখিত, এই প্রশ্নের উত্তর দেওয়া সম্ভব হচ্ছে না। অনুগ্রহ করে অন্যভাবে জিজ্ঞেস করুন।';
      }
      rethrow;
    }
  }

  /// Reset chat session (clear conversation history)
  void resetChat() {
    _chat = _model.startChat();
  }
}
