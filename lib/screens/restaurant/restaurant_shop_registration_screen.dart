import 'package:flutter/material.dart';
import 'dart:io';
import '../../services/restaurant_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import 'restaurant_home.dart';

class RestaurantShopRegistrationScreen extends StatefulWidget {
  const RestaurantShopRegistrationScreen({super.key});

  @override
  State<RestaurantShopRegistrationScreen> createState() =>
      _RestaurantShopRegistrationScreenState();
}

class _RestaurantShopRegistrationScreenState
    extends State<RestaurantShopRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedImageUrl;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImageUrl == null || _selectedImageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select an image for your shop'),
        backgroundColor: AppColors.errorRed,
      ));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await RestaurantService.registerShop(
        shopName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _selectedImageUrl!,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🎉 Shop registered successfully!'),
          backgroundColor: AppColors.successGreen,
        ));

        // Refresh user profile from API to update restaurantId
        await AuthService.getCurrentUserFromApi();

        if (!mounted) return;

        // Navigate to restaurant home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RestaurantHome()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${result['error']}'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.errorRed,
      ));
    }
  }

  void _selectImageUrl() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Shop Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Paste image URL',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() => _selectedImageUrl = value);
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Or use sample images:',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=400',
                'https://images.unsplash.com/photo-1567521464027-f127ff144326?w=400',
                'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400',
                'https://images.unsplash.com/photo-1536049310127-d810dbf434e1?w=400',
              ]
                  .map((url) => GestureDetector(
                        onTap: () {
                          setState(() => _selectedImageUrl = url);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(url),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.restaurantPrimary,
        foregroundColor: Colors.white,
        title: const Text('Register Your Shop'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Illustration
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                size: 80,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome! Let\'s set up your shop.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your shop will be visible to customers once you complete this setup.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop Name
                  const Text(
                    'Shop Name',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Pizza Palace',
                      prefixIcon: const Icon(Icons.storefront),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Shop name is required';
                      }
                      if (value.length < 3) {
                        return 'Shop name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Describe your shop, cuisine type, specialties...',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Icon(Icons.description),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Description is required';
                      }
                      if (value.length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Shop Image
                  const Text(
                    'Shop Image',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectImageUrl,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primaryOrange,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        image: _selectedImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_selectedImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: AppColors.backgroundColor,
                      ),
                      child: _selectedImageUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: AppColors.primaryOrange,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tap to select image',
                                  style: TextStyle(
                                    color: AppColors.primaryOrange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  if (_selectedImageUrl != null) ...[
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() => _selectedImageUrl = null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                      ),
                      child: const Text('Change Image'),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Register Shop',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '✓ Your shop will be visible to customers immediately\n✓ You can add menu items after registration\n✓ Start receiving orders right away',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                      height: 1.6,
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
}
