import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/time_slot_service.dart';
import '../../models/restaurant.dart';
import '../../models/time_slot.dart';
import '../../utils/app_colors.dart';

class TimeSlotSelectionScreen extends StatefulWidget {
  final Restaurant restaurant;

  const TimeSlotSelectionScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<TimeSlotSelectionScreen> createState() =>
      _TimeSlotSelectionScreenState();
}

class _TimeSlotSelectionScreenState extends State<TimeSlotSelectionScreen> {
  DateTime selectedDate = DateTime.now();
  TimeSlot? selectedSlot;

  @override
  void initState() {
    super.initState();
    _fetchTimeSlots();
  }

  void _fetchTimeSlots() {
    Provider.of<TimeSlotService>(context, listen: false)
        .getAvailableSlots(widget.restaurant.restaurantId, selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Delivery Time'),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Selection
              const Text(
                'Select Date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final date = DateTime.now().add(Duration(days: index));
                    final isSelected = selectedDate.year == date.year &&
                        selectedDate.month == date.month &&
                        selectedDate.day == date.day;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDate = date;
                          });
                          _fetchTimeSlots();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryOrange
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getDayName(date.weekday),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                '${date.day}/${date.month}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Time Slots
              const Text(
                'Select Time Slot',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Consumer<TimeSlotService>(
                builder: (context, timeSlotService, _) {
                  if (timeSlotService.isLoading) {
                    return const CircularProgressIndicator();
                  }

                  if (timeSlotService.error != null) {
                    return Center(
                      child: Text('Error: ${timeSlotService.error}'),
                    );
                  }

                  final slots = timeSlotService.timeSlots;

                  if (slots.isEmpty) {
                    return const Center(
                      child: Text('No time slots available for this date'),
                    );
                  }

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slot = slots[index];
                      final isSelected = selectedSlot?.id == slot.id;

                      return GestureDetector(
                        onTap: slot.isFull
                            ? null
                            : () {
                                setState(() {
                                  selectedSlot = slot;
                                });
                              },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryOrange
                                : (slot.isFull
                                    ? Colors.grey[300]
                                    : Colors.grey[100]),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryOrange
                                  : Colors.grey[400]!,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                slot.displayTime,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                slot.isFull
                                    ? 'Full'
                                    : '${slot.capacity - slot.currentOrders} left',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedSlot != null
                      ? () {
                          Navigator.pop(context, {
                            'date': selectedDate,
                            'timeSlot': selectedSlot,
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
