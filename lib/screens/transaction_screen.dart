import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';
import '../services/sms_parser_service.dart';
import '../services/ml_service_client.dart';
import '../widgets/glass_card.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterType = 'ALL';
  final _smsTextController = TextEditingController(text: "Paid Rs. 340 to Zomato via PhonePe");
  bool _smsSyncEnabled = true;
  bool _isSyncingStatement = false;
  bool _isScanningReceipt = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _smsTextController.dispose();
    super.dispose();
  }

  final List<String> _smsSamples = [
    "Paid Rs. 340 to Zomato via PhonePe",
    "Sent Rs. 1500 to Shell Petrol Station via PhonePe",
    "Rs. 120.00 debited to Starbucks Coffee via UPI Ref 67890",
    "Paid Rs. 2999 to Amazon Retail via PhonePe",
    "BESCOM Bill: Rs. 2500 debited from a/c XXXXX123 on 08-06-2026",
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Transactions', icon: Icon(Icons.list_alt_rounded)),
            Tab(text: 'PhonePe Sync', icon: Icon(Icons.sync_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildTransactionsTab(),
          _buildSyncPortalTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80.0), // Above custom bottom bar
              child: FloatingActionButton.extended(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showAddTransactionDialog(context);
                },
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            )
          : null,
    );
  }

  Widget _buildTransactionsTab() {
    final dbService = Provider.of<DBService>(context);
    
    return StreamBuilder<List<TransactionModel>>(
      stream: dbService.getTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
        }

        var list = snapshot.data ?? [];

        if (_filterType == 'INCOME') list = list.where((t) => t.type == 'INCOME').toList();
        else if (_filterType == 'EXPENSE') list = list.where((t) => t.type == 'EXPENSE').toList();
        else if (_filterType == 'PHONEPE') list = list.where((t) => t.paymentMethod == 'PhonePe').toList();

        return Column(
          children: [
            Padding(
              key: const ValueKey('filter_pills_container'),
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFilterPill('All', 'ALL'),
                    _buildFilterPill('Income', 'INCOME'),
                    _buildFilterPill('Expenses', 'EXPENSE'),
                    _buildFilterPill('PhonePe Payments', 'PHONEPE'),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: list.isEmpty
                  ? _buildEmptyTransactions()
                  : ListView.builder(
                      itemCount: list.length,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 100),
                      itemBuilder: (context, index) {
                        return _buildTransactionRow(list[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterPill(String label, String code) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final active = _filterType == code;
    return GestureDetector(
      onTap: () => setState(() => _filterType = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: active ? primaryColor : Colors.grey.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey.shade500,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionRow(TransactionModel tx) {
    final isExpense = tx.type == 'EXPENSE';
    final amtFormatted = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(tx.amount);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(tx.date);
    final primaryColor = Theme.of(context).colorScheme.primary;

    IconData catIcon = Icons.account_balance_wallet_rounded;
    Color iconColor = Colors.grey;

    switch (tx.category.toLowerCase()) {
      case 'food': catIcon = Icons.restaurant; iconColor = Colors.orangeAccent; break;
      case 'transport': catIcon = Icons.directions_car; iconColor = Colors.blueAccent; break;
      case 'shopping': catIcon = Icons.shopping_bag; iconColor = Colors.pinkAccent; break;
      case 'entertainment': catIcon = Icons.movie; iconColor = Colors.purpleAccent; break;
      case 'education': catIcon = Icons.school; iconColor = Colors.greenAccent; break;
      case 'healthcare': catIcon = Icons.medical_services; iconColor = Colors.redAccent; break;
      case 'utilities': catIcon = Icons.flash_on; iconColor = Colors.amber; break;
      case 'investments': catIcon = Icons.trending_up; iconColor = Colors.tealAccent; break;
      case 'salary': catIcon = Icons.work; iconColor = primaryColor; break;
      case 'freelance': catIcon = Icons.computer; iconColor = Colors.cyanAccent; break;
    }

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        Provider.of<DBService>(context, listen: false).deleteTransaction(tx.id, tx.category, tx.amount, tx.type);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.all(4),
          borderRadius: 24,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: iconColor.withOpacity(0.12),
              child: Icon(catIcon, color: iconColor, size: 24),
            ),
            title: Text(tx.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(tx.paymentMethod, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    if (tx.source == 'SMS')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('SMS Sync', style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold)),
                      )
                    else if (tx.source == 'Statement')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Statement', style: TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ],
            ),
            trailing: Text(
              '${isExpense ? "-" : "+"}$amtFormatted',
              style: TextStyle(
                color: isExpense ? Colors.redAccent : primaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 24),
          const Text('No Transactions Yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 12),
          const Text('Create manually or sync your PhonePe transactions.', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSyncPortalTab() {
    final smsService = Provider.of<SMSParserService>(context);
    final dbService = Provider.of<DBService>(context);
    final mlClient = Provider.of<MLServiceClient>(context, listen: false);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 120.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.sms_rounded, color: primaryColor),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Auto-SMS Parser', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        _smsSyncEnabled ? 'Listening to bank alerts' : 'Disabled',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _smsSyncEnabled,
                  activeColor: primaryColor,
                  onChanged: (val) async {
                    if (val) await smsService.requestSMSPermissions();
                    setState(() => _smsSyncEnabled = val);
                  },
                )
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text('Simulator Console', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Text('Trigger parsers manually for testing.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          
          GlassCard(
            padding: const EdgeInsets.all(8),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _smsSamples.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  title: Text(_smsSamples[index], style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  trailing: Icon(Icons.play_arrow_rounded, color: primaryColor, size: 20),
                  onTap: () => _smsTextController.text = _smsSamples[index],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _smsTextController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              labelText: 'Transaction SMS Text',
              prefixIcon: const Icon(Icons.terminal_rounded),
            ),
          ),
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: () async {
              if (_smsTextController.text.trim().isEmpty) return;
              final success = await smsService.simulateIncomingSMS(dbService, _smsTextController.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success ? 'Sync Successful!' : 'Regex failed to match.'),
                  backgroundColor: success ? primaryColor : Colors.orangeAccent,
                ));
              }
            },
            icon: const Icon(Icons.bolt_rounded, color: Colors.white),
            label: const Text('Parse Text', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(height: 40),

          Text('Statement Upload', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Text('Import PDF/CSV statements directly.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          
          GlassCard(
            child: InkWell(
              onTap: _isSyncingStatement ? null : () => _simulateStatementUpload(dbService, mlClient),
              borderRadius: BorderRadius.circular(32),
              child: Container(
                height: 160,
                alignment: Alignment.center,
                child: _isSyncingStatement
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: primaryColor),
                          const SizedBox(height: 16),
                          const Text('Parsing statement...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_rounded, size: 48, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text('Tap to choose file', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text('PDF, CSV supported', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _simulateStatementUpload(DBService dbService, MLServiceClient mlClient) async {
    setState(() => _isSyncingStatement = true);
    await Future.delayed(const Duration(seconds: 2));
    final parsed = await mlClient.parseStatementFile([], "phonepe_statement_june.csv");
    
    for (var tx in parsed) {
      await dbService.addTransaction(
        tx['amount'], tx['type'], tx['category'],
        DateTime.now().subtract(const Duration(days: 4)),
        tx['description'], tx['paymentMethod'], source: 'Statement',
      );
    }
    
    setState(() => _isSyncingStatement = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Imported ${parsed.length} transactions!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ));
      _tabController.animateTo(0);
    }
  }

  void _showAddTransactionDialog(BuildContext context) {
    final dbService = Provider.of<DBService>(context, listen: false);
    final mlClient = Provider.of<MLServiceClient>(context, listen: false);
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final catController = TextEditingController(text: 'Food');
    String paymentMethod = 'PhonePe';
    String type = 'EXPENSE';

    final paymentMethods = ['PhonePe', 'Cash', 'Card', 'NetBanking'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return GlassCard(
              borderRadius: 32,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                left: 24, right: 24, top: 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('New Transaction', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      TextButton.icon(
                        icon: _isScanningReceipt
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(Icons.document_scanner_rounded, color: primaryColor),
                        label: Text('Scan Receipt', style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w900)),
                        onPressed: _isScanningReceipt
                            ? null
                            : () async {
                                setModalState(() => _isScanningReceipt = true);
                                final result = await mlClient.scanReceipt([], "starbucks_receipt.jpg");
                                setModalState(() {
                                  _isScanningReceipt = false;
                                  amountController.text = result.amount.toString();
                                  descController.text = result.merchant;
                                  catController.text = result.category;
                                });
                              },
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(value: 'EXPENSE', label: Text('Expense'), icon: Icon(Icons.arrow_upward_rounded)),
                      ButtonSegment<String>(value: 'INCOME', label: Text('Income'), icon: Icon(Icons.arrow_downward_rounded)),
                    ],
                    selected: {type},
                    onSelectionChanged: (newSelection) {
                      setModalState(() {
                        type = newSelection.first;
                        catController.text = type == 'INCOME' ? 'Salary' : 'Food';
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: type == 'EXPENSE' ? Colors.redAccent.withOpacity(0.2) : primaryColor.withOpacity(0.2),
                      selectedForegroundColor: type == 'EXPENSE' ? Colors.redAccent : primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: catController,
                    decoration: InputDecoration(
                      labelText: 'Category (e.g. Food, Trip, Salary)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: (type == 'INCOME' ? ['Salary', 'Freelance', 'Business'] : ['Food', 'Transport', 'Shopping', 'Trip', 'Investments'])
                        .map((c) => ActionChip(
                              label: Text(c, style: const TextStyle(fontSize: 11)),
                              backgroundColor: primaryColor.withOpacity(0.1),
                              side: BorderSide.none,
                              onPressed: () {
                                setModalState(() => catController.text = c);
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    ),
                    items: paymentMethods.map((pm) => DropdownMenuItem(value: pm, child: Text(pm))).toList(),
                    onChanged: (val) { if (val != null) setModalState(() => paymentMethod = val); },
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: () async {
                      final amt = double.tryParse(amountController.text) ?? 0.0;
                      final desc = descController.text.trim();
                      final cat = catController.text.trim().isEmpty ? 'Others' : catController.text.trim();
                      if (amt <= 0 || desc.isEmpty) return;

                      await dbService.addTransaction(amt, type, cat, DateTime.now(), desc, paymentMethod);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
