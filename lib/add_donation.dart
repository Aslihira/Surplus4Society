import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationForm extends StatefulWidget {
  const DonationForm({super.key});

  @override
  _DonationFormState createState() => _DonationFormState();
}

class _DonationFormState extends State<DonationForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController specialInstructionsController =
      TextEditingController();
  final TextEditingController pickupAddressController = TextEditingController();

  String selectedCategory = 'New';
  String selectedType = 'Books';
  int quantity = 1;
  String deliveryMethod = 'NGO Pickup';
  bool isUrgent = false;
  Map<String, dynamic>? _userData;
  DateTime pickupDate = DateTime.now();
  String pickupTimeSlot = 'Morning (9AM-12PM)';

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
            _userData = doc.data();
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw 'User not logged in';
        }

        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (!userDoc.exists) {
          throw 'User data not found';
        }

        final userData = userDoc.data()!;

        const defaultLat = 19.0760;
        const defaultLng = 72.8777;

        await FirebaseFirestore.instance.collection("donations").add({
          "donationType": selectedType,
          "condition": selectedCategory,
          "deliveryMethod": deliveryMethod,
          "quantity": quantity,
          "specialInstructions": specialInstructionsController.text,
          "status": "Pending",
          "isUrgent": isUrgent,
          "pickupAddress":
              (deliveryMethod == "NGO Pickup")
                  ? pickupAddressController.text
                  : "",
          "pickupDate": pickupDate,
          "pickupTimeSlot": pickupTimeSlot,
          "createdAt": FieldValue.serverTimestamp(),
          "donorId": user.uid,
          "donorName":
              "${userData['firstName'] ?? ''} ${userData['surname'] ?? ''}",
          "donorPhone": userData['phone'] ?? '',
          "latitude": userData['latitude'] ?? defaultLat,
          "longitude": userData['longitude'] ?? defaultLng,
          "geoPoint": GeoPoint(
            userData['latitude'] ?? defaultLat,
            userData['longitude'] ?? defaultLng,
          ),
        });

        _showSuccessDialog();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error submitting donation: $error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Icon(Icons.check_circle, color: Colors.green, size: 80),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Donation Submitted!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Thank you for your generous donation. We'll process it soon.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Make a Donation",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4A3AEF),
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildCategoryButton('New', selectedCategory == 'New'),
                        const SizedBox(width: 10),
                        _buildCategoryButton(
                          'Used',
                          selectedCategory == 'Used',
                        ),
                        const SizedBox(width: 10),
                        _buildCategoryButton(
                          'Needs\nRepair',
                          selectedCategory == 'Needs\nRepair',
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    const Text(
                      'Select Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTypeButton(
                          'Books',
                          Icons.book,
                          selectedType == 'Books',
                        ),
                        _buildTypeButton(
                          'Clothes',
                          Icons.checkroom,
                          selectedType == 'Clothes',
                        ),
                        _buildTypeButton(
                          'Other',
                          Icons.category,
                          selectedType == 'Other',
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildQuantityButton(
                          icon: Icons.remove,
                          onTap: () {
                            if (quantity > 1) {
                              setState(() {
                                quantity--;
                              });
                            }
                          },
                        ),
                        Container(
                          width: 50,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            '$quantity',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        _buildQuantityButton(
                          icon: Icons.add,
                          onTap: () {
                            setState(() {
                              quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    const Text(
                      'Delivery Method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDeliveryButton(
                            'NGO Pickup',
                            Icons.local_shipping,
                            deliveryMethod == 'NGO Pickup',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDeliveryButton(
                            'Drop-off',
                            Icons.location_on,
                            deliveryMethod == 'Drop-off',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    if (deliveryMethod == 'NGO Pickup') ...[
                      const Text(
                        'Pickup Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: pickupAddressController,
                        decoration: InputDecoration(
                          hintText: 'Enter pickup address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter pickup address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),
                    ],

                    const Text(
                      'Special Instructions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: specialInstructionsController,
                      decoration: InputDecoration(
                        hintText: 'Any special instructions...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 25),

                    SwitchListTile(
                      title: Text(
                        "Urgent Donation",
                        style: TextStyle(
                          color: isUrgent ? Colors.red : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      activeColor: Colors.red,
                      value: isUrgent,
                      onChanged: (value) => setState(() => isUrgent = value),
                    ),
                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A3AEF),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Submit Donation",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String title, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4A3AEF) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? const Color(0xFF4A3AEF) : Colors.grey[300]!,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = title;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? const Color(0xFF4A3AEF) : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              color: isSelected ? const Color(0xFF4A3AEF) : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF4A3AEF) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
        child: Icon(icon),
      ),
    );
  }

  Widget _buildDeliveryButton(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          deliveryMethod = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBEAFF) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A3AEF) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF4A3AEF)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    specialInstructionsController.dispose();
    pickupAddressController.dispose();
    super.dispose();
  }
}