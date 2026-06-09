import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';
import '../widgets/glass_card.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _limitController = TextEditingController();
  String _selectedCategory = 'Food';

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DBService>(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final categories = ['Food', 'Transport', 'Shopping', 'Entertainment', 'Education', 'Healthcare', 'Utilities', 'Investments', 'Others'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Set Category Limit', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) { if (val != null) setState(() => _selectedCategory = val); },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _limitController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Limit (₹)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final limit = double.tryParse(_limitController.text) ?? 0.0;
                          if (limit <= 0) return;
                          
                          await dbService.addBudget(_selectedCategory, limit);
                          _limitController.clear();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Budget updated for $_selectedCategory!'),
                                backgroundColor: primaryColor,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Icon(Icons.check_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<BudgetModel>>(
              stream: dbService.getBudgetsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryColor));
                }

                final budgets = snapshot.data ?? [];
                if (budgets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.donut_large_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 24),
                        const Text('No Budgets Set', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                        const SizedBox(height: 12),
                        const Text('Set monthly limits to keep expenses controlled.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: budgets.length,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 100),
                  itemBuilder: (context, index) {
                    return _buildBudgetRow(budgets[index], primaryColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetRow(BudgetModel b, Color primaryColor) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final spent = b.spentAmount;
    final limit = b.limitAmount;
    final double pct = limit > 0 ? (spent / limit) : 0.0;
    
    Color barColor = primaryColor;
    String statusText = "Safe";
    IconData statusIcon = Icons.check_circle_rounded;
    
    if (pct >= 1.0) {
      barColor = Colors.redAccent;
      statusText = "Overspent!";
      statusIcon = Icons.error_rounded;
    } else if (pct >= 0.8) {
      barColor = Colors.orangeAccent;
      statusText = "Approaching Limit (80%+)";
      statusIcon = Icons.warning_amber_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(b.category, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Row(
                  children: [
                    Icon(statusIcon, color: barColor, size: 16),
                    const SizedBox(width: 6),
                    Text(statusText, style: TextStyle(color: barColor, fontWeight: FontWeight.w900, fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.grey.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${currency.format(spent)}',
                  style: TextStyle(color: isOverBudget(spent, limit) ? Colors.redAccent : Colors.grey, fontSize: 13, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Limit: ${limit > 0 ? currency.format(limit) : "Unset"}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ],
            ),
            if (limit > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Utilization: ${(pct * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 11, color: barColor, fontWeight: FontWeight.w900),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool isOverBudget(double spent, double limit) => limit > 0 && spent > limit;
}
