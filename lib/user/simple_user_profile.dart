import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login_page.dart';

class SimpleUserProfilePage extends StatefulWidget {
  const SimpleUserProfilePage({super.key});

  @override
  State<SimpleUserProfilePage> createState() => _SimpleUserProfilePageState();
}

class _SimpleUserProfilePageState extends State<SimpleUserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  bool isLoading = true;
  bool isEditing = false;
  String? errorMessage;
  
  // User data
  String userName = "User";
  String userEmail = "";
  String userPhone = "";
  String userAddress = "";
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          
          setState(() {
            userName = data['firstName'] ?? data['username'] ?? "User";
            userEmail = user.email ?? "";
            userPhone = data['phone'] ?? "";
            userAddress = data['address'] ?? "";
            
            // Set controller values
            _nameController.text = userName;
            _phoneController.text = userPhone;
            _addressController.text = userAddress;
            
            isLoading = false;
          });
        } else {
          // Create a new user document if it doesn't exist
          await _firestore.collection('users').doc(user.uid).set({
            'firstName': user.displayName ?? "User",
            'email': user.email,
            'phone': "",
            'address': "",
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          setState(() {
            userName = user.displayName ?? "User";
            userEmail = user.email ?? "";
            _nameController.text = userName;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "User not logged in";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error loading profile: $e";
      });
    }
  }
  
  Future<void> _saveProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'firstName': _nameController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        setState(() {
          userName = _nameController.text;
          userPhone = _phoneController.text;
          userAddress = _addressController.text;
          isEditing = false;
          isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error updating profile: $e";
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
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUserData,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Profile' : 'My Profile'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: isEditing ? _saveProfile : () => setState(() => isEditing = true),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Personal Information Section
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Name',
              value: userName,
              icon: Icons.person,
              controller: _nameController,
              isEditing: isEditing,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              title: 'Email',
              value: userEmail,
              icon: Icons.email,
              isEditing: false,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              title: 'Phone',
              value: userPhone.isEmpty ? 'Not provided' : userPhone,
              icon: Icons.phone,
              controller: _phoneController,
              isEditing: isEditing,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              title: 'Address',
              value: userAddress.isEmpty ? 'Not provided' : userAddress,
              icon: Icons.location_on,
              controller: _addressController,
              isEditing: isEditing,
            ),
            const SizedBox(height: 24),
            
            // Account Settings Section
            const Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsCard(
              title: 'Change Password',
              icon: Icons.lock_outline,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password change coming soon!')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsCard(
              title: 'Notification Preferences',
              icon: Icons.notifications_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification settings coming soon!')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsCard(
              title: 'Privacy Settings',
              icon: Icons.privacy_tip_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy settings coming soon!')),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    TextEditingController? controller,
    required bool isEditing,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: isEditing && controller != null
                  ? TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: title,
                        border: const OutlineInputBorder(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
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
  
  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 