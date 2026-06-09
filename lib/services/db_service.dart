import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class TransactionModel {
  final String id;
  final double amount;
  final String type; // INCOME or EXPENSE
  final String category;
  final DateTime date;
  final String description;
  final String paymentMethod; // PhonePe, Cash, Card, NetBanking
  final String source; // SMS, Manual, Statement

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.description,
    required this.paymentMethod,
    this.source = 'Manual',
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type,
      'category': category,
      'date': Timestamp.fromDate(date),
      'description': description,
      'paymentMethod': paymentMethod,
      'source': source,
    };
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      type: data['type'] ?? 'EXPENSE',
      category: data['category'] ?? 'Others',
      date: (data['date'] as Timestamp).toDate(),
      description: data['description'] ?? '',
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      source: data['source'] ?? 'Manual',
    );
  }
}

class BudgetModel {
  final String id;
  final String category;
  final double limitAmount;
  final double spentAmount;
  final String monthYear; // MM-yyyy

  BudgetModel({
    required this.id,
    required this.category,
    required this.limitAmount,
    required this.spentAmount,
    required this.monthYear,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'limitAmount': limitAmount,
      'spentAmount': spentAmount,
      'monthYear': monthYear,
    };
  }

  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BudgetModel(
      id: doc.id,
      category: data['category'] ?? 'Others',
      limitAmount: (data['limitAmount'] as num).toDouble(),
      spentAmount: (data['spentAmount'] as num).toDouble(),
      monthYear: data['monthYear'] ?? '',
    );
  }
}

class GoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final double monthlyContribution;

  GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.monthlyContribution,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': Timestamp.fromDate(deadline),
      'monthlyContribution': monthlyContribution,
    };
  }

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GoalModel(
      id: doc.id,
      name: data['name'] ?? '',
      targetAmount: (data['targetAmount'] as num).toDouble(),
      currentAmount: (data['currentAmount'] as num).toDouble(),
      deadline: (data['deadline'] as Timestamp).toDate(),
      monthlyContribution: (data['monthlyContribution'] as num).toDouble(),
    );
  }
}

class HealthScoreResult {
  final int score;
  final String rating;
  final String explanation;
  final List<String> suggestions;

  HealthScoreResult({
    required this.score,
    required this.rating,
    required this.explanation,
    required this.suggestions,
  });
}

class DBService extends ChangeNotifier {
  late final FirebaseFirestore _db;
  
  bool _isFirebaseEnabled = false;
  String? _userId;

  // Local state cache for mock environment
  final List<TransactionModel> _mockTransactions = [];
  final List<BudgetModel> _mockBudgets = [];
  final List<GoalModel> _mockGoals = [];
  final List<Map<String, String>> _mockMessages = [
    {
      'role': 'assistant',
      'content': 'Hello! I am FinMate AI, your personal finance coach. Ask me about your budgets, savings goals, or spending habits. Try asking: **"Where did I spend the most this month?"** or click a suggestion below.'
    }
  ];

  // Controllers for stream fallbacks
  final _txStreamController = StreamController<List<TransactionModel>>.broadcast();
  final _budgetStreamController = StreamController<List<BudgetModel>>.broadcast();
  final _goalStreamController = StreamController<List<GoalModel>>.broadcast();
  final _chatStreamController = StreamController<List<Map<String, String>>>.broadcast();

  List<TransactionModel> get mockTransactions => _mockTransactions;

  DBService() {
    _checkFirebase();
  }

  void _checkFirebase() {
    try {
      _db = FirebaseFirestore.instance;
      if (_db.app != null) {
        _isFirebaseEnabled = true;
      }
    } catch (e) {
      _isFirebaseEnabled = false;
      _preloadMockData();
    }
  }

  void setUserId(String? uid) {
    _userId = uid;
    if (_isFirebaseEnabled && uid != null) {
      // Fire up Firestore streams if needed
    } else {
      _notifyAllMockStreams();
    }
  }

