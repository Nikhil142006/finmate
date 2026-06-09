import 'package:flutter/foundation.dart';
import 'db_service.dart';

class SMSParserService extends ChangeNotifier {
  // Regex filters for common Indian banking/UPI and PhonePe transaction SMS formats
  final List<RegExp> _debitPatterns = [
    // Pattern 1: Paid ₹250 to Swiggy via PhonePe
    RegExp(r'(?:Paid|Sent)\s+(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d+)?)\s+to\s+(.+?)\s+via\s+PhonePe', caseSensitive: false),
    
    // Pattern 2: Debited Rs.500 from a/c XXXXX at Zomato
    RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d+)?)\s+debited\s+from\s+a/c\s+.*?\s+at\s+(.+?)\b', caseSensitive: false),
    
    // Pattern 3: Txn of Rs. 150.00 debited for UPI/Merchant Ref XXXXX
    RegExp(r'debited\s+for\s+(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d+)?)\s+to\s+(.+?)\b', caseSensitive: false),
    
    // Pattern 4: Simple UPI transaction alerts: "Rs. 250.00 debited to Swiggy"
    RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d+)?)\s+debited\s+to\s+(.+?)\b', caseSensitive: false),
  ];

  bool _permissionGranted = false;
  bool get permissionGranted => _permissionGranted;

  Future<void> requestSMSPermissions() async {
    // Under Web/Desktop we automatically mock permission as true to enable testing
    // For physical Android apps, standard permission request flow applies.
    _permissionGranted = true;
    notifyListeners();
  }

  // Parse a received message and insert it into DB
  Future<Map<String, dynamic>?> parseSMS(String messageBody) async {
    for (var pattern in _debitPatterns) {
      final match = pattern.firstMatch(messageBody);
      if (match != null && match.groupCount >= 2) {
        try {
          final amtStr = match.group(1)!.replaceAll(',', '');
          final double amount = double.parse(amtStr);
          
          String merchant = match.group(2)!.trim();
          // Clean up common SMS words from merchant name
          merchant = merchant
              .replaceAll(RegExp(r'(?:Ref\s*\d+|UPI|a/c|Ref\s*No|Val.*)', caseSensitive: false), '')
              .trim();
              
          if (merchant.endsWith('.') || merchant.endsWith(',')) {
            merchant = merchant.substring(0, merchant.length - 1).trim();
          }

          if (merchant.isEmpty) {
            merchant = "PhonePe UPI Merchant";
          }

          // Determine category using our standard helper mapping
          final category = _autoCategorize(merchant);

          return {
            'amount': amount,
            'merchant': merchant,
            'category': category,
            'date': DateTime.now(),
            'paymentMethod': 'PhonePe',
            'source': 'SMS',
          };
        } catch (e) {
          if (kDebugMode) print("Error parsing matched SMS group values: $e");
        }
      }
    }
    return null;
  }

  // Simulates an incoming SMS message trigger for testing
  Future<bool> simulateIncomingSMS(DBService dbService, String text) async {
    final result = await parseSMS(text);
    if (result != null) {
      await dbService.addTransaction(
        result['amount'],
        'EXPENSE',
        result['category'],
        result['date'],
        "Synced from SMS: ${result['merchant']}",
        result['paymentMethod'],
        source: 'SMS',
      );
      return true;
    }
    return false;
  }

  String _autoCategorize(String description) {
    final descLower = description.toLowerCase();
    
    final Map<String, List<String>> categories = {
      "Food": ["swiggy", "zomato", "restaurant", "cafe", "hotel", "food", "eat", "bakery", "mcdonalds", "starbucks", "pizza"],
      "Transport": ["uber", "ola", "metro", "auto", "irctc", "railway", "fuel", "petrol", "shell", "hpcl", "bpcl"],
      "Shopping": ["amazon", "flipkart", "myntra", "meesho", "retail", "mart", "clothing", "supermarket"],
      "Entertainment": ["netflix", "spotify", "prime", "hotstar", "bookmyshow", "cinema", "theatre", "gaming", "steam"],
      "Education": ["udemy", "coursera", "college", "school", "books", "tuition", "academy"],
      "Healthcare": ["apollo", "pharmacy", "chemist", "hospital", "clinic", "lab", "dentist", "medplus"],
      "Utilities": ["electricity", "water", "gas", "recharge", "jio", "airtel", "vi", "broadband", "rent"],
      "Investments": ["groww", "zerodha", "mutual fund", "sip", "stocks", "etf", "indmoney", "fd"]
    };

    for (var entry in categories.entries) {
      if (entry.value.any((keyword) => descLower.contains(keyword))) {
        return entry.key;
      }
    }
    return "Others";
  }
}
