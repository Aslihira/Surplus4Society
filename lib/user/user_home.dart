import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_donation.dart';
import 'volunteer.dart';
import 'user_profile.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    DonationForm(),
    const VolunteerPage(),
    UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF4A3AEF),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard),
              label: 'Donate',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Volunteer',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String? userName;
  bool isLoading = true;
  int points = 0;
  int level = 1;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (doc.exists) {
          setState(() {
            userName = doc.data()?['firstName'] ?? 'User';
            points = doc.data()?['points'] ?? 0;
            level = doc.data()?['level'] ?? 1;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        userName = 'User';
        points = 0;
        level = 1;
        isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    // Header with greeting and profile icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $userName!',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Your actions create change!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none, color: Colors.black),
                              onPressed: () {
                                // Show notifications
                              },
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => UserProfilePage()),
                                );
                              },
                              child: const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.black,
                                child: Icon(Icons.person, color: Colors.white, size: 24),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    // Points and level card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.black, Color(0xFF333333)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Impact',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$points Points',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Earned',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Level $level',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Achieved',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (points % 100) / 100,
                              minHeight: 10,
                              backgroundColor: Colors.white24,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${100 - (points % 100)} points to next level',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Quick Actions (Vertical Layout)
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildVerticalActionButton(
                      title: 'Donate Now',
                      subtitle: 'Support causes you care about',
                      icon: Icons.favorite,
                      color: Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DonationForm()),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildVerticalActionButton(
                      title: 'Volunteer Now',
                      subtitle: 'Give your time to help others',
                      icon: Icons.people,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VolunteerPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildVerticalActionButton(
                      title: 'Your Donations',
                      subtitle: 'View your donation history',
                      icon: Icons.history,
                      color: Colors.green,
                      onTap: () {
                        // Navigate to donations history
                        // This would be implemented in a future update
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Donation history coming soon!')),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVerticalActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
