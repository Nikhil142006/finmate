import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dbService = Provider.of<DBService>(context);
    final user = authService.currentUser;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return StreamBuilder<List<TransactionModel>>(
      stream: dbService.getTransactionsStream(),
      builder: (context, snapshot) {
        final txs = snapshot.data ?? [];
        
        // Compute statistics
        double totalIncome = txs.where((t) => t.type == 'INCOME').fold(0.0, (sum, t) => sum + t.amount);
        double totalExpense = txs.where((t) => t.type == 'EXPENSE').fold(0.0, (sum, t) => sum + t.amount);
        double totalBalance = totalIncome - totalExpense;
        double savings = totalBalance > 0 ? totalBalance : 0.0;

        // Compute category spending
        final Map<String, double> catSpending = {};
        for (var t in txs.where((tx) => tx.type == 'EXPENSE')) {
          catSpending[t.category] = (catSpending[t.category] ?? 0.0) + t.amount;
        }

        // The health score is calculated locally per widget build below

        return Scaffold(
          body: RefreshIndicator(
            color: primaryColor,
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // HEADER WELCOME
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FINMATE',
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hello, ${user?.displayName?.split(" ").first ?? "User"} 👋',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Theme.of(context).brightness == Brightness.dark 
                                  ? Icons.light_mode_rounded 
                                  : Icons.dark_mode_rounded,
                              ),
                              onPressed: () {
                                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout_rounded),
                              onPressed: () => authService.logout(),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 32),

                    // SUMMARY BALANCES CARDS
                    _buildBalanceSection(totalBalance, totalIncome, totalExpense, savings, primaryColor),
                    const SizedBox(height: 32),

                    Text(
                      'Financial Health',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<BudgetModel>>(
                      stream: dbService.getBudgetsStream(),
                      builder: (context, budgetSnap) {
                        return StreamBuilder<List<GoalModel>>(
                          stream: dbService.getGoalsStream(),
                          builder: (context, goalSnap) {
                            final budgets = budgetSnap.data ?? [];
                            final goals = goalSnap.data ?? [];
                            final healthResult = dbService.calculateFinancialHealthScore(txs, budgets, goals);
                            return _buildHealthScoreCard(healthResult, primaryColor);
                          }
                        );
                      }
                    ),
                    const SizedBox(height: 32),

                    // CHARTS SECTION
                    if (totalExpense > 0) ...[
                      Text(
                        'Spending Categories',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 16),
                      _buildPieChartCard(catSpending),
                      const SizedBox(height: 32),

                      Text(
                        'Monthly Trend',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 16),
                      _buildLineChartCard(txs, primaryColor),
                      const SizedBox(height: 32),
                    ] else ...[
                      _buildEmptyChartState(primaryColor),
                      const SizedBox(height: 32),
                    ],

                    // QUICK ACCESS ACTIONS
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActionGrid(primaryColor),
                    const SizedBox(height: 100), // padding for bottom nav
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceSection(double balance, double income, double expense, double savings, Color primary) {
    final f = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildMetricCard('Total Balance', f.format(balance), Colors.blueAccent, Icons.account_balance_wallet_rounded),
          _buildMetricCard('Monthly Income', f.format(income), primary, Icons.arrow_downward_rounded),
          _buildMetricCard('Monthly Expenses', f.format(expense), Colors.orangeAccent, Icons.arrow_upward_rounded),
          _buildMetricCard('Net Savings', f.format(savings), Colors.greenAccent, Icons.savings_rounded),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.trending_up, size: 12, color: color),
                )
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard(HealthScoreResult result, Color primary) {
    Color scoreColor = Colors.orangeAccent;
    if (result.score >= 85) scoreColor = primary;
    else if (result.score >= 50) scoreColor = Colors.amber;

    return GlassCard(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    height: 90,
                    width: 90,
                    child: CircularProgressIndicator(
                      value: result.score / 100,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.grey.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${result.score}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                      const Text('Score', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    Expanded(child: Text(result.rating, style: TextStyle(color: scoreColor, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(result.explanation, style: const TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _showHealthSuggestions(result.suggestions, primary),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: primary),
                        const SizedBox(width: 6),
                        Flexible(child: Text('Improvement Tips', style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showHealthSuggestions(List<String> suggestions, Color primary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassCard(
          padding: const EdgeInsets.all(32.0),
          borderRadius: 32,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tips for you', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              ...suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, color: primary, size: 22),
                    const SizedBox(width: 16),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 15, height: 1.5))),
                  ],
                ),
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieChartCard(Map<String, double> categorySpending) {
    final List<MapEntry<String, double>> list = categorySpending.entries.toList();
    final total = list.fold(0.0, (sum, item) => sum + item.value);

    final List<Color> colors = [
      FinMateTheme.zomatoRed, Colors.blueAccent, Colors.orangeAccent, Colors.purpleAccent, Colors.tealAccent, Colors.pinkAccent
    ];

    return GlassCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                        _touchedPieIndex = -1;
                        return;
                      }
                      _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: List.generate(list.length, (i) {
                  final isTouched = i == _touchedPieIndex;
                  final fontSize = isTouched ? 18.0 : 14.0;
                  final radius = isTouched ? 65.0 : 55.0;
                  final pct = (list[i].value / total) * 100;
                  
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: list[i].value,
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: radius,
                    titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, color: Colors.white),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: List.generate(list.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${list[i].key}: ₹${list[i].value.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildLineChartCard(List<TransactionModel> txs, Color primary) {
    final Map<String, double> monthlySums = {};
    for (var tx in txs.where((t) => t.type == 'EXPENSE')) {
      final m = DateFormat('MMM').format(tx.date);
      monthlySums[m] = (monthlySums[m] ?? 0.0) + tx.amount;
    }
    
    final sortedMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final presentMonths = sortedMonths.where((m) => monthlySums.containsKey(m)).toList();
    
    if (presentMonths.isEmpty) return const SizedBox(height: 50);
    
    final List<FlSpot> spots = [];
    for (int i = 0; i < presentMonths.length; i++) {
      spots.add(FlSpot(i.toDouble(), monthlySums[presentMonths[i]]!));
    }

    return GlassCard(
      padding: const EdgeInsets.only(top: 32, bottom: 24, right: 32, left: 16),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    int idx = val.toInt();
                    if (idx >= 0 && idx < presentMonths.length) {
                       return Padding(
                         padding: const EdgeInsets.only(top: 8.0),
                         child: Text(presentMonths[idx], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                       );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: primary,
                barWidth: 6,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 6, color: primary, strokeWidth: 2, strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [primary.withOpacity(0.3), primary.withOpacity(0.0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChartState(Color primary) {
    return GlassCard(
      padding: const EdgeInsets.all(40.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.insert_chart_rounded, size: 72, color: primary.withOpacity(0.5)),
            const SizedBox(height: 24),
            const Text('No Data Yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 12),
            const Text(
              'Add expenses to see beautiful spending charts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionGrid(Color primary) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _buildActionBtn('Transactions', Icons.receipt_long_rounded, () => widget.onNavigate(1), primary),
        _buildActionBtn('Budgets', Icons.donut_large_rounded, () => widget.onNavigate(2), primary),
        _buildActionBtn('Goals', Icons.flag_rounded, () => widget.onNavigate(3), primary),
        _buildActionBtn('AI Chat', Icons.psychology_rounded, () => widget.onNavigate(4), primary),
        _buildActionBtn('Education', Icons.school_rounded, () => widget.onNavigate(5), primary),
        _buildActionBtn('Scan', Icons.document_scanner_rounded, () => widget.onNavigate(1), primary),
      ],
    );
  }

  Widget _buildActionBtn(String label, IconData icon, VoidCallback onTap, Color primary) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primary, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
