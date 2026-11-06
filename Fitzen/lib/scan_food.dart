import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'network/api_service.dart';

class ScanFoodPage extends StatefulWidget {
  const ScanFoodPage({super.key});

  @override
  State<ScanFoodPage> createState() => _ScanFoodPageState();
}

class _ScanFoodPageState extends State<ScanFoodPage> with SingleTickerProviderStateMixin {
  // 🚨 GEMINI API KEY
  static const String _geminiApiKey = "";

  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;

  bool _isAnalyzing = false;
  bool _showResults = false;
  bool _isLogging = false;

  // Real Dynamic Data from Gemini
  String _scannedFoodName = "Analyzing Food...";
  int _baseCalories = 0;
  int _baseProtein = 0;
  int _baseCarbs = 0;
  int _baseFat = 0;

  // User Adjustments
  double _portionMultiplier = 1.0;
  String _selectedMeal = "Lunch";
  final List<String> _mealOptions = ["Breakfast", "Lunch", "Dinner", "Snack"];

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scanAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOutSine),
    );

    // Let the user choose Camera or Gallery on startup
    WidgetsBinding.instance.addPostFrameCallback((_) => _chooseImageSource());
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _chooseImageSource() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFC91F2B)),
              title: const Text('Take Photo (Camera)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndAnalyze(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF087B78)),
              title: const Text('Upload from Gallery / Files'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndAnalyze(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 50,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _isAnalyzing = true;
          _showResults = false;
        });

        _scanController.repeat(reverse: true);

        // Call Gemini AI Vision API
        await _analyzeFoodWithGemini(bytes);
      } else {
        if (_imageBytes == null && mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Picker error: $e");
      if (_imageBytes == null && mounted) Navigator.pop(context);
    }
  }

  // ============================================================
  // GEMINI VISION API CALL
  // ============================================================
  Future<void> _analyzeFoodWithGemini(Uint8List bytes) async {
    final base64Image = base64Encode(bytes);

    final prompt = """
    Identify the primary food item in this picture. Estimate nutritional facts for
     a standard single serving.
    Return strictly JSON without markdown backticks or formatting:
    {
      "foodName": "Food Name",
      "calories": 250,
      "protein": 15,
      "carbs": 30,
      "fat": 8
    }
    """;

    final requestBody = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt},
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Image,
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "response_mime_type": "application/json"
      }
    });

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=$_geminiApiKey',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawText = data['candidates'][0]['content']['parts'][0]['text'];

        rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
        final parsed = jsonDecode(rawText);

        setState(() {
          _scannedFoodName = parsed['foodName'] ?? "Identified Food";
          _baseCalories = (parsed['calories'] as num?)?.toInt() ?? 0;
          _baseProtein = (parsed['protein'] as num?)?.toInt() ?? 0;
          _baseCarbs = (parsed['carbs'] as num?)?.toInt() ?? 0;
          _baseFat = (parsed['fat'] as num?)?.toInt() ?? 0;
          _isAnalyzing = false;
          _showResults = true;
        });
      } else {
        throw Exception("Gemini API Error: ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      debugPrint("AI error: $e");
      setState(() {
        _scannedFoodName = "Could not identify plate";
        _baseCalories = 200;
        _baseProtein = 10;
        _baseCarbs = 20;
        _baseFat = 5;
        _isAnalyzing = false;
        _showResults = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI Error: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: const Color(0xFFC91F2B),
          ),
        );
      }
    } finally {
      _scanController.stop();
    }
  }

  // ============================================================
  // LOG FOOD TO DATABASE
  // ============================================================
  Future<void> _logFood() async {
    setState(() => _isLogging = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('userEmail') ?? prefs.getString('email') ?? '';

      final now = DateTime.now();
      final dateStr =
          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

      final response = await ApiService.logScannedFood(
        email: email,
        date: dateStr,
        mealType: _selectedMeal,
        foodName: _scannedFoodName,
        calories: (_baseCalories * _portionMultiplier).round(),
        protein: (_baseProtein * _portionMultiplier).round(),
        carbs: (_baseCarbs * _portionMultiplier).round(),
        fat: (_baseFat * _portionMultiplier).round(),
      );

      if (response['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Food logged successfully!'),
              backgroundColor: Color(0xFF149447),
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error logging food'),
            backgroundColor: Color(0xFFC91F2B),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. IMAGE DISPLAY WITH ERROR HANDLING
          if (_imageBytes != null)
            Positioned.fill(
              child: Image.memory(
                _imageBytes!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54, size: 60),
                  ),
                ),
              ),
            ),

          // 2. SCANNING LASER ANIMATION
          if (_isAnalyzing)
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Positioned.fill(
                  child: Align(
                    alignment: Alignment(0, _scanAnimation.value),
                    child: Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF087B78),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF087B78).withOpacity(0.8),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          if (_isAnalyzing)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "FitZen AI is identifying nutrition...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                    ),
                  ),
                ],
              ),
            ),

          // 3. TOP ACTION BAR
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                GestureDetector(
                  onTap: _chooseImageSource,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "Retake",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. RESULTS BOTTOM SHEET
          if (_showResults)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF087B78), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _scannedFoodName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF171717),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // MACROS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroCircle(
                          "Calories",
                          (_baseCalories * _portionMultiplier).round().toString(),
                          "kcal",
                          const Color(0xFFFF8A3D),
                        ),
                        _buildMacroCircle(
                          "Protein",
                          (_baseProtein * _portionMultiplier).round().toString(),
                          "g",
                          const Color(0xFFC91F2B),
                        ),
                        _buildMacroCircle(
                          "Carbs",
                          (_baseCarbs * _portionMultiplier).round().toString(),
                          "g",
                          const Color(0xFF087B78),
                        ),
                        _buildMacroCircle(
                          "Fat",
                          (_baseFat * _portionMultiplier).round().toString(),
                          "g",
                          const Color(0xFF665B5B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // PORTION SLIDER
                    Text(
                      "Portion Size: ${_portionMultiplier.toStringAsFixed(1)}x",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF665B5B),
                      ),
                    ),
                    Slider(
                      value: _portionMultiplier,
                      min: 0.5,
                      max: 3.0,
                      divisions: 5,
                      activeColor: const Color(0xFFC91F2B),
                      onChanged: (val) => setState(() => _portionMultiplier = val),
                    ),
                    const SizedBox(height: 10),

                    // MEAL TYPE SELECTOR
                    const Text(
                      "Add to",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF665B5B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: _mealOptions.map((meal) {
                        final isSelected = _selectedMeal == meal;
                        return ChoiceChip(
                          label: Text(meal),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFFE2CA),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFFFF8A3D) : const Color(0xFF665B5B),
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) => setState(() => _selectedMeal = meal),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),

                    // LOG BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLogging ? null : _logFood,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC91F2B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isLogging
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "Log Food",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMacroCircle(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 4),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.0,
                  ),
                ),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF665B5B)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF171717)),
        ),
      ],
    );
  }
}