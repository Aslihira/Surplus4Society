import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class VolunteerPage extends StatefulWidget {
  const VolunteerPage({super.key});

  @override
  State<VolunteerPage> createState() => _VolunteerPageState();
}

class _VolunteerPageState extends State<VolunteerPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Position? _currentPosition;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', '1km', '5km', '10km', '20km'];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          _userData = doc.data();
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error getting location: $e');
    }
  }

  Future<void> _launchMaps(double lat, double lng, String title) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not launch maps');
    }
  }

  Future<void> _launchDirections(double startLat, double startLng, double endLat, double endLng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$endLat,$endLng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not launch directions');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // in km
  }

  String _formatDistance(double kilometers) {
    if (kilometers < 1) {
      return '${(kilometers * 1000).toStringAsFixed(0)}m';
    } else {
      return '${kilometers.toStringAsFixed(1)}km';
    }
  }

  Future<void> _acceptVolunteerRequest(String requestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('donations').doc(requestId).update({
        'status': 'Accepted',
        'volunteerId': user.uid,
        'acceptedAt': Timestamp.now(),
      });

      _showError('Request accepted successfully');
    } catch (e) {
      _showError('Failed to accept request: $e');
    }
  }

  Future<void> _updateUserStatus(String newStatus) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _userData?['status'] = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentPosition == null) {
      return const Scaffold(
        body: Center(child: Text('Location not available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Opportunities'),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => _filters.map((filter) {
              return PopupMenuItem(
                value: filter,
                child: Text(filter),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_userData != null) _buildUserInfoCard(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('donations')
                  .where('status', isEqualTo: 'Pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final requests = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ngoLocation = data['location'] as Map<String, dynamic>?;

                  if (ngoLocation == null || ngoLocation['latitude'] == null || ngoLocation['longitude'] == null) {
                    return null;
                  }

                  final distance = _calculateDistance(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    ngoLocation['latitude'] as double,
                    ngoLocation['longitude'] as double,
                  );

                  if (_selectedFilter != 'All') {
                    final maxDistance = double.parse(_selectedFilter.replaceAll('km', ''));
                    if (distance > maxDistance) return null;
                  }

                  return {
                    'doc': doc,
                    'data': data,
                    'distance': distance,
                  };
                }).where((r) => r != null).toList();

                if (requests.isEmpty) {
                  return _buildNoRequestsInRange();
                }

                requests.sort((a, b) => (a!['distance'] as double).compareTo(b!['distance'] as double));

                return RefreshIndicator(
                  onRefresh: _getCurrentLocation,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) =>
                        _buildRequestCard(requests[index]!),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, size: 30, color: Colors.black),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_userData!['firstName']} ${_userData!['surname']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _userData!['email'],
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _userData?['status'] ?? 'Pending',
                      dropdownColor: Colors.blue,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'In Progress',
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: 'Completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'On Hold',
                          child: Text('On Hold'),
                        ),
                      ],
                      onChanged: (String? newStatus) {
                        if (newStatus != null) {
                          _updateUserStatus(newStatus);
                        }
                      },
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _launchMaps(_currentPosition!.latitude, _currentPosition!.longitude, 'Your Location'),
                  icon: const Icon(Icons.map),
                  label: const Text('View on Map'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final data = request['data'] as Map<String, dynamic>;
    final ngoLocation = data['location'] as Map<String, dynamic>;
    final distance = request['distance'] as double;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.directions, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(_formatDistance(distance), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ]),
                if (createdAt != null)
                  Text(DateFormat('MMM d, h:mm a').format(createdAt), style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['itemType'] ?? 'Unknown Item', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Quantity: ${data['quantity'] ?? 0}', style: const TextStyle(fontSize: 16)),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _buildLocationBox('Your Location', _currentPosition!.latitude, _currentPosition!.longitude, Colors.blue.shade50, Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildLocationBox('NGO Location', ngoLocation['latitude'], ngoLocation['longitude'], Colors.green.shade50, Colors.green)),
                ]),
                if (data['notes'] != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.notes, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(data['notes'], style: const TextStyle(fontSize: 14))),
                    ]),
                  ),
                ],
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _launchDirections(_currentPosition!.latitude, _currentPosition!.longitude, ngoLocation['latitude'], ngoLocation['longitude']),
                      icon: const Icon(Icons.directions),
                      label: const Text('Get Directions'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptVolunteerRequest(request['doc'].id),
                      icon: const Icon(Icons.volunteer_activism),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBox(String title, double lat, double lng, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: iconColor.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.location_on, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: iconColor, fontSize: 12)),
          ]),
          const SizedBox(height: 4),
          Text('${lat.toStringAsFixed(6)},\n${lng.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _launchMaps(lat, lng, title),
              style: ElevatedButton.styleFrom(backgroundColor: iconColor, padding: const EdgeInsets.symmetric(vertical: 8)),
              child: const Text('View Map'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
        Icon(Icons.volunteer_activism, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('No volunteer requests available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildNoRequestsInRange() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.location_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text('No requests within ${_selectedFilter == 'All' ? 'range' : _selectedFilter}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
