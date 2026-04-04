import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/restaurant_service.dart';
import '../../utils/app_colors.dart';

class RestaurantOnboardingScreen extends StatefulWidget {
  const RestaurantOnboardingScreen({super.key});

  @override
  State<RestaurantOnboardingScreen> createState() =>
      _RestaurantOnboardingScreenState();
}

class _RestaurantOnboardingScreenState
    extends State<RestaurantOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 1: Basic Info
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Step 2: Location & Delivery
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _deliveryTimeController =
      TextEditingController(text: '30');
  final TextEditingController _deliveryChargeController =
      TextEditingController(text: '0');
  final TextEditingController _minOrderController =
      TextEditingController(text: '0');

  // Step 3: Cuisines & Hours
  final List<String> availableCuisines = [
    'Italian',
    'Chinese',
    'Indian',
    'Mexican',
    'American',
    'Fast Food',
    'Bakery',
    'Cafe',
  ];
  List<String> selectedCuisines = [];
  Map<String, dynamic> operatingHours = {
    'monday': {'open': '09:00', 'close': '21:00'},
    'tuesday': {'open': '09:00', 'close': '21:00'},
    'wednesday': {'open': '09:00', 'close': '21:00'},
    'thursday': {'open': '09:00', 'close': '21:00'},
    'friday': {'open': '09:00', 'close': '21:00'},
    'saturday': {'open': '10:00', 'close': '22:00'},
    'sunday': {'open': '10:00', 'close': '22:00'},
  };

  // Step 4: Time Slot Settings
  int timeSlotCapacity = 20;
  int timeSlotDuration = 15;

  // Step 5: Bank Details
  final TextEditingController _accountHolderController =
      TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _deliveryTimeController.dispose();
    _deliveryChargeController.dispose();
    _minOrderController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  void _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final restaurantData = {
      'restaurantName': _nameController.text,
      'description': _descriptionController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
      'city': _cityController.text,
      'zipCode': _zipController.text,
      'cuisineTypes': selectedCuisines,
      'deliveryTime': int.parse(_deliveryTimeController.text),
      'deliveryCharge': double.parse(_deliveryChargeController.text),
      'minOrderValue': double.parse(_minOrderController.text),
      'operatingHours': operatingHours,
      'defaultTimeSlotCapacity': timeSlotCapacity,
      'timeSlotDuration': timeSlotDuration,
      'bankDetails': {
        'accountHolder': _accountHolderController.text,
        'accountNumber': _accountNumberController.text,
        'ifscCode': _ifscController.text,
        'bankName': _bankNameController.text,
      },
      'isVerified': true, // Show in customer list
      'isOpen': true, // Make shop open by default
    };

    final success = await Provider.of<RestaurantService>(context, listen: false)
        .registerRestaurant(restaurantData);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant registered successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to register restaurant')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Restaurant'),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 4) {
            setState(() {
              _currentStep++;
            });
          } else {
            _submitRegistration();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep--;
            });
          }
        },
        steps: [
          // Step 1
          Step(
            title: const Text('Basic Info'),
            content: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    label: const Text('Restaurant Name'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    label: const Text('Description'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    label: const Text('Phone Number'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 0,
          ),
          // Step 2
          Step(
            title: const Text('Location & Delivery'),
            content: Column(
              children: [
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    label: const Text('Address'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          label: const Text('City'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _zipController,
                        decoration: InputDecoration(
                          label: const Text('ZIP Code'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _deliveryTimeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    label: const Text('Delivery Time (mins)'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _deliveryChargeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          label: const Text('Delivery Charge (₹)'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _minOrderController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          label: const Text('Min Order (₹)'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            isActive: _currentStep >= 1,
          ),
          // Step 3
          Step(
            title: const Text('Cuisines'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableCuisines.map((cuisine) {
                    return FilterChip(
                      label: Text(cuisine),
                      selected: selectedCuisines.contains(cuisine),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedCuisines.add(cuisine);
                          } else {
                            selectedCuisines.remove(cuisine);
                          }
                        });
                      },
                      selectedColor: AppColors.primaryOrange,
                    );
                  }).toList(),
                ),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
          // Step 4
          Step(
            title: const Text('Time Slot Settings'),
            content: Column(
              children: [
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    label: const Text('Orders per 15-min slot'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    timeSlotCapacity = int.tryParse(value) ?? 20;
                  },
                  controller:
                      TextEditingController(text: timeSlotCapacity.toString()),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Example: If you set 20, you can process max 20 orders per 15-minute slot',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            isActive: _currentStep >= 3,
          ),
          // Step 5
          Step(
            title: const Text('Bank Details'),
            content: Column(
              children: [
                TextField(
                  controller: _accountHolderController,
                  decoration: InputDecoration(
                    label: const Text('Account Holder Name'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    label: const Text('Account Number'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ifscController,
                        decoration: InputDecoration(
                          label: const Text('IFSC Code'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _bankNameController,
                        decoration: InputDecoration(
                          label: const Text('Bank Name'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            isActive: _currentStep >= 4,
          ),
        ],
      ),
    );
  }
}