  void _preloadMockData() {
    // 1. Preload transactions
    _mockTransactions.addAll([
      TransactionModel(
        id: 'tx1',
        amount: 25000.0,
        type: 'INCOME',
        category: 'Salary',
        date: DateTime.now().subtract(const Duration(days: 8)),
        description: 'Monthly Corporate Salary',
        paymentMethod: 'NetBanking',
      ),
      TransactionModel(
        id: 'tx2',
        amount: 3500.0,
        type: 'INCOME',
        category: 'Freelance',
        date: DateTime.now().subtract(const Duration(days: 2)),
        description: 'UI Design Landing Page',
        paymentMethod: 'PhonePe',
      ),
      TransactionModel(
        id: 'tx3',
        amount: 820.0,
        type: 'EXPENSE',
        category: 'Food',
        date: DateTime.now().subtract(const Duration(days: 1)),
        description: 'Swiggy Dinner Delivery',
        paymentMethod: 'PhonePe',
        source: 'SMS',
      ),
      TransactionModel(
        id: 'tx4',
        amount: 1200.0,
        type: 'EXPENSE',
        category: 'Transport',
        date: DateTime.now().subtract(const Duration(days: 3)),
        description: 'Ola Cab to Office',
        paymentMethod: 'PhonePe',
        source: 'SMS',
      ),
      TransactionModel(
        id: 'tx5',
        amount: 3400.0,
        type: 'EXPENSE',
        category: 'Shopping',
        date: DateTime.now().subtract(const Duration(days: 4)),
        description: 'Amazon Smartwatch sale',
        paymentMethod: 'Card',
      ),
      TransactionModel(
        id: 'tx6',
        amount: 199.0,
        type: 'EXPENSE',
        category: 'Entertainment',
        date: DateTime.now().subtract(const Duration(days: 7)),
        description: 'Spotify Monthly Premium',
        paymentMethod: 'PhonePe',
      ),
      TransactionModel(
        id: 'tx7',
        amount: 1500.0,
        type: 'EXPENSE',
        category: 'Healthcare',
        date: DateTime.now().subtract(const Duration(days: 5)),
        description: 'Apollo Pharmacy Medicines',
        paymentMethod: 'Cash',
      ),
      TransactionModel(
        id: 'tx8',
        amount: 2500.0,
        type: 'EXPENSE',
        category: 'Investments',
        date: DateTime.now().subtract(const Duration(days: 6)),
        description: 'Nifty Index Fund SIP',
        paymentMethod: 'PhonePe',
      ),
    ]);

    // 2. Preload Budgets
    String monthYear = DateFormat('MM-yyyy').format(DateTime.now());
    _mockBudgets.addAll([
      BudgetModel(id: 'b1', category: 'Food', limitAmount: 5000.0, spentAmount: 820.0, monthYear: monthYear),
      BudgetModel(id: 'b2', category: 'Shopping', limitAmount: 3000.0, spentAmount: 3400.0, monthYear: monthYear),
      BudgetModel(id: 'b3', category: 'Transport', limitAmount: 2000.0, spentAmount: 1200.0, monthYear: monthYear),
      BudgetModel(id: 'b4', category: 'Entertainment', limitAmount: 1500.0, spentAmount: 199.0, monthYear: monthYear),
    ]);

    // 3. Preload Goals
    _mockGoals.addAll([
      GoalModel(
        id: 'g1',
        name: 'Emergency Fund',
        targetAmount: 50000.0,
        currentAmount: 15000.0,
        deadline: DateTime.now().add(const Duration(days: 180)),
        monthlyContribution: 5000.0,
      ),
      GoalModel(
        id: 'g2',
        name: 'Buy Laptop',
        targetAmount: 75000.0,
        currentAmount: 45000.0,
        deadline: DateTime.now().add(const Duration(days: 90)),
        monthlyContribution: 10000.0,
      ),
    ]);

    _notifyAllMockStreams();
  }

  void _notifyAllMockStreams() {
    _txStreamController.add(List.from(_mockTransactions));
    _budgetStreamController.add(List.from(_mockBudgets));
    _goalStreamController.add(List.from(_mockGoals));
    _chatStreamController.add(List.from(_mockMessages));
  }

