import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/time_slot_service.dart';
import '../../utils/app_colors.dart';
import '../../models/time_slot.dart';

class RestaurantTimeSlotsScreen extends StatefulWidget {
  const RestaurantTimeSlotsScreen({super.key});

  @override
  State<RestaurantTimeSlotsScreen> createState() =>
      _RestaurantTimeSlotsScreenState();
}

class _RestaurantTimeSlotsScreenState extends State<RestaurantTimeSlotsScreen> {
  late DateTime _selectedDate;
  late TimeOfDay _startTime = const TimeOfDay(hour: 11, minute: 0);
  late TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 0);
  int _capacityPerSlot = 20;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    // Load time slots for today
    Future.microtask(() {
      context.read<TimeSlotService>().getMyTimeSlots(date: _selectedDate);
    });
  }

  Future<void> _refreshTimeSlots() async {
    context.read<TimeSlotService>().getMyTimeSlots(date: _selectedDate);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Time Slots'),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTimeSlots,
        color: AppColors.primaryOrange,
        child: Consumer<TimeSlotService>(
          builder: (context, timeSlotService, _) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
              children: [
                // Date & Time Configuration Section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set Operating Hours',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date Picker
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: AppColors.primaryOrange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textGrey)),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate:
                                          DateTime.now().subtract(Duration(days: 0)),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 30)),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _selectedDate = picked;
                                      });
                                      timeSlotService.getMyTimeSlots(
                                          date: _selectedDate);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.textGrey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Start Time Picker
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              color: AppColors.primaryOrange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Opening Time',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textGrey)),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: _startTime,
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _startTime = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.textGrey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _startTime.format(context),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // End Time Picker
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              color: AppColors.primaryOrange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Closing Time',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textGrey)),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: _endTime,
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _endTime = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.textGrey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _endTime.format(context),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Capacity Per Slot
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Capacity per 15-min Slot',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textGrey)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _capacityPerSlot.toDouble(),
                                  min: 1,
                                  max: 100,
                                  divisions: 99,
                                  activeColor: AppColors.primaryOrange,
                                  label: '$_capacityPerSlot orders',
                                  onChanged: (value) {
                                    setState(() {
                                      _capacityPerSlot = value.toInt();
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 60,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryOrange
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_capacityPerSlot',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryOrange,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Generate Slots Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _generateSlots(context, timeSlotService),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Generate Time Slots'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Time Slots Display Section
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today\'s Time Slots',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (timeSlotService.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (timeSlotService.timeSlots.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.schedule_outlined,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                const Text(
                                  'No time slots yet.\nGenerate slots to get started!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: timeSlotService.timeSlots
                              .map((slot) => _buildSlotCard(context, slot, timeSlotService))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            );
          },
        ),
        ),
    );
  }

  Widget _buildSlotCard(BuildContext context, TimeSlot slot,
      TimeSlotService timeSlotService) {
    final isSlotFull = slot.currentOrders >= slot.capacity;
    final availableSlots = slot.capacity - slot.currentOrders;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 20, color: AppColors.primaryOrange),
                      const SizedBox(width: 8),
                      Text(
                        '${slot.startTime} - ${slot.endTime}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Orders progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${slot.currentOrders}/${slot.capacity} booked',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          if (isSlotFull)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.errorRed.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FULL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.errorRed,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: slot.capacity > 0
                              ? slot.currentOrders / slot.capacity
                              : 0,
                          minHeight: 6,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isSlotFull
                                ? AppColors.errorRed
                                : AppColors.successGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Available Slots Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSlotFull
                    ? AppColors.errorRed.withOpacity(0.1)
                    : AppColors.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '$availableSlots',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isSlotFull
                          ? AppColors.errorRed
                          : AppColors.successGreen,
                    ),
                  ),
                  Text(
                    'Available',
                    style: TextStyle(
                      fontSize: 10,
                      color: isSlotFull
                          ? AppColors.errorRed
                          : AppColors.successGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Edit button
            PopupMenuButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Capacity'),
                    ],
                  ),
                  onTap: () => _showEditCapacityDialog(
                      context, slot, timeSlotService),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        slot.isAvailable ? Icons.close : Icons.check,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(slot.isAvailable ? 'Close Slot' : 'Open Slot'),
                    ],
                  ),
                  onTap: () async {
                    await timeSlotService.toggleSlotAvailability(
                        slot.id, !slot.isAvailable);
                    await timeSlotService.getMyTimeSlots(
                        date: _selectedDate);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCapacityDialog(
      BuildContext context, TimeSlot slot, TimeSlotService timeSlotService) {
    int newCapacity = slot.capacity;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Slot Capacity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Set maximum orders for this time slot',
                style: TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Slider(
                value: newCapacity.toDouble(),
                min: (slot.currentOrders + 1).toDouble(),
                max: 100,
                divisions: 99,
                activeColor: AppColors.primaryOrange,
                label: '$newCapacity',
                onChanged: (value) {
                  setDialogState(() {
                    newCapacity = value.toInt();
                  });
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Capacity:'),
                    Text(
                      '$newCapacity',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryOrange,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Current Orders: ${slot.currentOrders}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await timeSlotService.updateSlotCapacity(slot.id, newCapacity);
                await timeSlotService.getMyTimeSlots(date: _selectedDate);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Capacity updated!'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateSlots(BuildContext context,
      TimeSlotService timeSlotService) async {
    setState(() => _isLoading = true);

    try {
      // Convert TimeOfDay to HH:mm format
      final startTimeStr =
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
      final endTimeStr =
          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

      print('🕐 Generating slots from $startTimeStr to $endTimeStr with capacity $_capacityPerSlot');

      final success = await timeSlotService.generateSlots(
        _selectedDate,
        startTime: startTimeStr,
        endTime: endTimeStr,
        capacity: _capacityPerSlot,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        await timeSlotService.getMyTimeSlots(date: _selectedDate);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Time slots generated successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${timeSlotService.error}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}
