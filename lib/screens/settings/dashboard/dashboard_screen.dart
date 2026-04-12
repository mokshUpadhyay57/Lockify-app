import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lockify/components/widgets/subscription_card.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int mainTabIndex = 1;
  String selectedDuration = "Last 28 Days";
  DateTime today = DateTime.now();

  // Optional: You could use this to update data in future
  DateTime startDate = DateTime.now().subtract(const Duration(days: 28));

  List<String> durations = [
    "Last 7 Days",
    "Last 15 Days",
    "Last 28 Days",
    "Last 1 Month",
    "Last 3 Months",
  ];

  String getDateRange() {
    DateTime calculatedStart;
    if (selectedDuration == "Last 7 Days") {
      calculatedStart = today.subtract(const Duration(days: 7));
    } else if (selectedDuration == "Last 15 Days") {
      calculatedStart = today.subtract(const Duration(days: 15));
    } else if (selectedDuration == "Last 1 Month") {
      calculatedStart = DateTime(today.year, today.month - 1, today.day);
    } else if (selectedDuration == "Last 3 Months") {
      calculatedStart = DateTime(today.year, today.month - 3, today.day);
    } else {
      calculatedStart = today.subtract(const Duration(days: 28));
    }

    startDate = calculatedStart;

    return "${DateFormat("MMM d, yyyy").format(calculatedStart)} - ${DateFormat("MMM d, yyyy").format(today)}";
  }

  @override
  Widget build(BuildContext context) {
    List<String> mainTabs = [
      "Earnings",
      "Subscriptions",
      "Subscription Endings",
    ];

    return LockifyScaffold(
      title: "Dashboard",
      body: Column(
        children: [
          // Tab Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(mainTabs.length, (index) {
                bool isSelected = index == mainTabIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      mainTabIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurple.shade400 : Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      mainTabs[index],
                      style: TextStyle(
                        color: isSelected ? AppColors.white : Colors.deepPurple.shade900,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Tab Content
          Expanded(child: getTabContent()),
        ],
      ),
    );
  }

  Widget getTabContent() {
    switch (mainTabIndex) {
      case 0:
        return earningsTab();
      case 1:
        return subscriptionsTab();
      case 2:
        return subscriptionEndingTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget earningsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range and dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Date Range
                InkWell(
                  onTap: () => _showDatePicker(context),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        getDateRange(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Duration Dropdown
                DropdownButton<String>(
                  value: selectedDuration,
                  items: durations
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedDuration = val!;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Earnings Cards
          const SubscriptionCard(
            title: "Total Earnings",
            subtitle: "Earnings from all subscriptions",
            value: "₹0",
            valueColor: AppColors.onlineGreen,
          ),
          const SubscriptionCard(
            title: "Subscription Earnings",
            subtitle: "Earnings from all subscriptions",
            value: "₹0",
            valueColor: AppColors.onlineGreen,
          ),
          const SubscriptionCard(
            title: "Earnings This Month",
            subtitle: "Earnings for the selected month",
            value: "\$0",
            valueColor: Colors.blue,
          ),
          const SubscriptionCard(
            title: "Locked Messages Earnings",
            subtitle: "Earnings from all locked messages",
            value: "₹0",
            valueColor: AppColors.onlineGreen,
          ),
          const SubscriptionCard(
            title: "SuperThanks Earnings",
            subtitle: "Earnings from all superthanks",
            value: "₹0",
            valueColor: AppColors.onlineGreen,
          ),
         
        ],
      ),
    );
  }

  Widget subscriptionEndingTab() {
    return const Center(child: Text("Subscription Ending content will go here."));
  }

  Widget subscriptionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range and dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Date Range
                InkWell(
                  onTap: () => _showDatePicker(context),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        getDateRange(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Duration Dropdown
                DropdownButton<String>(
                  value: selectedDuration,
                  items: durations
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedDuration = val!;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const SubscriptionCard(
            title: "No of Subscriptions Sold",
            subtitle: "0 of 0 (0%)\nPrevious data not available",
            value: "0",
            valueColor: AppColors.errorRed,
          ),
          const SubscriptionCard(
            title: "Subscriptions Renewed",
            subtitle: "0 of 0 (0%)\nPrevious data not available",
            value: "0",
            valueColor: AppColors.errorRed,
          ),
          const SubscriptionCard(
            title: "Subscriptions Not Renewed",
            subtitle: "0 of 0 (0%)\nPrevious data not available",
            value: "0",
            valueColor: AppColors.errorRed,
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 1),
      lastDate: today,
      initialDateRange: DateTimeRange(start: startDate, end: today),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        today = picked.end;
        selectedDuration = "Custom";
      });
    }
  }
}

