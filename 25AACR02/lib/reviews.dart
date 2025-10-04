import 'package:flutter/material.dart';

class Reviews extends StatelessWidget {
  const Reviews({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> givenReviews = [
      {
        "user": "Rahul",
        "date": "2 days ago",
        "title": "Great collaborator",
        "body": "Enjoyed working with Sara on the project!",
        "likes": "12",
        "dislikes": "0",
        "comments": "2",
        "shares": "0",
        "color": Color.fromARGB(255, 150, 198, 229),
        "rating": 4,
      },
      {
        "user": "Meera",
        "date": "5 days ago",
        "title": "Very skilled",
        "body": "Rahul really helped me debug my app efficiently.",
        "likes": "8",
        "dislikes": "1",
        "comments": "1",
        "shares": "0",
        "color": Color.fromARGB(255, 150, 198, 229),
        "rating": 5,
      },
    ];

    final List<Map<String, dynamic>> receivedReviews = [
      {
        "user": "Karan",
        "date": "1 day ago",
        "title": "Helpful and patient",
        "body": "Sara explained everything clearly, highly recommend!",
        "likes": "20",
        "dislikes": "0",
        "comments": "3",
        "shares": "1",
        "color": Color.fromARGB(255, 150, 198, 229),
        "rating": 5,
      },
      {
        "user": "Priya",
        "date": "1 week ago",
        "title": "Good communication",
        "body": "Was quick to respond and delivered on time.",
        "likes": "15",
        "dislikes": "2",
        "comments": "2",
        "shares": "0",
        "color": Color.fromARGB(255, 150, 198, 229),
        "rating": 4,
      },
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Reviews',
            style: TextStyle(
              fontSize: 30,
              //fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
          backgroundColor:Color(0xFF123b53),
          iconTheme: IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Given Reviews"),
              Tab(text: "Received Reviews"),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        body: TabBarView(
          children: [
            _buildReviewList(givenReviews),
            _buildReviewList(receivedReviews),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewList(List<Map<String, dynamic>> reviews) {
    return ListView.builder(
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final post = reviews[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              color: post['color'],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(184, 4, 2, 2),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + User + Stars + Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person,
                                size: 16, color: Colors.black),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            post['user'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Row(
                            children: List.generate(
                              post['rating'],
                              (index) => Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.yellow[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      post['date'],
                      style: const TextStyle(
                          color: Colors.black, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  post['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  post['body'],
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(221, 255, 255, 255)),
                ),
                const SizedBox(height: 12),
                // Bottom row: likes, dislikes, comments, shares
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _iconText(Icons.thumb_up_alt_outlined, post['likes']),
                    _iconText(Icons.thumb_down_alt_outlined, post['dislikes']),
                    _iconText(Icons.comment_outlined, post['comments']),
                    _iconText(Icons.share_outlined, post['shares']),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 18, color: Colors.black),
      const SizedBox(width: 6),
      Text(text),
    ]);
  }
}
