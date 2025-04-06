import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login_page.dart';

class NGOProfilePage extends StatefulWidget {
  const NGOProfilePage({super.key});

  @override
  State<NGOProfilePage> createState() => _NGOProfilePageState();
}

class _NGOProfilePageState extends State<NGOProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        userData = doc.data();
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      userData!['ngoName'] ?? 'NGO Profile',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: _logout,
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Organization Details'),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          Icons.business,
                          'NGO Name',
                          userData!['ngoName'] ?? '',
                        ),
                        _buildInfoCard(
                          Icons.email,
                          'Email',
                          userData!['email'] ?? '',
                        ),
                        _buildInfoCard(
                          Icons.phone,
                          'Phone',
                          userData!['phone'] ?? '',
                        ),
                        _buildInfoCard(
                          Icons.numbers,
                          'Government Registration Number',
                          userData!['govNumber'] ?? '',
                        ),
                        _buildInfoCard(
                          Icons.category,
                          'NGO Type',
                          userData!['ngoType'] ?? '',
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Address Information'),
                        const SizedBox(height: 16),
                        _buildAddressCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    final address = userData!['address'] ?? {};
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAddressField(Icons.home, 'Home/Apartment', address['home'] ?? ''),
            _buildAddressField(Icons.place, 'Landmark', address['landmark'] ?? ''),
            _buildAddressField(Icons.location_city, 'Area', address['area'] ?? ''),
            _buildAddressField(Icons.pin, 'Pincode', address['pincode'] ?? ''),
            _buildAddressField(Icons.location_city, 'City', address['city'] ?? ''),
            _buildAddressField(Icons.map, 'State', address['state'] ?? ''),
            _buildAddressField(Icons.public, 'Country', address['country'] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressField(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 