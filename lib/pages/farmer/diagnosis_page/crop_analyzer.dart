import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CropAnalyzer extends StatefulWidget {
  const CropAnalyzer({super.key});

  @override
  _CropAnalyzerState createState() => _CropAnalyzerState();
}

class _CropAnalyzerState extends State<CropAnalyzer> {
  File? _image;
  String? _result;
  String? _suggestions;
  bool _isLoading = false;
  bool _isLoadingSuggestions = false;

  final picker = ImagePicker();

  static const String OPENAI_API_KEY =
      'Replace with your actual OpenAI API key';

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = null;
        _suggestions = null;
      });
    }
  }

  Future<String> _getChatGPTSuggestions(
      String cropType, String diseaseType) async {
    try {
      final response = await http
          .post(
            Uri.parse('add your api.openai.com'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $OPENAI_API_KEY',
            },
            body: jsonEncode({
              'model': 'gpt-3.5-turbo',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are an agricultural expert providing practical advice for crop disease management. Provide clear, actionable suggestions in a structured format.'
                },
                {
                  'role': 'user',
                  'content':
                      'I have detected $diseaseType in my $cropType crop. Please provide practical suggestions for treatment and prevention. Include: 1) Immediate treatment steps, 2) Prevention measures, 3) Organic solutions if available, 4) When to consult a professional. Keep the response concise and actionable.'
                }
              ],
              'max_tokens': 500,
              'temperature': 0.7,
            }),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        log('OpenAI API Error: ${response.statusCode} - ${response.body}');
        return 'Unable to get suggestions. Please check your API key and try again.';
      }
    } catch (e) {
      log('Error getting ChatGPT suggestions: $e');
      return 'Error getting suggestions: ${e.toString()}';
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) {
      if (!mounted) return;
      setState(() => _result = 'Please select an image first');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _result = 'Analyzing image...';
      _suggestions = null;
    });

    try {
      // Step 1: Check if it's a crop
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'Train your Model for crop vs no crop and Create api key by deploying on Render'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', _image!.path),
      );
      final response = await request.send().timeout(Duration(seconds: 30));
      final cropCheckResponseBody = await response.stream.bytesToString();
      log('Crop API response: $cropCheckResponseBody');
      final cropCheckResult = jsonDecode(cropCheckResponseBody);
      final cropLabel = cropCheckResult['prediction']?.toString().toLowerCase();

      if (cropLabel == null) throw Exception('Crop API did not return a label');

      if (cropLabel == 'not_crop') {
        if (!mounted) return;
        setState(() {
          _result = 'Image does not contain a crop';
          _isLoading = false;
        });
        return;
      }

      // Step 2: Analyze disease
      final diseaseRequest = http.MultipartRequest(
        'POST',
        Uri.parse(
            'Train your Model for disease Detection and Create api key by deploying on Render'),
      );
      diseaseRequest.files.add(
        await http.MultipartFile.fromPath('file', _image!.path),
      );
      final diseaseResponse = await diseaseRequest.send();
      final diseaseResponseBody = await diseaseResponse.stream.bytesToString();

      log('Disease API response: $diseaseResponseBody');
      final diseaseResult = jsonDecode(diseaseResponseBody);
      final diseaseLabel = diseaseResult['prediction'];

      if (!mounted) return;
      setState(() {
        _result = 'Crop: $cropLabel\nDisease: $diseaseLabel';
        _isLoading = false;
      });

      // Step 3: Get AI suggestions for the disease
      if (diseaseLabel != null &&
          diseaseLabel.toString().toLowerCase() != 'healthy') {
        if (!mounted) return;
        setState(() => _isLoadingSuggestions = true);

        final suggestions =
            await _getChatGPTSuggestions(cropLabel, diseaseLabel);

        if (!mounted) return;
        setState(() {
          _suggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    } on SocketException catch (e) {
      if (!mounted) return;
      setState(() {
        _result = 'Network error: Unable to reach server\n${e.message}';
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _result = 'Request timed out: Server took too long to respond';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result = 'Error: ${e.toString()}';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingSuggestions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Crop Analyzer',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade200, Colors.green.shade50],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.97),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.12),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_image != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_image!, height: 200),
                          )
                        else
                          Column(
                            children: [
                              Icon(
                                Icons.agriculture,
                                size: 90,
                                color: Colors.green[300],
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No image selected.',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: 24),

                        // Analysis Results
                        if (_isLoading)
                          Column(
                            children: [
                              CircularProgressIndicator(
                                  color: Colors.green[700]),
                              SizedBox(height: 10),
                              Text(
                                'Analyzing...',
                                style: TextStyle(color: Colors.green[700]),
                              ),
                            ],
                          )
                        else if (_result != null)
                          Card(
                            color: Colors.green[50],
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Analysis Result:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[900],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _result!,
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: Colors.green[900],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // AI Suggestions Section
                        if (_isLoadingSuggestions)
                          Column(
                            children: [
                              SizedBox(height: 16),
                              CircularProgressIndicator(
                                  color: Colors.blue[700]),
                              SizedBox(height: 10),
                              Text(
                                'Getting AI suggestions...',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                            ],
                          )
                        else if (_suggestions != null)
                          Column(
                            children: [
                              SizedBox(height: 16),
                              Card(
                                color: Colors.blue[50],
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.lightbulb,
                                              color: Colors.blue[700],
                                              size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'AI Treatment Suggestions:',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[900],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        _suggestions!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue[900],
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              icon: Icon(Icons.photo, color: Colors.green[900]),
                              label: Text('Gallery'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[100],
                                foregroundColor: Colors.green[900],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  await _getImage(ImageSource.gallery);
                                } catch (e) {
                                  setState(() {
                                    _result = 'Error picking image: $e';
                                  });
                                }
                              },
                            ),
                            ElevatedButton.icon(
                              icon: Icon(Icons.camera_alt,
                                  color: Colors.green[900]),
                              label: Text('Camera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[100],
                                foregroundColor: Colors.green[900],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  await _getImage(ImageSource.camera);
                                } catch (e) {
                                  setState(() {
                                    _result = 'Error picking image: $e';
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 18),
                        ElevatedButton.icon(
                          icon: Icon(Icons.search, color: Colors.white),
                          label: Text('Analyze'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[800],
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          onPressed: _analyzeImage,
                        ),
                      ],
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
}
