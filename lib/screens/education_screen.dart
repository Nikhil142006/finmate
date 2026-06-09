import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  int _currentQuestionIdx = 0;
  int _scoreTotal = 0;
  bool _quizActive = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is your primary investment goal?',
      'options': [
        {'text': 'Protect my cash and avoid any losses', 'points': 1},
        {'text': 'Grow my wealth steadily over time', 'points': 2},
        {'text': 'Maximize returns, accepting high volatility', 'points': 3},
      ]
    },
    {
      'question': 'How would you react if your investments fell by 20% in a month?',
      'options': [
        {'text': 'Sell everything immediately to prevent more losses', 'points': 1},
        {'text': 'Hold and wait for the market to recover', 'points': 2},
        {'text': 'Buy more at a discount to average down costs', 'points': 3},
      ]
    },
    {
      'question': 'What is your investment duration horizon?',
      'options': [
        {'text': 'Short term (Less than 2 years)', 'points': 1},
        {'text': 'Medium term (2 to 5 years)', 'points': 2},
        {'text': 'Long term (More than 5 years)', 'points': 3},
      ]
    },
    {
      'question': 'How much of your monthly income do you currently save?',
      'options': [
        {'text': 'Less than 10%', 'points': 1},
        {'text': 'Between 10% and 30%', 'points': 2},
        {'text': 'More than 30%', 'points': 3},
      ]
    },
    {
      'question': 'How stable is your primary source of income?',
      'options': [
        {'text': 'Unpredictable (Freelance, Gig)', 'points': 1},
        {'text': 'Stable but fixed salary', 'points': 2},
        {'text': 'High growth potential or business', 'points': 3},
      ]
    },
    {
      'question': 'Have you built an emergency fund covering 6 months of expenses?',
      'options': [
        {'text': 'No, I have very little cash reserves', 'points': 1},
        {'text': 'Partially, covering 1 to 3 months', 'points': 2},
        {'text': 'Yes, fully funded', 'points': 3},
      ]
    },
    {
      'question': 'How familiar are you with the stock market and mutual funds?',
      'options': [
        {'text': 'Complete beginner', 'points': 1},
        {'text': 'Basic knowledge', 'points': 2},
        {'text': 'Advanced, I actively trade', 'points': 3},
      ]
    },
    {
      'question': 'If you received a sudden ₹1 Lakh bonus, what would you do?',
      'options': [
        {'text': 'Keep it in a savings account or FD', 'points': 1},
        {'text': 'Invest half in a mutual fund, keep half', 'points': 2},
        {'text': 'Invest it entirely in the stock market', 'points': 3},
      ]
    }
  ];

  void _answerQuestion(int points) {
    _scoreTotal += points;
    if (_currentQuestionIdx < _questions.length - 1) {
      setState(() {
        _currentQuestionIdx++;
      });
    } else {
      String profile = 'Moderate';
      if (_scoreTotal <= 13) {
        profile = 'Conservative';
      } else if (_scoreTotal >= 20) {
        profile = 'Aggressive';
      }

      Provider.of<AuthService>(context, listen: false).updateProfile(riskProfile: profile);

      setState(() {
        _quizActive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final hasProfile = user?.riskProfile != null && user!.riskProfile.isNotEmpty;
    final activeProfile = user?.riskProfile ?? 'Moderate';
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Education', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Risk Profiler & Asset Allocation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Your Active Profile: ', style: TextStyle(fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(activeProfile, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  if (!_quizActive) ...[
                    if (hasProfile) ...[
                      const Text(
                        '🎉 Your personalized profile recommendations are updated below. You can re-take the quiz anytime.',
                        style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentQuestionIdx = 0;
                            _scoreTotal = 0;
                            _quizActive = true;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Retake', style: TextStyle(fontWeight: FontWeight.w900)),
                      )
                    ] else ...[
                      const Text(
                        'Take our 1-minute questionnaire to determine your exact risk category and get asset suggestions.',
                        style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentQuestionIdx = 0;
                            _scoreTotal = 0;
                            _quizActive = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Start Quiz', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      )
                    ]
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        'Question ${_currentQuestionIdx + 1} of ${_questions.length}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _questions[_currentQuestionIdx]['question'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, height: 1.3),
                    ),
                    const SizedBox(height: 24),
                    ...(_questions[_currentQuestionIdx]['options'] as List).map((opt) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: OutlinedButton(
                        onPressed: () => _answerQuestion(opt['points']),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Text(opt['text'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
                      ),
                    )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Suggested Asset Classes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            ..._getAssetsForProfile(activeProfile, primaryColor),
            const SizedBox(height: 32),

            Text(
              'Recommended Learning Platforms',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            ..._getLearningResourcesForProfile(activeProfile, primaryColor),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Text('Important Disclaimer', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent, fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This information is for educational purposes only and does not constitute financial advice.',
                    style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _getAssetsForProfile(String profile, Color primaryColor) {
    if (profile == 'Conservative') {
      return [
        _buildAssetCard('Fixed Deposits (FD)', 'Low', '6.5% - 7.5% p.a.', 'Guaranteed savings certificates offered by commercial banks with virtually zero principal risk.', Icons.lock_outline_rounded, Colors.blueAccent, primaryColor),
        _buildAssetCard('Government Bonds', 'Low', '7.0% - 7.8% p.a.', 'Debt instruments issued by the RBI representing low-risk credit backed by the state treasury.', Icons.account_balance_rounded, Colors.tealAccent, primaryColor),
        _buildAssetCard('Index Funds (Large Cap)', 'Low - Mod', '11.0% - 12.5% p.a.', 'Passive equity funds tracking top 50 blue-chip stocks (Nifty/Sensex).', Icons.trending_up_rounded, Colors.orangeAccent, primaryColor),
      ];
    } else if (profile == 'Aggressive') {
      return [
        _buildAssetCard('Growth Stocks & Mid Caps', 'High', '15.0% - 20%+ p.a.', 'Individual corporate shares in fast-scaling tech and industrial sectors.', Icons.bolt_rounded, Colors.redAccent, primaryColor),
        _buildAssetCard('Sectoral Funds', 'High', '16.0% - 22%+ p.a.', 'Mutual funds concentrated heavily on a single sector prone to high volatility.', Icons.pie_chart_rounded, Colors.purpleAccent, primaryColor),
        _buildAssetCard('International Equities', 'High', '12.0% - 15% p.a.', 'Exposure to foreign indices (NASDAQ/S&P 500) to diversify currency risks.', Icons.public_rounded, Colors.indigoAccent, primaryColor),
      ];
    } else {
      return [
        _buildAssetCard('Diversified Mutual Funds', 'Moderate', '12.0% - 14.5% p.a.', 'Managed funds investing across large, mid, and small-cap stocks.', Icons.widgets_rounded, Colors.indigoAccent, primaryColor),
        _buildAssetCard('Equity ETFs', 'Moderate', '13.0% - 15.0% p.a.', 'Baskets of securities trading on exchanges, mimicking major equity indices.', Icons.insights_rounded, Colors.tealAccent, primaryColor),
        _buildAssetCard('Systematic Investment Plans', 'Moderate', '12.5% - 14.0% p.a.', 'Disciplined rupee-cost averaging investments that invest fixed amounts monthly.', Icons.published_with_changes_rounded, primaryColor, primaryColor),
      ];
    }
  }

  List<Widget> _getLearningResourcesForProfile(String profile, Color primaryColor) {
    if (profile == 'Conservative') {
      return [
        _buildResourceCard('Investopedia', 'Basics of Fixed Income', 'Learn the fundamentals of bonds, FDs, and risk-free returns.', Icons.menu_book_rounded, Colors.blueAccent, 'https://www.investopedia.com/terms/f/fixedincome.asp'),
        _buildResourceCard('Zerodha Varsity', 'Intro to Mutual Funds', 'Understand how mutual funds work and how to select safe debt funds.', Icons.school_rounded, Colors.orangeAccent, 'https://zerodha.com/varsity/'),
        _buildResourceCard('YouTube (Pranjal Kamra)', 'Safe Investment Strategies', 'Video guides on beating inflation without taking stock market risks.', Icons.play_circle_filled_rounded, Colors.redAccent, 'https://www.youtube.com/@pranjalkamra'),
      ];
    } else if (profile == 'Aggressive') {
      return [
        _buildResourceCard('Zerodha Varsity', 'Technical & Fundamental Analysis', 'Deep dive into picking high-growth stocks and reading balance sheets.', Icons.candlestick_chart_rounded, Colors.indigoAccent, 'https://zerodha.com/varsity/'),
        _buildResourceCard('YouTube (Akshat Shrivastava)', 'High Growth & Global Stocks', 'Insights on macroeconomic trends and aggressive equity investing.', Icons.play_circle_filled_rounded, Colors.redAccent, 'https://www.youtube.com/@AkshatZayn'),
        _buildResourceCard('Sensibull Education', 'Options & Derivatives', 'Advanced trading strategies to hedge and leverage volatile markets.', Icons.dynamic_form_rounded, Colors.purpleAccent, 'https://sensibull.com/'),
      ];
    } else {
      return [
        _buildResourceCard('Zerodha Varsity', 'Personal Finance & Indexing', 'Learn the power of compounding and long-term index fund investing.', Icons.school_rounded, Colors.tealAccent, 'https://zerodha.com/varsity/'),
        _buildResourceCard('YouTube (CA Rachana Ranade)', 'Stock Market Basics', 'Simplified tutorials on building a balanced equity and debt portfolio.', Icons.play_circle_filled_rounded, Colors.redAccent, 'https://www.youtube.com/@CARachanaRanade'),
        _buildResourceCard('Book', 'The Psychology of Money', 'Timeless lessons on wealth, greed, and happiness by Morgan Housel.', Icons.book_rounded, Colors.blueGrey, 'https://www.amazon.in/Psychology-Money-Morgan-Housel/dp/9390166268'),
      ];
    }
  }

  Widget _buildAssetCard(String name, String risk, String returns, String desc, IconData icon, Color color, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Risk: ', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w800)),
                                Text(risk, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Returns: ', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w800)),
                                Text(returns, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: primaryColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Text(desc, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(String platform, String topic, String desc, IconData icon, Color color, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(platform, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 6),
                  Text(topic, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text('Visit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