  // STREAMS
  Stream<List<TransactionModel>> getTransactionsStream() {
    if (_isFirebaseEnabled && _userId != null) {
      return _db.collection('users').doc(_userId).collection('transactions')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList());
    }
    return _txStreamController.stream;
  }

  Stream<List<BudgetModel>> getBudgetsStream() {
    if (_isFirebaseEnabled && _userId != null) {
      return _db.collection('users').doc(_userId).collection('budgets')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => BudgetModel.fromFirestore(doc)).toList());
    }
    return _budgetStreamController.stream;
  }

  Stream<List<GoalModel>> getGoalsStream() {
    if (_isFirebaseEnabled && _userId != null) {
      return _db.collection('users').doc(_userId).collection('goals')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => GoalModel.fromFirestore(doc)).toList());
    }
    return _goalStreamController.stream;
  }

  // MUTATIONS - Transactions
  Future<void> addTransaction(double amount, String type, String category, DateTime date, String description, String paymentMethod, {String source = 'Manual'}) async {
    final id = _isFirebaseEnabled ? null : 'tx_${DateTime.now().millisecondsSinceEpoch}';
    final tx = TransactionModel(
      id: id ?? '',
      amount: amount,
      type: type,
      category: category,
      date: date,
      description: description,
      paymentMethod: paymentMethod,
      source: source,
    );

    if (_isFirebaseEnabled && _userId != null) {
      await _db.collection('users').doc(_userId).collection('transactions').add(tx.toMap());
      // Proactively update budget spent
      if (type == 'EXPENSE') {
        await _updateBudgetSpent(category, amount);
      }
    } else {
      _mockTransactions.insert(0, tx);
      if (type == 'EXPENSE') {
        _updateMockBudgetSpent(category, amount);
      }
      _notifyAllMockStreams();
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id, String category, double amount, String type) async {
    if (_isFirebaseEnabled && _userId != null) {
      await _db.collection('users').doc(_userId).collection('transactions').doc(id).delete();
      if (type == 'EXPENSE') {
        await _updateBudgetSpent(category, -amount);
      }
    } else {
      _mockTransactions.removeWhere((tx) => tx.id == id);
      if (type == 'EXPENSE') {
        _updateMockBudgetSpent(category, -amount);
      }
      _notifyAllMockStreams();
      notifyListeners();
    }
  }

  // MUTATIONS - Budgets
  Future<void> addBudget(String category, double limitAmount) async {
    String monthYear = DateFormat('MM-yyyy').format(DateTime.now());
    
    // Calculate spent amount based on current month's expenses
    double currentSpent = 0.0;
    List<TransactionModel> txs = _isFirebaseEnabled ? [] : _mockTransactions;
    if (!_isFirebaseEnabled) {
      currentSpent = txs
          .where((t) => t.category == category && t.type == 'EXPENSE' && DateFormat('MM-yyyy').format(t.date) == monthYear)
          .fold(0.0, (sum, t) => sum + t.amount);
    }

    if (_isFirebaseEnabled && _userId != null) {
      final docId = '${category}_$monthYear';
      await _db.collection('users').doc(_userId).collection('budgets').doc(docId).set({
        'category': category,
        'limitAmount': limitAmount,
        'spentAmount': currentSpent,
        'monthYear': monthYear,
      });
    } else {
      final id = 'b_${DateTime.now().millisecondsSinceEpoch}';
      final existingIdx = _mockBudgets.indexWhere((b) => b.category == category && b.monthYear == monthYear);
      if (existingIdx != -1) {
        _mockBudgets[existingIdx] = BudgetModel(
          id: _mockBudgets[existingIdx].id,
          category: category,
          limitAmount: limitAmount,
          spentAmount: _mockBudgets[existingIdx].spentAmount,
          monthYear: monthYear,
        );
      } else {
        _mockBudgets.add(BudgetModel(
          id: id,
          category: category,
          limitAmount: limitAmount,
          spentAmount: currentSpent,
          monthYear: monthYear,
        ));
      }
      _notifyAllMockStreams();
      notifyListeners();
    }
  }

  // MUTATIONS - Goals
  Future<void> addGoal(String name, double targetAmount, DateTime deadline, double monthlyContribution) async {
    final goal = GoalModel(
      id: _isFirebaseEnabled ? '' : 'g_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      targetAmount: targetAmount,
      currentAmount: 0.0,
      deadline: deadline,
      monthlyContribution: monthlyContribution,
    );

    if (_isFirebaseEnabled && _userId != null) {
      await _db.collection('users').doc(_userId).collection('goals').add(goal.toMap());
    } else {
      _mockGoals.add(goal);
      _notifyAllMockStreams();
      notifyListeners();
    }
  }

  Future<void> contributeToGoal(String id, double amount) async {
    if (_isFirebaseEnabled && _userId != null) {
      await _db.collection('users').doc(_userId).collection('goals').doc(id).update({
        'currentAmount': FieldValue.increment(amount),
      });
    } else {
      final idx = _mockGoals.indexWhere((g) => g.id == id);
      if (idx != -1) {
        _mockGoals[idx] = GoalModel(
          id: _mockGoals[idx].id,
          name: _mockGoals[idx].name,
          targetAmount: _mockGoals[idx].targetAmount,
          currentAmount: _mockGoals[idx].currentAmount + amount,
          deadline: _mockGoals[idx].deadline,
          monthlyContribution: _mockGoals[idx].monthlyContribution,
        );
        _notifyAllMockStreams();
        notifyListeners();
      }
    }
  }

  // BUDGET HELPERS
  Future<void> _updateBudgetSpent(String category, double delta) async {
    String monthYear = DateFormat('MM-yyyy').format(DateTime.now());
    final docId = '${category}_$monthYear';
    final docRef = _db.collection('users').doc(_userId).collection('budgets').doc(docId);
    
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.update({'spentAmount': FieldValue.increment(delta)});
    } else {
      await docRef.set({
        'category': category,
        'limitAmount': 0.0, // Limit unset
        'spentAmount': delta,
        'monthYear': monthYear,
      });
    }
  }

  void _updateMockBudgetSpent(String category, double delta) {
    String monthYear = DateFormat('MM-yyyy').format(DateTime.now());
    final idx = _mockBudgets.indexWhere((b) => b.category == category && b.monthYear == monthYear);
    if (idx != -1) {
      _mockBudgets[idx] = BudgetModel(
        id: _mockBudgets[idx].id,
        category: category,
        limitAmount: _mockBudgets[idx].limitAmount,
        spentAmount: _mockBudgets[idx].spentAmount + delta,
        monthYear: monthYear,
      );
    } else {
      _mockBudgets.add(BudgetModel(
        id: 'b_${DateTime.now().millisecondsSinceEpoch}',
        category: category,
        limitAmount: 0.0,
        spentAmount: delta,
        monthYear: monthYear,
      ));
    }
  }

  HealthScoreResult calculateFinancialHealthScore(List<TransactionModel> txs, List<BudgetModel> budgets, List<GoalModel> goals) {

    double income = txs.where((t) => t.type == 'INCOME').fold(0.0, (sum, t) => sum + t.amount);
    double expenses = txs.where((t) => t.type == 'EXPENSE').fold(0.0, (sum, t) => sum + t.amount);
    
    // 1. Savings Rate Metric (Max 25 points)
    double savingsRate = income > 0 ? ((income - expenses) / income) * 100 : 0.0;
    double savingsPoints = 2.0;
    if (savingsRate >= 30.0) {
      savingsPoints = 25.0;
    } else if (savingsRate > 0.0) {
      savingsPoints = 5.0 + (savingsRate / 30.0) * 20.0;
    }

    // 2. Budget Adherence Metric (Max 25 points)
    double budgetPoints = 25.0;
    int exceededCount = budgets.where((b) => b.limitAmount > 0 && b.spentAmount > b.limitAmount).length;
    
    if (budgets.isEmpty) {
      budgetPoints = 20.0; 
    } else {
      double totalLimit = budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
      double totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
      if (totalLimit > 0) {
        double util = totalSpent / totalLimit;
        budgetPoints = 25.0 - ((util.clamp(0.0, 1.5)) * 10.0);
        budgetPoints -= (exceededCount * 4.0);
        budgetPoints = budgetPoints.clamp(5.0, 25.0);
      }
    }

    // 3. Emergency Fund Level Metric (Max 20 points)
    double emergencyPoints = 10.0; 
    final emergencyGoal = goals.where((g) => g.name.toLowerCase().contains("emergency")).toList();
    if (emergencyGoal.isNotEmpty && emergencyGoal[0].targetAmount > 0) {
      double pct = (emergencyGoal[0].currentAmount / emergencyGoal[0].targetAmount).clamp(0.0, 1.0);
      emergencyPoints = 10.0 + (pct * 10.0);
    }

    // 4. Income Consistency Metric (Max 15 points)
    int incomeCount = txs.where((t) => t.type == 'INCOME').length;
    double consistencyPoints = (incomeCount * 5.0).clamp(5.0, 15.0);

    // 5. Debt Ratio / Investment Focus Metric (Max 15 points)
    double investmentTotal = txs.where((t) => t.category == 'Investments').fold(0.0, (sum, t) => sum + t.amount);
    double investmentPoints = 5.0;
    if (investmentTotal > 0 && income > 0) {
      double pctOfIncome = (investmentTotal / income) * 100;
      investmentPoints = 5.0 + (pctOfIncome / 15.0) * 10.0;
      investmentPoints = investmentPoints.clamp(5.0, 15.0);
    }

    int totalScore = (savingsPoints + budgetPoints + emergencyPoints + consistencyPoints + investmentPoints).round();
    totalScore = totalScore.clamp(0, 100);

    String rating = "Needs Work";
    String explanation = "Your finances are unstable. Focus on cutting down unnecessary shopping and building a buffer.";
    if (totalScore >= 85) {
      rating = "Excellent";
      explanation = "You are demonstrating outstanding financial discipline! Strong savings rate, budgets are in check, and you are investing consistently.";
    } else if (totalScore >= 70) {
      rating = "Good";
      explanation = "You are on the right track. Consider boosting your monthly savings rate to 30% and locking in an Emergency Fund.";
    } else if (totalScore >= 50) {
      rating = "Fair";
      explanation = "Moderate financial health. You are matching expenses closely with income. Reduce discretionary budgets.";
    }

    List<String> suggestions = [];
    if (savingsRate < 20) {
      suggestions.add("Aim to increase your savings rate above 20% by reducing dining and subscription expenses.");
    }
    if (exceededCount > 0) {
      suggestions.add("You overspent in $exceededCount budget category. Enable notifications to get alerts at 80% utilization.");
    }
    if (emergencyGoal.isEmpty || (emergencyGoal.isNotEmpty && (emergencyGoal[0].currentAmount / emergencyGoal[0].targetAmount) < 0.5)) {
      suggestions.add("Prioritize funding your Emergency Fund to cover at least 3 months of basic expenses.");
    }
    if (investmentTotal == 0) {
      suggestions.add("Start a recurring SIP mutual fund investment. Even ₹1,000/month helps build wealth long term.");
    }
    if (suggestions.isEmpty) {
      suggestions.add("Keep up the great work! Consider moving extra cash from savings into index funds for inflation-beating yields.");
    }

    return HealthScoreResult(
      score: totalScore,
      rating: rating,
      explanation: explanation,
      suggestions: suggestions,
    );
  }

  // CHAT STREAM & MUTATIONS
  Stream<List<Map<String, String>>> getChatMessagesStream() {
    if (_isFirebaseEnabled && _userId != null) {
      return _db.collection('users').doc(_userId).collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                return {
                  'role': data['role']?.toString() ?? 'assistant',
                  'content': data['content']?.toString() ?? '',
                };
              }).toList());
    }
    return _chatStreamController.stream;
  }

  Future<void> saveChatMessage(String role, String content) async {
    if (_isFirebaseEnabled && _userId != null) {
      await _db.collection('users').doc(_userId).collection('messages').add({
        'role': role,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      _mockMessages.add({
        'role': role,
        'content': content,
      });
      _chatStreamController.add(List.from(_mockMessages));
      notifyListeners();
    }
  }

  Future<void> clearChatHistory() async {
    if (_isFirebaseEnabled && _userId != null) {
      final snapshot = await _db.collection('users').doc(_userId).collection('messages').get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } else {
      _mockMessages.clear();
      _mockMessages.add({
        'role': 'assistant',
        'content': 'Chat history cleared. Hello! I am FinMate AI, your personal finance coach.'
      });
      _chatStreamController.add(List.from(_mockMessages));
      notifyListeners();
    }
  }
}
