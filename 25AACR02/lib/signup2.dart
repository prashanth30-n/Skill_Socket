import 'package:barter_system/home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class SignUpPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const SignUpPage({super.key, this.userData});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  String? _currentWorkingStatus;
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _skillsRequiredController =
      TextEditingController();
  final TextEditingController _skillsOfferedController =
      TextEditingController();

  @override
  void dispose() {
    _educationController.dispose();
    _professionController.dispose();
    _skillsRequiredController.dispose();
    _skillsOfferedController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  Future<String?> _uploadProfileImageToCloudinary(File profileImageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://skillsocket-backend.onrender.com/api/user/upload-logo'),
      );

      // Add the file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'logo',
          profileImageFile.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['logoUrl'];
      } else {
        print(
            'Profile image upload error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Profile image upload exception: $e');
      return null;
    }
  }

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate() || _currentWorkingStatus == null) {
      setState(() {
        _errorMessage = 'Please fill all required fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Upload profile image first if provided
      String? profileImageUrl;
      if (widget.userData?['profileImageFile'] != null) {
        final profileImageFile = widget.userData!['profileImageFile'] as File;
        profileImageUrl =
            await _uploadProfileImageToCloudinary(profileImageFile);
        if (profileImageUrl == null) {
          setState(() {
            _errorMessage = 'Failed to upload profile image. Please try again.';
            _isLoading = false;
          });
          return;
        }
      }

      // Parse date of birth from DD/MM/YYYY to ISO format
      String? dateOfBirth;
      if (widget.userData?['dateOfBirth'] != null &&
          widget.userData!['dateOfBirth'].isNotEmpty) {
        final parts = widget.userData!['dateOfBirth'].split('/');
        if (parts.length == 3) {
          final day = parts[0].padLeft(2, '0');
          final month = parts[1].padLeft(2, '0');
          final year = parts[2];
          dateOfBirth = '$year-$month-$day';
        }
      }

      // Combine data from both pages
      final signupData = {
        'firstName': widget.userData?['firstName'] ?? '',
        'lastName': widget.userData?['lastName'] ?? '',
        'email': widget.userData?['email'] ?? '',
        'password': widget.userData?['password'] ?? '',
        'dateOfBirth': dateOfBirth,
        'gender': widget.userData?['gender'] ?? '',
        'location': widget.userData?['location'] ?? '',
        'education': _educationController.text.trim(),
        'currentlyWorking': _currentWorkingStatus ?? '',
        'profession': _professionController.text.trim(),
        'skillsRequired': _skillsRequiredController.text
            .trim()
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'skillsOffered': _skillsOfferedController.text
            .trim()
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'profileImage': profileImageUrl ?? '',
      };

      print('Sending signup data: $signupData');

      final response = await http.post(
        Uri.parse('https://skillsocket-backend.onrender.com/api/auth/signup'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(signupData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to community selection
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MyHomePage(title: 'SkillSocket')),
          );
        }
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Registration failed';
        });
      }
    } catch (e) {
      print('Signup error: $e');
      setState(() {
        _errorMessage =
            'Network error. Please check your connection and ensure the backend server is running.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB6E1F0), Color(0xFF66B7D2), Color(0xFF123b53)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 60.0, left: 20.0),
                child: Column(children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white70,
                    child: Text("LOGO", style: TextStyle(color: Colors.black)),
                  ),
                  const SizedBox(height: 8),
                  const Text("SkillSocket",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                padding: const EdgeInsets.all(25.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Text(
                        'Education *',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      _buildPurpleTextField(_educationController,
                          hint: 'Education',
                          validator: (value) =>
                              _validateRequired(value, 'Education')),
                      const SizedBox(height: 25),

                      const Text(
                        'Are you currently working? *',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'Yes',
                            groupValue: _currentWorkingStatus,
                            onChanged: (String? value) {
                              setState(() {
                                _currentWorkingStatus = value;
                              });
                            },
                            activeColor: const Color(0xFF6A0DAD),
                          ),
                          const Text('Yes',
                              style: TextStyle(color: Colors.black87)),
                          const SizedBox(width: 20),
                          Radio<String>(
                            value: 'No',
                            groupValue: _currentWorkingStatus,
                            onChanged: (String? value) {
                              setState(() {
                                _currentWorkingStatus = value;
                              });
                            },
                            activeColor: Color(0xFF123b53),
                          ),
                          const Text('No',
                              style: TextStyle(color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 25),

                      const Text(
                        'Profession *',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      _buildPurpleTextField(_professionController,
                          hint: 'Profession',
                          validator: (value) =>
                              _validateRequired(value, 'Profession')),
                      const SizedBox(height: 25),

                      const Text(
                        'Skills Required',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      _buildPurpleTextField(_skillsRequiredController,
                          hint: 'Skills you want to learn (comma separated)'),
                      const SizedBox(height: 25),

                      const Text(
                        'Skills offered',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      _buildPurpleTextField(_skillsOfferedController,
                          hint: 'Skills you can teach (comma separated)'),
                      const SizedBox(height: 50),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF123b53),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text("PREV",
                                  style: TextStyle(color: Colors.white)),
                            ),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submitSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF123b53),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text("SUBMIT",
                                      style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Updated to accept hint text and validator
  Widget _buildPurpleTextField(TextEditingController controller,
      {String hint = '', String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black45),
        filled: true,
        fillColor: const Color(0xFFB6E1F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }
}