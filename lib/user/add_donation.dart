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
  
  // Controllers
  final TextEditingController quantityController = TextEditingController(text: "1");
  final TextEditingController specialInstructionsController = TextEditingController();
  final TextEditingController pickupAddressController = TextEditingController();
  
  // Form data
  String donationType = "Books";
  String condition = "New";
  String deliveryMethod = "NGO Pickup";
  String pickupTimeSlot = "Morning (9AM - 12PM)";
  bool isUrgent = false;
  int quantity = 1;
  DateTime? pickupDate;
  
  // Stepper state
  int _currentStep = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _currentStep == 0 ? "Make a Donation" : "Donation Details",
          style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.bold),
        ),
        leading: _currentStep > 0 
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.indigo[700]),
              onPressed: () => setState(() => _currentStep--),
            )
          : null,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: _buildStepContent(),
        ),
      ),
      floatingActionButton: _currentStep < 2 ? FloatingActionButton(
        backgroundColor: Colors.indigo[600],
        mini: true,
        child: Icon(Icons.chat, color: Colors.white),
        onPressed: () {},
      ) : null,
    );
  }
  
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildCategorySelectionStep();
      case 1:
        return _buildPickupDetailsStep();
      case 2:
        return _buildDonationSummaryStep();
      default:
        return Container();
    }
  }
  
  Widget _buildCategorySelectionStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: 0.33,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
          ),
          SizedBox(height: 30),
          Text(
            "Select Category",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),
          
          // Condition selection
          Row(
            children: [
              _buildConditionOption("New", condition == "New"),
              SizedBox(width: 10),
              _buildConditionOption("Used", condition == "Used"),
              SizedBox(width: 10),
              _buildConditionOption("Needs\nRepair", condition == "Needs Repair"),
            ],
          ),
          
          SizedBox(height: 30),
          
          // Donation type selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDonationTypeOption(Icons.book, "Books"),
              _buildDonationTypeOption(Icons.checkroom, "Clothes"),
              _buildDonationTypeOption(Icons.category, "Other"),
            ],
          ),
          
          SizedBox(height: 30),
          
          // Quantity selector
          Text(
            "Quantity",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  if (quantity > 1) {
                    setState(() {
                      quantity--;
                      quantityController.text = quantity.toString();
                    });
                  }
                },
              ),
              SizedBox(
                width: 50,
                child: TextField(
                  controller: quantityController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      quantity = int.parse(value);
                    }
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    quantity++;
                    quantityController.text = quantity.toString();
                  });
                },
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Delivery method
          Text(
            "Delivery Method",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDeliveryMethodOption(
                  "NGO Pickup", 
                  Icons.local_shipping, 
                  deliveryMethod == "NGO Pickup"
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildDeliveryMethodOption(
                  "Drop-off", 
                  Icons.location_on, 
                  deliveryMethod == "Drop-off"
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Date picker
          Text(
            "Pickup Date & Time",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 10),
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      pickupDate != null 
                        ? "${pickupDate!.day.toString().padLeft(2, '0')}-${pickupDate!.month.toString().padLeft(2, '0')}-${pickupDate!.year}"
                        : "dd-mm-yyyy",
                      style: TextStyle(color: pickupDate != null ? Colors.black : Colors.grey),
                    ),
                  ),
                  Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          
          // Time slot dropdown
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: pickupTimeSlot,
                items: [
                  "Morning (9AM - 12PM)",
                  "Afternoon (1PM - 5PM)",
                  "Evening (6PM - 9PM)",
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    pickupTimeSlot = newValue!;
                  });
                },
              ),
            ),
          ),
          
          SizedBox(height: 30),
          
          // Next button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              setState(() {
                _currentStep = 1;
              });
            },
            child: Text("Continue", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPickupDetailsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: 0.66,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
          ),
          SizedBox(height: 20),
          
          if (deliveryMethod == "NGO Pickup") ...[
            Text(
              "Pickup Address",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10),
            TextField(
              controller: pickupAddressController,
              decoration: InputDecoration(
                hintText: "Enter your address",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 20),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              // This would be a map in a real app
            ),
            SizedBox(height: 30),
          ],
          
          // Upload photos
          Text(
            "Upload Photos",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              // Photo picker logic would go here
            },
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("Tap to upload photos", style: TextStyle(color: Colors.grey))
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DashedBorderPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Mark as urgent
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Mark as Urgent",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Switch(
                value: isUrgent,
                onChanged: (value) {
                  setState(() {
                    isUrgent = value;
                  });
                },
                activeColor: Colors.indigo,
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Special instructions
          Text(
            "Special Instructions",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 10),
          TextField(
            controller: specialInstructionsController,
            decoration: InputDecoration(
              hintText: "Add any special notes or requirements",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            ),
            maxLines: 3,
          ),
          
          SizedBox(height: 30),
          
          // Continue button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              setState(() {
                _currentStep = 2;
              });
            },
            child: Text("Continue", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDonationSummaryStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
          ),
          SizedBox(height: 20),
          
          // Upload photos
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Upload Photos",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    // Photo picker logic would go here
                  },
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, color: Colors.grey),
                              SizedBox(height: 8),
                              Text("Tap to upload photos", style: TextStyle(color: Colors.grey))
                            ],
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: DashedBorderPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 15),
                
                // Mark as urgent
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Mark as Urgent",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Switch(
                      value: isUrgent,
                      onChanged: (value) {
                        setState(() {
                          isUrgent = value;
                        });
                      },
                      activeColor: Colors.indigo,
                    ),
                  ],
                ),
                
                SizedBox(height: 15),
                
                // Special instructions
                Text(
                  "Special Instructions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: specialInstructionsController,
                  decoration: InputDecoration(
                    hintText: "Add any special notes or requirements",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 25),
          
          // Donation summary
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Donation Summary",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 15),
                _buildSummaryItem("Category", donationType),
                _buildSummaryItem("Quantity", "$quantity item${quantity > 1 ? 's' : ''}"),
                _buildSummaryItem(
                  "Pickup", 
                  "${pickupDate != null ? 'Mar ${pickupDate!.day}' : 'Date not set'}, $pickupTimeSlot"
                ),
                _buildSummaryItem("Reward Points", "+50 points", isReward: true),
              ],
            ),
          ),
          
          SizedBox(height: 30),
          
          // Confirm button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _submitDonation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Confirm Donation", style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Icon(Icons.check_circle, size: 20),
              ],
            ),
          ),
          
          // Add extra padding at the bottom to prevent overflow
          SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildConditionOption(String title, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            condition = title;
          });
        },
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.indigo[600] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.indigo[600]! : Colors.grey[300]!,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDonationTypeOption(IconData icon, String type) {
    final isSelected = donationType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          donationType = type;
        });
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.indigo[100] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(color: Colors.indigo) : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.indigo : Colors.grey[700],
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            type,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.indigo : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDeliveryMethodOption(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          deliveryMethod = title;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo[100] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.indigo : Colors.grey[600],
            ),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.indigo : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value, {bool isReward = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isReward ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: pickupDate ?? DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        pickupDate = picked;
      });
    }
  }
  
  void _submitDonation() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
            ),
          );
        },
      );
      
      // Add donation to Firestore
      await FirebaseFirestore.instance.collection("donations").add({
        "donationType": donationType,
        "condition": condition,
        "quantity": quantity,
        "deliveryMethod": deliveryMethod,
        "pickupDate": pickupDate,
        "pickupTimeSlot": pickupTimeSlot,
        "isUrgent": isUrgent,
        "specialInstructions": specialInstructionsController.text,
        "pickupAddress": deliveryMethod == "NGO Pickup" ? pickupAddressController.text : "",
        "status": "Pending",
        "createdAt": FieldValue.serverTimestamp(),
        "userId": FirebaseAuth.instance.currentUser?.uid,
        "rewardPoints": 50,
      });
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success dialog
      _showSuccessDialog();
    } catch (error) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error submitting donation: $error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 70,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  "Thank You!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Your donation has been submitted successfully. You'll receive confirmation shortly.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Reset form or navigate back to home
                    setState(() {
                      _currentStep = 0;
                    });
                  },
                  child: Text("Done"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double startX = 0;
    final path = Path();
    
    // Top border
    while (startX < size.width) {
      path.moveTo(startX, 0);
      path.lineTo(startX + dashWidth, 0);
      startX += dashWidth + dashSpace;
    }
    
    // Right border
    startX = size.width;
    double startY = 0;
    while (startY < size.height) {
      path.moveTo(startX, startY);
      path.lineTo(startX, startY + dashWidth);
      startY += dashWidth + dashSpace;
    }
    
    // Bottom border
    startX = size.width;
    while (startX > 0) {
      path.moveTo(startX, size.height);
      path.lineTo(startX - dashWidth, size.height);
      startX -= dashWidth + dashSpace;
    }
    
    // Left border
    startX = 0;
    startY = size.height;
    while (startY > 0) {
      path.moveTo(startX, startY);
      path.lineTo(startX, startY - dashWidth);
      startY -= dashWidth + dashSpace;
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}