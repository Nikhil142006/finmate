import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';
import '../widgets/glass_card.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _contribController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _contribController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DBService>(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Goals', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(24.0),
              child: ExpansionTile(
                title: const Text('Create Saving Goal', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                iconColor: primaryColor,
                textColor: primaryColor,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Goal Name (e.g. Master Abroad Fund)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _targetController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Target Amount (₹)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  filled: true,
                                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _contribController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Monthly Deposit (₹)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  filled: true,
                                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: Icon(Icons.calendar_month_rounded, color: primaryColor),
                          label: Text(
                            'Target Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(color: primaryColor.withOpacity(0.5)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            final name = _nameController.text.trim();
                            final target = double.tryParse(_targetController.text) ?? 0.0;
                            final contrib = double.tryParse(_contribController.text) ?? 0.0;

                            if (name.isEmpty || target <= 0 || contrib <= 0) return;
                            
                            await dbService.addGoal(name, target, _selectedDate, contrib);
                            
                            _nameController.clear();
                            _targetController.clear();
                            _contribController.clear();
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Goal created! Let\'s crush it.'),
                                  backgroundColor: primaryColor,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Add Goal', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<GoalModel>>(
              stream: dbService.getGoalsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryColor));
                }

                final goals = snapshot.data ?? [];
                if (goals.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 24),
                        const Text('No Saving Goals', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                        const SizedBox(height: 12),
                        const Text('Track deadlines and watch your wealth compound.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: goals.length,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 100),
                  itemBuilder: (context, index) {
                    return _buildGoalRow(goals[index], dbService, primaryColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRow(GoalModel g, DBService dbService, Color primaryColor) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final double pct = g.targetAmount > 0 ? (g.currentAmount / g.targetAmount) : 0.0;
    final deadlineStr = DateFormat('MMM yyyy').format(g.deadline);

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
                Text(g.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('Target: $deadlineStr', style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saved: ${currency.format(g.currentAmount)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: primaryColor)),
                Text('Goal: ${currency.format(g.targetAmount)}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.grey.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Monthly Contribution: ${currency.format(g.monthlyContribution)}', style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                ElevatedButton.icon(
                  onPressed: () => _showDepositDialog(g.id, g.name, dbService, primaryColor),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Money', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    foregroundColor: primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDepositDialog(String id, String name, DBService dbService, Color primaryColor) {
    final depositController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Add Funds: $name', style: const TextStyle(fontWeight: FontWeight.w900)),
          content: TextField(
            controller: depositController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Deposit Amount (₹)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(depositController.value.text) ?? 0.0;
                if (amt <= 0) return;
                
                await dbService.contributeToGoal(id, amt);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Deposit'),
            )
          ],
        );
      },
    );
  }
}
