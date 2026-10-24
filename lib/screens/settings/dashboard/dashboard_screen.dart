import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';
import 'package:lockify/components/widgets/subscription_card.dart';
import 'package:lockify/utils/colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int mainTabIndex = 0;
  String selectedDuration = "Last 28 Days";
  DateTime today = DateTime.now();
  DateTime startDate = DateTime.now().subtract(const Duration(days: 28));
  late Future<_DashboardStats> _statsFuture;

  final List<String> durations = const [
    "Last 7 Days",
    "Last 15 Days",
    "Last 28 Days",
    "Last 1 Month",
    "Last 3 Months",
    "Custom",
  ];

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadDashboardStats();
  }

  DateTime get _rangeStart {
    final end = _dateOnly(today);
    switch (selectedDuration) {
      case "Last 7 Days":
        return end.subtract(const Duration(days: 6));
      case "Last 15 Days":
        return end.subtract(const Duration(days: 14));
      case "Last 1 Month":
        return DateTime(end.year, end.month - 1, end.day);
      case "Last 3 Months":
        return DateTime(end.year, end.month - 3, end.day);
      case "Custom":
        return _dateOnly(startDate);
      case "Last 28 Days":
      default:
        return end.subtract(const Duration(days: 27));
    }
  }

  DateTime get _rangeEnd => _dateOnly(today);

  DateTime get _rangeEndExclusive => _rangeEnd.add(const Duration(days: 1));

  String getDateRange() {
    return "${DateFormat("MMM d, yyyy").format(_rangeStart)} - ${DateFormat("MMM d, yyyy").format(_rangeEnd)}";
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = _loadDashboardStats();
    });
  }

  Future<_DashboardStats> _loadDashboardStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      return _DashboardStats.empty(
        buckets: _buildEmptyBuckets(_rangeStart, _rangeEnd),
        isLoggedOut: true,
      );
    }

    Map<String, dynamic> walletData = {};
    try {
      final walletSnapshot =
          await _firestore.collection('wallets').doc(user.uid).get();
      walletData = walletSnapshot.data() ?? {};
    } on FirebaseException {
      walletData = {};
    }

    final transactionsDocs = await _safeQueryDocs(
      _firestore
          .collection('wallet_transactions')
          .where('userId', isEqualTo: user.uid),
    );
    final orderItemDocs = await _safeQueryDocs(
      _firestore
          .collection('order-items')
          .where('creatorId', isEqualTo: user.uid),
    );
    final lockedMessageDocs = await _safeQueryDocs(
      _firestore
          .collection('lockedMessages')
          .where('createdBy', isEqualTo: user.uid),
    );
    final groupSubscriptionDocs = await _safeQueryDocs(
      _firestore
          .collection('groups')
          .where('participantUids', arrayContains: user.uid),
    );
    final channelSubscriptionDocs = await _safeQueryDocs(
      _firestore
          .collection('channels')
          .where('participantUids', arrayContains: user.uid),
    );

    final buckets = _buildEmptyBuckets(_rangeStart, _rangeEnd);
    final bucketByKey = {
      for (final bucket in buckets) _bucketKey(bucket.date): bucket,
    };
    final subscriptionBuckets = _buildEmptyBuckets(_rangeStart, _rangeEnd);
    final subscriptionBucketByKey = {
      for (final bucket in subscriptionBuckets) _bucketKey(bucket.date): bucket,
    };

    double rangeEarnings = 0;
    final fallbackEarningsByKey = <String, double>{};
    for (final doc in transactionsDocs) {
      final data = doc.data();
      if (!_isCreditTransaction(data)) continue;

      final createdAt = _readDate(data['createdAt']);
      if (createdAt == null || !_isInSelectedRange(createdAt)) continue;

      final amount = _readAmount(data['amount']);
      rangeEarnings += amount;
      bucketByKey[_bucketKey(createdAt)]?.earnings += amount;
    }

    int rangeSales = 0;
    double salesFallbackEarnings = 0;
    final Map<String, _MessagePerformance> performanceByMessage = {};

    for (final doc in orderItemDocs) {
      final data = doc.data();
      final purchasedAt = _readDate(data['purchasedAt']);
      if (purchasedAt == null || !_isInSelectedRange(purchasedAt)) continue;

      final amount = _readAmount(data['pricePaid']);
      final lockedMessageId = data['lockedMessageId']?.toString() ?? "";

      rangeSales += 1;
      salesFallbackEarnings += amount;
      bucketByKey[_bucketKey(purchasedAt)]?.sales += 1;
      fallbackEarningsByKey.update(
        _bucketKey(purchasedAt),
        (value) => value + amount,
        ifAbsent: () => amount,
      );

      if (lockedMessageId.isNotEmpty) {
        performanceByMessage
            .putIfAbsent(
              lockedMessageId,
              () => _MessagePerformance(
                id: lockedMessageId,
                title: "Locked message",
              ),
            )
            .addSale(amount);
      }
    }

    int activeLockedMessages = 0;
    for (final doc in lockedMessageDocs) {
      final data = doc.data();
      activeLockedMessages += 1;
      final title = data['teaserText']?.toString().trim();
      final purchasedCount = _readInt(data['purchasedCount']);
      final unlockPrice = _readAmount(data['unlockPrice']);

      performanceByMessage.update(
        doc.id,
        (item) {
          item.title = (title == null || title.isEmpty) ? item.title : title;
          item.totalSales = math.max(item.totalSales, purchasedCount);
          if (item.earnings == 0 && purchasedCount > 0 && unlockPrice > 0) {
            item.earnings = purchasedCount * unlockPrice;
          }
          return item;
        },
        ifAbsent:
            () => _MessagePerformance(
              id: doc.id,
              title: title == null || title.isEmpty ? "Locked message" : title,
              totalSales: purchasedCount,
              earnings: purchasedCount * unlockPrice,
            ),
      );
    }

    final topMessages =
        performanceByMessage.values
            .where((item) => item.totalSales > 0)
            .toList()
          ..sort((a, b) => b.totalSales.compareTo(a.totalSales));

    int subscriptionSales = 0;
    int activeSubscriptions = 0;
    double subscriptionEarnings = 0;
    final subscriptionDocs = [
      ...groupSubscriptionDocs,
      ...channelSubscriptionDocs,
    ];

    for (final doc in subscriptionDocs) {
      final data = doc.data();
      if (data['createdBy'] != user.uid || !_isPaidSubscription(data)) {
        continue;
      }

      final subscriberCount = _subscriberCount(data);
      final price = _readAmount(data['subscriptionPrice']);
      final earning = subscriberCount * price;

      subscriptionSales += subscriberCount;
      activeSubscriptions += subscriberCount;
      subscriptionEarnings += earning;

      final createdAt = _readDate(data['createdAt']);
      if (createdAt == null || !_isInSelectedRange(createdAt)) continue;

      final bucket = subscriptionBucketByKey[_bucketKey(createdAt)];
      bucket?.sales += subscriberCount;
      bucket?.earnings += earning;
    }

    final totalEarnings = _readAmount(walletData['totalEarned']);
    final availableBalance = _readAmount(walletData['availableBalance']);
    final pendingBalance = _readAmount(walletData['pendingBalance']);
    if (rangeEarnings == 0 && salesFallbackEarnings > 0) {
      for (final entry in fallbackEarningsByKey.entries) {
        bucketByKey[entry.key]?.earnings = entry.value;
      }
    }

    return _DashboardStats(
      buckets: buckets,
      totalEarnings: totalEarnings,
      availableBalance: availableBalance,
      pendingBalance: pendingBalance,
      rangeEarnings: rangeEarnings > 0 ? rangeEarnings : salesFallbackEarnings,
      rangeSales: rangeSales,
      activeLockedMessages: activeLockedMessages,
      topMessages: topMessages.take(5).toList(),
      subscriptionBuckets: subscriptionBuckets,
      expiredSubscriptionBuckets: _buildEmptyBuckets(_rangeStart, _rangeEnd),
      subscriptionSales: subscriptionSales,
      activeSubscriptions: activeSubscriptions,
      subscriptionEarnings: subscriptionEarnings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainTabs = ["Overview", "Earnings", "Subscription"];

    return LockifyScaffold(
      title: "Dashboard",
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(mainTabs.length, (index) {
                final isSelected = index == mainTabIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      mainTabIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.deepPurple.shade400
                              : Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      mainTabs[index],
                      style: TextStyle(
                        color:
                            isSelected
                                ? AppColors.white
                                : Colors.deepPurple.shade900,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: FutureBuilder<_DashboardStats>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildDashboardBody(
                    _DashboardStats.empty(
                      buckets: _buildEmptyBuckets(_rangeStart, _rangeEnd),
                      errorMessage: "Unable to load dashboard data right now.",
                    ),
                  );
                }

                return _buildDashboardBody(
                  snapshot.data ??
                      _DashboardStats.empty(
                        buckets: _buildEmptyBuckets(_rangeStart, _rangeEnd),
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardBody(_DashboardStats stats) {
    if (stats.isLoggedOut) {
      return const Center(child: Text("Please log in to view dashboard data."));
    }

    switch (mainTabIndex) {
      case 0:
        return _overviewTab(stats);
      case 1:
        return _earningWalletTab(stats);
      case 2:
        return _subscriptionTab(stats);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _overviewTab(_DashboardStats stats) {
    return _tabScaffold(
      children: [
        if (stats.errorMessage != null) _errorBanner(stats.errorMessage!),
        SubscriptionCard(
          title: "Available Balance",
          subtitle: "Ready to withdraw",
          value: _formatCurrency(stats.availableBalance),
          valueColor: AppColors.primaryPurple,
        ),
        SubscriptionCard(
          title: "Selected Range Earnings",
          subtitle: getDateRange(),
          value: _formatCurrency(stats.rangeEarnings),
          valueColor: AppColors.onlineGreen,
          chart: _EarningsLineChart(
            buckets: stats.buckets,
            fallbackEarnings: stats.rangeEarnings,
          ),
        ),
        SubscriptionCard(
          title: "Locked Message Sales",
          subtitle: getDateRange(),
          value: stats.rangeSales.toString(),
          valueColor: AppColors.primaryPurple,
          chart: _SalesBarChart(buckets: stats.buckets),
        ),
        SubscriptionCard(
          title: "Top Locked Messages",
          subtitle: "By total sales",
          value: stats.topMessages.length.toString(),
          valueColor: AppColors.primaryPurple,
          chart: _TopMessagesChart(messages: stats.topMessages),
        ),
      ],
    );
  }

  Widget _earningWalletTab(_DashboardStats stats) {
    return _tabScaffold(
      children: [
        if (stats.errorMessage != null) _errorBanner(stats.errorMessage!),
        SubscriptionCard(
          title: "Total Earnings",
          subtitle: "All-time creator earnings",
          value: _formatCurrency(stats.totalEarnings),
          valueColor: AppColors.onlineGreen,
        ),
        SubscriptionCard(
          title: "Earnings Snapshot",
          subtitle: "Available, pending, and selected range",
          value: _formatCurrency(stats.availableBalance + stats.pendingBalance),
          valueColor: AppColors.primaryPurple,
          chart: _EarningsSnapshotChart(
            availableBalance: stats.availableBalance,
            pendingBalance: stats.pendingBalance,
            rangeEarnings: stats.rangeEarnings,
          ),
        ),
        SubscriptionCard(
          title: "Selected Range Earnings",
          subtitle: getDateRange(),
          value: _formatCurrency(stats.rangeEarnings),
          valueColor: AppColors.onlineGreen,
          chart: _EarningsLineChart(
            buckets: stats.buckets,
            fallbackEarnings: stats.rangeEarnings,
          ),
        ),
        SubscriptionCard(
          title: "Top Earning Message",
          subtitle:
              stats.topMessages.isEmpty
                  ? "No message sales yet"
                  : "${stats.topMessages.first.title}\n${stats.topMessages.first.totalSales} sales",
          value:
              stats.topMessages.isEmpty
                  ? "0"
                  : _formatCurrency(stats.topMessages.first.earnings),
          valueColor: AppColors.primaryPurple,
        ),
        SubscriptionCard(
          title: "Active Locked Messages",
          subtitle: "Created by you",
          value: stats.activeLockedMessages.toString(),
          valueColor: AppColors.onlineGreen,
        ),
      ],
    );
  }

  Widget _subscriptionTab(_DashboardStats stats) {
    return _tabScaffold(
      children: [
        if (stats.errorMessage != null) _errorBanner(stats.errorMessage!),
        SubscriptionCard(
          title: "Subscription Earnings",
          subtitle: getDateRange(),
          value: _formatCurrency(stats.subscriptionEarnings),
          valueColor: AppColors.onlineGreen,
          chart: _EarningsLineChart(
            buckets: stats.subscriptionBuckets,
            fallbackEarnings: stats.subscriptionEarnings,
          ),
        ),
        SubscriptionCard(
          title: "Total Subscriptions Sold",
          subtitle: getDateRange(),
          value: stats.subscriptionSales.toString(),
          valueColor: AppColors.primaryPurple,
          chart: _SalesBarChart(buckets: stats.subscriptionBuckets),
        ),
        SubscriptionCard(
          title: "Active Subscriptions",
          subtitle: "Currently active subscribers",
          value: stats.activeSubscriptions.toString(),
          valueColor: AppColors.onlineGreen,
          chart: _SalesBarChart(buckets: stats.subscriptionBuckets),
        ),
        SubscriptionCard(
          title: "Expired Subscriptions",
          subtitle: "Expiry tracking not available yet",
          value: stats.expiredSubscriptions.toString(),
          valueColor: AppColors.errorRed,
          chart: _SalesBarChart(buckets: stats.expiredSubscriptionBuckets),
        ),
      ],
    );
  }

  Widget _tabScaffold({required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_dateFilter(), const SizedBox(height: 16), ...children],
      ),
    );
  }

  Widget _dateFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showDatePicker(context),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      getDateRange(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: selectedDuration,
            items:
                durations
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
            onChanged: (val) {
              if (val == null) return;
              selectedDuration = val;
              if (val != "Custom") {
                today = DateTime.now();
              }
              _refreshStats();
            },
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.red50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message, style: const TextStyle(color: AppColors.red700)),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _rangeStart, end: _rangeEnd),
    );

    if (picked != null) {
      startDate = picked.start;
      today = picked.end;
      selectedDuration = "Custom";
      _refreshStats();
    }
  }

  List<_DailyBucket> _buildEmptyBuckets(DateTime start, DateTime end) {
    final buckets = <_DailyBucket>[];
    var cursor = _dateOnly(start);
    final last = _dateOnly(end);

    while (!cursor.isAfter(last)) {
      buckets.add(_DailyBucket(date: cursor));
      cursor = cursor.add(const Duration(days: 1));
    }

    return buckets.isEmpty ? [_DailyBucket(date: last)] : buckets;
  }

  bool _isCreditTransaction(Map<String, dynamic> data) {
    final type = data['type']?.toString().toLowerCase() ?? '';
    final status = data['status']?.toString().toLowerCase() ?? '';
    final category = data['category']?.toString().toLowerCase() ?? '';

    return (type == 'credit' || category == 'order_earning') &&
        status != 'failed' &&
        status != 'cancelled';
  }

  bool _isPaidSubscription(Map<String, dynamic> data) {
    final isPaid = data['isPaid'] == true;
    final price = _readAmount(data['subscriptionPrice']);
    return isPaid || price > 0;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _safeQueryDocs(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      return (await query.get()).docs;
    } on FirebaseException {
      return [];
    }
  }

  int _subscriberCount(Map<String, dynamic> data) {
    final participants = data['participantUids'];
    if (participants is! List) return 0;
    return math.max(0, participants.length - 1);
  }

  bool _isInSelectedRange(DateTime date) {
    return !date.isBefore(_rangeStart) && date.isBefore(_rangeEndExclusive);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _bucketKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  double _readAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int _readInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _formatCurrency(double value) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: value == value.roundToDouble() ? 0 : 2,
    );
    return format.format(value);
  }
}

class _DashboardStats {
  final List<_DailyBucket> buckets;
  final List<_DailyBucket> subscriptionBuckets;
  final List<_DailyBucket> expiredSubscriptionBuckets;
  final double totalEarnings;
  final double availableBalance;
  final double pendingBalance;
  final double rangeEarnings;
  final int rangeSales;
  final int activeLockedMessages;
  final int subscriptionSales;
  final int activeSubscriptions;
  final int expiredSubscriptions;
  final double subscriptionEarnings;
  final List<_MessagePerformance> topMessages;
  final bool isLoggedOut;
  final String? errorMessage;

  const _DashboardStats({
    required this.buckets,
    this.subscriptionBuckets = const [],
    this.expiredSubscriptionBuckets = const [],
    this.totalEarnings = 0,
    this.availableBalance = 0,
    this.pendingBalance = 0,
    this.rangeEarnings = 0,
    this.rangeSales = 0,
    this.activeLockedMessages = 0,
    this.subscriptionSales = 0,
    this.activeSubscriptions = 0,
    this.expiredSubscriptions = 0,
    this.subscriptionEarnings = 0,
    this.topMessages = const [],
    this.isLoggedOut = false,
    this.errorMessage,
  });

  factory _DashboardStats.empty({
    required List<_DailyBucket> buckets,
    bool isLoggedOut = false,
    String? errorMessage,
  }) {
    return _DashboardStats(
      buckets: buckets,
      subscriptionBuckets: buckets,
      expiredSubscriptionBuckets: buckets,
      isLoggedOut: isLoggedOut,
      errorMessage: errorMessage,
    );
  }
}

class _DailyBucket {
  final DateTime date;
  double earnings;
  int sales;

  _DailyBucket({required this.date, this.earnings = 0, this.sales = 0});
}

class _MessagePerformance {
  final String id;
  String title;
  int totalSales;
  double earnings;

  _MessagePerformance({
    required this.id,
    required this.title,
    this.totalSales = 0,
    this.earnings = 0,
  });

  void addSale(double amount) {
    totalSales += 1;
    earnings += amount;
  }
}

class _EarningsLineChart extends StatelessWidget {
  final List<_DailyBucket> buckets;
  final double fallbackEarnings;

  const _EarningsLineChart({
    required this.buckets,
    required this.fallbackEarnings,
  });

  @override
  Widget build(BuildContext context) {
    final bucketValues = buckets.map((bucket) => bucket.earnings).toList();
    final hasBucketData = bucketValues.any((value) => value > 0);
    final hasData = hasBucketData || fallbackEarnings > 0;
    final values =
        hasBucketData || buckets.isEmpty
            ? bucketValues
            : [
              for (var i = 0; i < buckets.length; i++)
                i == buckets.length - 1 ? fallbackEarnings : 0.0,
            ];
    final maxY = math.max(1.0, values.fold<double>(0, math.max) * 1.2);
    final spots = [
      for (var i = 0; i < buckets.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    return _ChartFrame(
      emptyLabel: hasData ? null : "No earnings yet",
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(1, buckets.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine:
                (_) => const FlLine(color: AppColors.grey200, strokeWidth: 1),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: AppColors.grey200),
          ),
          titlesData: _chartTitles(
            buckets: buckets,
            leftFormatter: (value) => value == 0 ? "0" : "₹${value.toInt()}",
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: hasData ? AppColors.onlineGreen : AppColors.grey300,
              barWidth: 3,
              dotData: FlDotData(show: hasData && buckets.length <= 15),
              belowBarData: BarAreaData(
                show: hasData,
                color: AppColors.green100.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsSnapshotChart extends StatelessWidget {
  final double availableBalance;
  final double pendingBalance;
  final double rangeEarnings;

  const _EarningsSnapshotChart({
    required this.availableBalance,
    required this.pendingBalance,
    required this.rangeEarnings,
  });

  @override
  Widget build(BuildContext context) {
    final total = [
      availableBalance,
      pendingBalance,
      rangeEarnings,
    ].fold<double>(0, (sum, value) => sum + value);
    final safeTotal = total <= 0 ? 1.0 : total;
    final items = [
      ("Available", availableBalance, AppColors.primaryPurple),
      ("Pending", pendingBalance, Colors.blue),
      ("Range", rangeEarnings, AppColors.onlineGreen),
    ];

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    item.$1,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: item.$2 / safeTotal,
                      minHeight: 10,
                      color: item.$3,
                      backgroundColor: AppColors.grey200,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 76,
                  child: Text(
                    NumberFormat.compactCurrency(
                      locale: 'en_IN',
                      symbol: '₹',
                      decimalDigits: 0,
                    ).format(item.$2),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SalesBarChart extends StatelessWidget {
  final List<_DailyBucket> buckets;

  const _SalesBarChart({required this.buckets});

  @override
  Widget build(BuildContext context) {
    final hasData = buckets.any((bucket) => bucket.sales > 0);
    final maxY = math.max(
      1.0,
      buckets
              .map((bucket) => bucket.sales.toDouble())
              .fold<double>(0, math.max) *
          1.2,
    );

    return _ChartFrame(
      emptyLabel: hasData ? null : "No sales yet",
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine:
                (_) => const FlLine(color: AppColors.grey200, strokeWidth: 1),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: AppColors.grey200),
          ),
          titlesData: _chartTitles(
            buckets: buckets,
            leftFormatter: (value) => value.toInt().toString(),
          ),
          barGroups: [
            for (var i = 0; i < buckets.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: buckets[i].sales.toDouble(),
                    width: buckets.length > 31 ? 5 : 10,
                    color:
                        hasData ? AppColors.primaryPurple : AppColors.grey300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TopMessagesChart extends StatelessWidget {
  final List<_MessagePerformance> messages;

  const _TopMessagesChart({required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const _ChartFrame(
        emptyLabel: "No locked message sales yet",
        child: SizedBox.expand(),
      );
    }

    final maxSales =
        messages
            .map((message) => message.totalSales)
            .fold<int>(1, math.max)
            .toDouble();

    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children:
            messages.map((message) {
              final progress = message.totalSales / maxSales;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          message.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            color: AppColors.primaryPurple,
                            backgroundColor: AppColors.grey200,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 32,
                        child: Text(
                          message.totalSales.toString(),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _ChartFrame extends StatelessWidget {
  final Widget child;
  final String? emptyLabel;

  const _ChartFrame({required this.child, this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 14, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          if (emptyLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.86),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                emptyLabel!,
                style: const TextStyle(
                  color: AppColors.grey600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

FlTitlesData _chartTitles({
  required List<_DailyBucket> buckets,
  required String Function(double value) leftFormatter,
}) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 42,
        getTitlesWidget: (value, meta) {
          if (value != meta.min && value != meta.max && value % 1 != 0) {
            return const SizedBox.shrink();
          }
          return SideTitleWidget(
            meta: meta,
            child: Text(
              leftFormatter(value),
              style: const TextStyle(fontSize: 10, color: AppColors.grey600),
            ),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 32,
        getTitlesWidget: (value, meta) {
          final index = value.round();
          if (index < 0 ||
              index >= buckets.length ||
              !_shouldShowBottomLabel(index, buckets.length)) {
            return const SizedBox.shrink();
          }
          return SideTitleWidget(
            meta: meta,
            child: Text(
              DateFormat('d MMM').format(buckets[index].date),
              style: const TextStyle(fontSize: 10, color: AppColors.grey600),
            ),
          );
        },
      ),
    ),
  );
}

bool _shouldShowBottomLabel(int index, int length) {
  if (length <= 7) return true;
  if (index == 0 || index == length - 1) return true;
  return index == (length / 2).floor();
}
