import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  String selectedRole = 'user';
  
  // Common fields
  final firstNameController = TextEditingController();
  final surnameController = TextEditingController();
  final ngoNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  
  // Address fields
  final homeController = TextEditingController();
  final landmarkController = TextEditingController();
  final areaController = TextEditingController();
  final pincodeController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();
  
  // NGO specific fields
  final govNumberController = TextEditingController();
  final ngoTypeController = TextEditingController();

  final auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> signupUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;
      final userData = {
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'role': selectedRole,
        'address': {
          'home': homeController.text.trim(),
          'landmark': landmarkController.text.trim(),
          'area': areaController.text.trim(),
          'pincode': pincodeController.text.trim(),
          'city': cityController.text.trim(),
          'state': stateController.text.trim(),
          'country': countryController.text.trim(),
        },
      };

      if (selectedRole == 'ngo') {
        userData['ngoName'] = ngoNameController.text.trim();
        userData['govNumber'] = govNumberController.text.trim();
        userData['ngoType'] = ngoTypeController.text.trim();
      } else {
        userData['firstName'] = firstNameController.text.trim();
        userData['surname'] = surnameController.text.trim();
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup successful')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $e')),
      );
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
      appBar: AppBar(
        title: const Text('Signup'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'ngo', child: Text('NGO')),
                ],
                onChanged: (value) => setState(() => selectedRole = value.toString()),
                decoration: const InputDecoration(labelText: 'Select Role'),
                validator: (value) => value == null ? 'Please select a role' : null,
              ),
              const SizedBox(height: 20),
              if (selectedRole == 'ngo')
                TextFormField(
                  controller: ngoNameController,
                  decoration: const InputDecoration(labelText: 'NGO Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter NGO name' : null,
                )
              else ...[
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter your first name' : null,
                ),
                TextFormField(
                  controller: surnameController,
                  decoration: const InputDecoration(labelText: 'Surname'),
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter your surname' : null,
                ),
              ],
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter your email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter your phone number';
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value!)) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter a password';
                  if (value!.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Address Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: homeController,
                decoration: const InputDecoration(labelText: 'Home/Apartment'),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your address' : null,
              ),
              TextFormField(
                controller: landmarkController,
                decoration: const InputDecoration(labelText: 'Landmark'),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a landmark' : null,
              ),
              TextFormField(
                controller: areaController,
                decoration: const InputDecoration(labelText: 'Area'),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your area' : null,
              ),
              TextFormField(
                controller: pincodeController,
                decoration: const InputDecoration(labelText: 'Pincode'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter pincode';
                  if (!RegExp(r'^\d{6}$').hasMatch(value!)) return 'Please enter a valid 6-digit pincode';
                  return null;
                },
              ),
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your city' : null,
              ),
              TextFormField(
                controller: stateController,
                decoration: const InputDecoration(labelText: 'State'),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your state' : null,
              ),
              TextFormField(
                controller: countryController,
                decoration: const InputDecoration(labelText: 'Country'),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your country' : null,
              ),
              if (selectedRole == 'ngo') ...[
                const SizedBox(height: 20),
                const Text('NGO Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: govNumberController,
                  decoration: const InputDecoration(labelText: 'Government Registration Number (Optional)'),
                ),
                TextFormField(
                  controller: ngoTypeController,
                  decoration: const InputDecoration(labelText: 'Type of NGO (Optional)'),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : signupUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Sign Up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}