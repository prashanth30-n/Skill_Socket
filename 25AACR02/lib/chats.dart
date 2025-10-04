import 'package:flutter/material.dart';
import 'chat.dart';
import 'new_chat_screen.dart';
import 'package:barter_system/profile.dart';
import 'package:barter_system/reviews.dart';
import 'package:barter_system/notification.dart';
import 'package:barter_system/history.dart';
import 'package:barter_system/login.dart';
import 'package:barter_system/services/chat_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'notification_helper.dart';

class Chats extends StatefulWidget {
  const Chats({super.key});

  @override
  State<Chats> createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  List<Map<String, dynamic>> chats = [];
  bool _isLoading = true;
  String? currentUserId;
  late IO.Socket socket;

  String searchQuery = ""; // <-- Add this line

  @override
  void initState() {
    super.initState();
    NotificationHelper.initialize();
    _initializeChats();
  }

  Future<void> _initializeChats() async {
    // Get current user ID
    currentUserId = await ChatService.getCurrentUserId();

    if (currentUserId != null) {
      await _loadChats();
      _connectToSocket();
    } else {
      await _loadChats();
    }
  }

  void _connectToSocket() {
    socket = IO.io(
      "https://skillsocket-backend.onrender.com/",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print("Connected to socket server");
      if (currentUserId != null) {
        socket.emit("joinRoom", currentUserId);
      }
    });

    socket.on("receiveMessage", (data) {
      if (mounted) {
        _updateChatWithNewMessage(data);
        // Show notification if message is from another user
        if (data['from'] != null && data['from']['_id'] != currentUserId) {
          NotificationHelper.showNotification(
            'New Message from ${data['from']['name'] ?? 'Someone'}',
            data['content'] ?? '',
          );
        }
      }
    });

    socket.onError((error) {
      print("Socket error: $error");
    });

    socket.onDisconnect((_) {
      print("Disconnected from socket server");
    });
  }

  void _updateChatWithNewMessage(dynamic messageData) {
    setState(() {
      // Find the chat with the sender/receiver
      String partnerId;
      if (messageData['from']['_id'] == currentUserId) {
        partnerId = messageData['to']['_id'];
      } else {
        partnerId = messageData['from']['_id'];
      }

      // Update existing chat or add new one
      int chatIndex =
          chats.indexWhere((chat) => chat['participant']['_id'] == partnerId);

      if (chatIndex != -1) {
        // Update existing chat
        chats[chatIndex]['lastMessage'] = {
          'content': messageData['content'],
          'createdAt': messageData['createdAt'],
          'from': messageData['from']['_id'],
          'seen': messageData['seen'] ?? false
        };
        // Move to top
        var updatedChat = chats.removeAt(chatIndex);
        chats.insert(0, updatedChat);
      } else {
        // Add new chat
        final partner = messageData['from']['_id'] == currentUserId
            ? messageData['to']
            : messageData['from'];
        chats.insert(0, {
          '_id': '${currentUserId}_$partnerId',
          'participant': {
            '_id': partner['_id'],
            'name': partner['name'],
            'email': partner['email'],
            'profileImage': partner['profileImage']
          },
          'lastMessage': {
            'content': messageData['content'],
            'createdAt': messageData['createdAt'],
            'from': messageData['from']['_id'],
            'seen': messageData['seen'] ?? false
          }
        });
      }
    });
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chatData = await ChatService.getUserChats();
      if (chatData != null) {
        setState(() {
          chats = chatData;
        });
      } else {
        // Fallback to sample data if no chats found or API fails
        setState(() {
          chats = [
            {
              '_id': '1',
              'participant': {
                '_id': 'user1',
                'name': 'Alice',
                'email': 'alice@example.com'
              },
              'lastMessage': {
                'content': 'Hey! How are you?',
                'createdAt': DateTime.now()
                    .subtract(const Duration(hours: 1))
                    .toIso8601String(),
              }
            },
            {
              '_id': '2',
              'participant': {
                '_id': 'user2',
                'name': 'Bob',
                'email': 'bob@example.com'
              },
              'lastMessage': {
                'content': 'What\'s up?',
                'createdAt': DateTime.now()
                    .subtract(const Duration(days: 1))
                    .toIso8601String(),
              }
            },
          ];
        });
      }
    } catch (e) {
      print('Error loading chats: $e');
      // Show sample data on error
      setState(() {
        chats = [
          {
            '_id': '1',
            'participant': {
              '_id': 'user1',
              'name': 'Alice',
              'email': 'alice@example.com'
            },
            'lastMessage': {
              'content': 'Hey! How are you?',
              'createdAt': DateTime.now()
                  .subtract(const Duration(hours: 1))
                  .toIso8601String(),
            }
          },
        ];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _formatLastMessageTime(String timestamp) {
    try {
      final messageTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(messageTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} min ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  void dispose() {
    if (currentUserId != null) {
      socket.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter chats based on searchQuery
    final filteredChats = chats.where((chat) {
      final participant = chat['participant'];
      final name = participant['name']?.toLowerCase() ?? '';
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFF123b53),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
                child: Row(
              children: [
                /*IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back_ios_new_rounded),
                  color: Color.fromARGB(255, 255, 255, 255),
                ),*/
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'SkillSocket',
                      style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 39),
                    ),
                  ),
                ),
              ],
            )),
            ListTile(
              leading: Icon(
                Icons.history,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              title: Text(
                'History',
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => History()));
              },
            ),
            Divider(color: Colors.white, thickness: 1),
            ListTile(
              leading: Icon(
                Icons.reviews,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              title: Text(
                'Reviews',
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Reviews()));
              },
            ),
            Divider(color: Colors.white, thickness: 1),
            ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
                title: Text(
                  'Sign Out',
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => LoginScreen()));
                }),
            Divider(color: Colors.white, thickness: 1),
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'SkillSocket',
          style: TextStyle(
              fontSize: 20,
              // fontStyle: FontStyle.italic,
              color: Color.fromARGB(255, 255, 255, 255)),
        ),
        backgroundColor: Color(0xFF123b53),
        iconTheme:
            IconThemeData(color: const Color.fromARGB(255, 255, 255, 255)),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Notifications()));
              },
              icon: Icon(Icons.notifications)),
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Profile()));
              },
              icon: Icon(Icons.person_rounded)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search chats...",
                filled: true,
                fillColor: const Color(0xFF66B7D2),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                hintStyle: const TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF123b53),
                    ),
                  )
                : filteredChats.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No chats found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start a conversation with someone!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadChats,
                        child: ListView.separated(
                          itemCount: filteredChats.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final chat = filteredChats[index];
                            final participant = chat['participant'];
                            final lastMessage = chat['lastMessage'];
                            final bool isUnseen =
                                lastMessage['seen'] == false &&
                                    lastMessage['from'] != currentUserId;

                            return ListTile(
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFB6E1F0),
                                    child: Text(
                                      participant['name'][0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF123b53),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Unread message indicator (like WhatsApp)
                                  if (isUnseen)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Text(
                                          '1',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                participant['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                lastMessage['content'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isUnseen ? Colors.green : Colors.black,
                                  fontWeight: isUnseen
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: Text(
                                _formatLastMessageTime(
                                    lastMessage['createdAt']),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Chat(
                                      chatId: chat['_id'],
                                      recipientId: participant['_id'],
                                      name: participant['name'],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewChatScreen()),
          );
        },
        backgroundColor: const Color(0xFF123b53),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
