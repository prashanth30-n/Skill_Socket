import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'package:barter_system/services/connection_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final String requiredSkill;
  final String offeredSkill;

  const ProfileEditScreen({
    super.key,
    required this.requiredSkill,
    required this.offeredSkill,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final SwipableStackController _controller = SwipableStackController();
  bool isExpanded = true;
  Map<int, bool> expandedProfiles = {};
  List<Map<String, dynamic>> profiles = [];
  bool isLoading = true;
  bool _isSending = false; // debounce flag to prevent multiple sends
  final Set<String> _sentRequests = {}; // track already requested userIds in this session

  @override
  void initState() {
    super.initState();
    fetchMatchingProfiles();
  }

  Future<void> fetchMatchingProfiles() async {
    setState(() => isLoading = true);
    final url = Uri.parse(
        'https://skillsocket-backend.onrender.com/api/users/match?required=${widget.requiredSkill}&offered=${widget.offeredSkill}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        setState(() {
          profiles = data
              .map((u) => {
                    "id": u["_id"] ?? "", // Add user ID
                    "name": u["name"] ?? "",
                    "profileImage": u["profileImage"],
                    "skillsOffered":
                        (u["skillsOffered"] as List?)?.join(', ') ?? "",
                    "skillsRequired":
                        (u["skillsRequired"] as List?)?.join(', ') ?? "",
                    "education": u["education"] ?? "",
                    "location": u["location"] ?? "",
                    "profession": u["profession"] ?? "",
                    "ratingsValue": u["ratingsValue"] ?? 4.5,
                    "reviews": u["reviews"] ?? _staticReviews(), // Use real reviews from backend
                  })
              .toList();
          isLoading = false;
        });
      } else {
        // Show random static profiles if no match found
        setState(() {
          profiles = _randomStaticProfiles();
          isLoading = false;
        });
      }
    } else {
      setState(() {
        profiles = _randomStaticProfiles();
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _staticReviews() {
    return [
      {
        "reviewer": "Demo Reviewer",
        "rating": 5.0,
        "title": "Great collaborator",
        "date": "21 Sep 2025",
        "comment": "Very helpful and skilled."
      }
    ];
  }

  List<String> _getSkillsList(dynamic skills) {
    if (skills == null) return [];
    if (skills is List) {
      return skills.map((e) => e.toString()).toList();
    }
    if (skills is String) {
      return skills.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }


  List<Map<String, dynamic>> _randomStaticProfiles() {
    return [
      {
        "id": "demo_user_1", // Demo user ID
        "name": "Alara",
        "profileImage": null,
        "skillsOffered": widget.requiredSkill,
        "skillsRequired": widget.offeredSkill,
        "education": "B.Tech",
        "location": "India",
        "profession": "Student",
        "reviews": _staticReviews(),
      },
      {
        "id": "demo_user_2", // Demo user ID
        "name": "Ethan",
        "profileImage": null,
        "skillsOffered": widget.requiredSkill,
        "skillsRequired": widget.offeredSkill,
        "education": "M.Tech",
        "location": "USA",
        "profession": "Developer",
        "reviews": _staticReviews(),
      },
      {
        "id": "demo_user_3", // Demo user ID
        "name": "Sophia",
        "profileImage": null,
        "skillsOffered": widget.requiredSkill,
        "skillsRequired": widget.offeredSkill,
        "education": "B.Sc",
        "location": "UK",
        "profession": "Data Scientist",
        "reviews": _staticReviews(),
      },
    ];
  }

  // Send connection request
  Future<void> _sendConnectionRequest(Map<String, dynamic> profile) async {
    final String toId = (profile["id"] ?? "").toString();
    if (toId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid user"), backgroundColor: Colors.red),
      );
      return;
    }

    if (_isSending) {
      return; // prevent overlapping requests
    }

    if (_sentRequests.contains(toId)) {
      // Already requested in this session
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You already sent a request to ${profile["name"]}"),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });
    try {
      final result = await ConnectionService.sendConnectionRequest(
        toUserId: toId,
        message: "Hi ${profile["name"]}, I'd like to connect and exchange skills: ${widget.requiredSkill} for ${widget.offeredSkill}!",
      );

      if (result != null && result['success'] == true) {
        // Success case
        _sentRequests.add(toId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Connection request sent to ${profile["name"]}!"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (result != null && result['success'] == false) {
        // Handle specific error cases from backend
        final errorMessage = result['message'] ?? 'Failed to send request';
        
        if (errorMessage.toLowerCase().contains('already sent')) {
          // Connection request already sent
          _sentRequests.add(toId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Connection request already sent to ${profile["name"]}"),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Other errors (network, validation, etc.)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Null result - unexpected error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Unexpected error sending request to ${profile["name"]}"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error sending connection request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Network error sending request to ${profile["name"]}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Widget _buildProfileCard(Map<String, dynamic> profile, int index) {
    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFFB6E1F0),
                backgroundImage: profile["profileImage"] != null && profile["profileImage"].toString().isNotEmpty
                    ? NetworkImage(profile["profileImage"])
                    : null,
                child: profile["profileImage"] == null || profile["profileImage"].toString().isEmpty
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                profile["name"] ?? "Unknown",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                profile["profession"] ?? "",
                style: const TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 16),

              // Skills Required
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Skills Required",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF123b53),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _getSkillsList(profile["skillsRequired"])
                    .map((skill) => Chip(label: Text(skill.trim())))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // Skills Offered
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Skills Offered",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF123b53),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _getSkillsList(profile["skillsOffered"])
                    .map((skill) => Chip(label: Text(skill.trim())))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // 🌍 Location
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(profile["location"] ?? ""),
                ],
              ),
              const SizedBox(height: 12),

              // 🎓 Education
              Row(
                children: [
                  const Icon(Icons.language, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(profile["education"] ?? ""),
                ],
              ),
              const SizedBox(height: 20),

              // 🔽 Reviews header row
              Row(
                children: [
                  const Text(
                    "Reviews",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF123b53),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Rating number
                  Text(
                    (profile["ratingsValue"] ?? 0).toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Stars (with half star logic)
                  Row(
                    children: List.generate(5, (starIndex) {
                      double rating = (profile["ratingsValue"] ?? 0).toDouble();
                      if (starIndex < rating.floor()) {
                        return const Icon(Icons.star,
                            color: Colors.amber, size: 20);
                      } else if (starIndex < rating && rating % 1 != 0) {
                        return const Icon(Icons.star_half,
                            color: Colors.amber, size: 20);
                      } else {
                        return const Icon(Icons.star_border,
                            color: Colors.amber, size: 20);
                      }
                    }),
                  ),

                  const Spacer(),

                  // Expand/Collapse button
                  IconButton(
                    icon: Icon(
                      expandedProfiles[index] == true
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.black54,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() {
                        expandedProfiles[index] =
                            !(expandedProfiles[index] ?? false);
                      });
                    },
                  ),
                ],
              ),

              // ✅ Show reviews if expanded
              if (expandedProfiles[index] == true) ...[
                const SizedBox(height: 12),
                Column(
                  children: (profile["reviews"] as List<dynamic>).map((review) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reviewer name + rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                review["reviewer"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  double rating =
                                      (review["rating"] ?? 0).toDouble();
                                  if (starIndex < rating.floor()) {
                                    return const Icon(Icons.star,
                                        color: Colors.amber, size: 18);
                                  } else if (starIndex < rating &&
                                      rating % 1 != 0) {
                                    return const Icon(Icons.star_half,
                                        color: Colors.amber, size: 18);
                                  } else {
                                    return const Icon(Icons.star_border,
                                        color: Colors.amber, size: 18);
                                  }
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            review["title"],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            review["date"],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            review["comment"],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const buttonSpacing = 70;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEAEA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFB6E1F0),
                    Color(0xFF66B7D2),
                    Color(0xFF123b53)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.8,
                        width: MediaQuery.of(context).size.width * 0.95,
                        child: SwipableStack(
                          controller: _controller,
                          detectableSwipeDirections: const {
                            SwipeDirection.left,
                            SwipeDirection.right
                          },
                          builder: (context, properties) {
                            if (profiles.isEmpty) {
                              return const Center(
                                  child: Text('No profiles found'));
                            }
                            final profile =
                                profiles[properties.index % profiles.length];
                            return _buildProfileCard(profile, properties.index);
                          },
                          onSwipeCompleted: (index, direction) {
                            // Swiping is purely for navigation/browsing
                            // No messages or actions - just silent navigation
                            // Users must explicitly click buttons to send requests
                          },
                        ),
                      ),
                    ),

                    // Reject button - just move to next profile silently
                    Positioned(
                      bottom: 5,
                      left: (screenWidth / 2) - buttonSpacing - 28,
                      child: FloatingActionButton(
                        heroTag: 'reject',
                        backgroundColor: Colors.redAccent,
                        onPressed: () => _controller.next(
                            swipeDirection: SwipeDirection.left),
                        child: const Icon(Icons.close,
                            size: 30, color: Colors.white),
                      ),
                    ),

                    // Accept button
                    Positioned(
                      bottom: 5,
                      left: (screenWidth / 2) + buttonSpacing - 28,
                      child: FloatingActionButton(
                        heroTag: 'accept',
                        backgroundColor: Colors.green,
                        onPressed: _isSending
                            ? null
                            : () {
                                if (profiles.isNotEmpty) {
                                  final currentIndex =
                                      _controller.currentIndex % profiles.length;
                                  final profile = profiles[currentIndex];
                                  // Send connection request without swiping
                                  _sendConnectionRequest(profile);
                                }
                              },
                        child: const Icon(Icons.check,
                            size: 28, color: Colors.white),
                      ),
                    ),

                    // Back button
                    Positioned(
                      top: 10,
                      left: 10,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
