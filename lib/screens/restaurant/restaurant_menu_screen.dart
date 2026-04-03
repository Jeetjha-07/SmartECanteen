import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/menu_service.dart';
import '../../models/food_item.dart';
import '../../utils/app_colors.dart';

class RestaurantMenuScreen extends StatefulWidget {
  const RestaurantMenuScreen({super.key});

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  String _selectedCategory = 'All';
  late Future<List<FoodItem>> _menuFuture;

  @override
  void initState() {
    super.initState();
    // Restaurant should see ALL items (available + unavailable)
    _menuFuture = MenuService.getAllMenuItems();
  }

  // Refresh menu items from backend
  void _refreshMenu() {
    setState(() {
      // Fetch ALL items including unavailable
      _menuFuture = MenuService.getAllMenuItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FoodItem>>(
      future: _menuFuture,
      builder: (context, snapshot) {
        final allItems = snapshot.data ?? [];

        final categories = ['All'];
        for (final item in allItems) {
          if (!categories.contains(item.category)) {
            categories.add(item.category);
          }
        }

        final filtered = _selectedCategory == 'All'
            ? allItems
            : allItems.where((i) => i.category == _selectedCategory).toList();

        return Column(
          children: [
            // Header with seed button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text('${allItems.length} items',
                      style: const TextStyle(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showAddEditDialog(context, null),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                    tooltip: 'Add new item',
                  ),
                ],
              ),
            ),
            // Category filter
            if (allItems.isNotEmpty)
              Container(
                height: 46,
                color: Colors.white,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textDark,
                                fontSize: 12)),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                        backgroundColor: Colors.grey[100],
                        selectedColor: AppColors.primaryOrange,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  },
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(child: Text('No items in this category'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _MenuItemCard(
                            item: filtered[index],
                            onEdit: () =>
                                _showAddEditDialog(context, filtered[index]),
                            onDelete: () =>
                                _deleteItem(context, filtered[index]),
                            onToggle: (val) async {
                              await MenuService.toggleAvailability(
                                  filtered[index].id, val);
                              // Refresh menu after toggle
                              _refreshMenu();
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(BuildContext context, FoodItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete "${item.name}" from menu?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await MenuService.deleteMenuItem(item.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? '${item.name} deleted' : 'Failed to delete'),
                backgroundColor: ok ? AppColors.errorRed : AppColors.errorRed,
              ));
              // Refresh menu after delete
              if (ok) {
                _refreshMenu();
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, FoodItem? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final priceCtrl = TextEditingController(
        text: existing != null ? existing.price.toStringAsFixed(0) : '');
    final imageCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    final catCtrl = TextEditingController(text: existing?.category ?? '');
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Menu Item' : 'Edit Item'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildField(nameCtrl, 'Item Name', Icons.fastfood),
                  const SizedBox(height: 12),
                  _buildField(descCtrl, 'Description', Icons.description,
                      maxLines: 2),
                  const SizedBox(height: 12),
                  _buildField(priceCtrl, 'Price (₹)', Icons.currency_rupee,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _buildField(catCtrl, 'Category', Icons.category),
                  const SizedBox(height: 12),
                  _buildField(imageCtrl, 'Image URL', Icons.image_outlined,
                      required: false,
                      onChanged: () => setDialogState(() {})),
                  const SizedBox(height: 12),
                  // Image Preview
                  if (imageCtrl.text.trim().isNotEmpty)
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.textGrey, width: 1),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[50],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: imageCtrl.text.trim(),
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.red[50],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.broken_image, color: AppColors.errorRed),
                                  SizedBox(height: 8),
                                  Text('Invalid Image URL',
                                      style: TextStyle(
                                          color: AppColors.errorRed,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isLoading = true);

                      final item = FoodItem(
                        id: existing?.id ?? '',
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        price: double.tryParse(priceCtrl.text) ?? 0,
                        imageUrl: imageCtrl.text.trim(),
                        category: catCtrl.text.trim(),
                      );

                      bool ok;
                      if (existing == null) {
                        final result = await MenuService.addMenuItem(item);
                        ok = result['success'] ?? false;
                      } else {
                        ok = await MenuService.updateMenuItem(item);
                      }

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok
                            ? existing == null
                                ? 'Item added!'
                                : 'Item updated!'
                            : 'Operation failed'),
                        backgroundColor:
                            ok ? AppColors.successGreen : AppColors.errorRed,
                      ));
                      // Refresh menu after add/edit
                      if (ok) {
                        _refreshMenu();
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {int maxLines = 1,
      TextInputType keyboardType = TextInputType.text,
      bool required = true,
      VoidCallback? onChanged}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) => onChanged?.call(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: required
          ? (v) {
              if (v == null || v.isEmpty) return '$label is required';
              return null;
            }
          : null,
    );
  }
}

class _MenuItemCard extends StatefulWidget {
  final FoodItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _MenuItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard> {
  late bool _isAvailable;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.item.isAvailable;
  }

  @override
  void didUpdateWidget(_MenuItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update availability if parent data changed
    if (oldWidget.item.isAvailable != widget.item.isAvailable) {
      _isAvailable = widget.item.isAvailable;
    }
  }

  Future<void> _toggleAvailability(bool newValue) async {
    setState(() => _isToggling = true);
    
    // Update UI immediately for better UX
    setState(() => _isAvailable = newValue);
    
    // Call the parent callback
    widget.onToggle(newValue);
    
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: widget.item.imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
                  ),
                ),
                if (!_isAvailable)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        color: Colors.black45,
                        child: const Center(
                          child: Text('OFF',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(widget.item.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(widget.item.category,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textGrey)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(widget.item.description,
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '₹${widget.item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                AnimatedBuilder(
                  animation: AlwaysStoppedAnimation(_isAvailable ? 1.0 : 0.0),
                  builder: (context, child) => Switch(
                    value: _isAvailable,
                    onChanged: _isToggling ? null : _toggleAvailability,
                    activeThumbColor: AppColors.successGreen,
                    inactiveThumbColor: Colors.grey[400],
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: widget.onEdit,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.primaryOrange),
                      ),
                    ),
                    InkWell(
                      onTap: widget.onDelete,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline,
                            size: 18, color: AppColors.errorRed),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
