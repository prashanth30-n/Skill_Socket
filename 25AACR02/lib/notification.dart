import 'package:flutter/material.dart';
import 'package:barter_system/services/connection_service.dart';
import 'package:barter_system/services/notification_service.dart';
import 'package:barter_system/chat.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  Map<String, List<Map<String, dynamic>>> notifications = {};
  bool isLoading = true;
  List<Map<String, dynamic>> connectionRequests = [];
  List<Map<String, dynamic>> allNotifications = [];
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load both connection requests and general notifications
      final requests = await ConnectionService.getReceivedRequests();
      final notificationsData = await NotificationService.getNotifications();

      if (requests != null) {
        connectionRequests = requests;
      }

      if (notificationsData != null) {
        allNotifications =
            List<Map<String, dynamic>>.from(notificationsData['data'] ?? []);
        unreadCount = notificationsData['unreadCount'] ?? 0;
      }

      _buildNotificationsMap();
    } catch (e) {
      print('Error loading notifications: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  void _buildNotificationsMap() {
    Map<String, List<Map<String, dynamic>>> tempNotifications = {
      "Today": [],
    };

    // Add general notifications (excluding message notifications)
    for (var notification in allNotifications) {
      // Skip message notifications - they don't belong in notifications tab
      if (notification['type'] == 'message') continue;

      tempNotifications["Today"]!.add({
        "id": notification['_id'],
        "type": notification['type'],
        "title": notification['title'],
        "body": notification['body'],
        "time": NotificationService.formatNotificationTime(
            notification['createdAt']),
        "icon": Icons.notifications,
        "profileImage": notification['sender']?['profileImage'],
        "read": notification['read'] ?? false,
        "data": notification['data'] ?? {},
      });
    }

    // Add connection requests
    for (var request in connectionRequests) {
      tempNotifications["Today"]!.add({
        "type": "connection_request",
        "requestId": request["_id"],
        "user": request["from"]["name"],
        "userId": request["from"]["_id"],
        "profileImage":
            request["from"]["profileImage"] ?? request["from"]["logo"],
        "userEmail": request["from"]["email"],
        "action": "sent you a connection request",
        "message": request["message"] ?? "",
        "time": _formatTime(request["createdAt"]),
        "icon": Icons.person_add,
        "accepted": false,
      });
    }

    // Add some static notifications for demo
    tempNotifications["Today"]!.addAll([
      {
        "type": "normal",
        "user": "John",
        "action": "liked your post",
        "time": "2h ago",
        "icon": Icons.thumb_up_alt_outlined,
        "showThumbnail": true
      },
    ]);

    setState(() {
      notifications = tempNotifications;
    });
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  void _showOverlayMessage(String message) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        left: MediaQuery.of(context).size.width * 0.2,
        width: MediaQuery.of(context).size.width * 0.6,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Future<void> _acceptConnectionRequest(String section, int index) async {
    final notification = notifications[section]?[index];
    if (notification == null) return;

    final requestId = notification["requestId"];
    final userName = notification["user"];
    final userId = notification["userId"];

    try {
      final success =
          await ConnectionService.acceptConnectionRequest(requestId);

      if (success) {
        setState(() {
          notifications[section]?[index]["accepted"] = true;
        });

        _showOverlayMessage("Connection request accepted!");

        // Navigate to chat after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Chat(
                  chatId: '${userId}_connection',
                  recipientId: userId,
                  name: userName,
                ),
              ),
            );
          }
        });
      } else {
        _showOverlayMessage("Failed to accept request");
      }
    } catch (e) {
      print('Error accepting connection request: $e');
      _showOverlayMessage("Error accepting request");
    }
  }

  Future<void> _rejectConnectionRequest(String section, int index) async {
    final notification = notifications[section]?[index];
    if (notification == null) return;

    final requestId = notification["requestId"];

    try {
      final success =
          await ConnectionService.rejectConnectionRequest(requestId);

      if (success) {
        setState(() {
          notifications[section]?.removeAt(index);
          if (notifications[section]?.isEmpty ?? false) {
            notifications.remove(section);
          }
        });

        _showOverlayMessage("Connection request rejected");
      } else {
        _showOverlayMessage("Failed to reject request");
      }
    } catch (e) {
      print('Error rejecting connection request: $e');
      _showOverlayMessage("Error rejecting request");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 32,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF123b53),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF123b53),
              ),
            )
          : notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: notifications.entries.map((entry) {
                    String section = entry.key;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            section,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...entry.value.asMap().entries.map((notifEntry) {
                          int index = notifEntry.key;
                          Map<String, dynamic> notif = notifEntry.value;

                          if (notif["type"] == "connection_request") {
                            bool isAccepted = notif["accepted"] ?? false;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: const Color(0xFF123b53),
                                      backgroundImage: (notif["profileImage"] !=
                                                  null &&
                                              (notif["profileImage"] as String)
                                                  .isNotEmpty)
                                          ? NetworkImage(notif["profileImage"])
                                          : null,
                                      child: (notif["profileImage"] == null ||
                                              (notif["profileImage"] as String)
                                                  .isEmpty)
                                          ? Icon(notif["icon"],
                                              color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${notif["user"]} ${notif["action"]}",
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          if (notif["message"] != null &&
                                              notif["message"].isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 4),
                                              child: Text(
                                                notif["message"],
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          Text(
                                            notif["time"],
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                          ),
                                          const SizedBox(height: 8),
                                          isAccepted
                                              ? Row(
                                                  children: const [
                                                    Icon(Icons.check_circle,
                                                        color: Colors.green),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      "Accepted",
                                                      style: TextStyle(
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Row(
                                                  children: [
                                                    ElevatedButton.icon(
                                                      onPressed: () {
                                                        _acceptConnectionRequest(
                                                            section, index);
                                                      },
                                                      icon: const Icon(
                                                          Icons.check),
                                                      label:
                                                          const Text("Accept"),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    OutlinedButton.icon(
                                                      onPressed: () {
                                                        _rejectConnectionRequest(
                                                            section, index);
                                                      },
                                                      icon: const Icon(
                                                          Icons.close),
                                                      label:
                                                          const Text("Decline"),
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        foregroundColor:
                                                            Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFF123b53),
                                    child: Icon(notif["icon"],
                                        color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: notif["user"],
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              TextSpan(
                                                text: ' ${notif["action"]}',
                                                style: const TextStyle(
                                                    color: Colors.black),
                                              ),
                                            ],
                                          ),
                                          softWrap: true,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notif["time"] ?? '',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (notif["showThumbnail"] == true)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.image,
                                            color: Colors.black54),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}
