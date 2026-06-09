import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isSignUp = false;
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    
    bool success;
    if (_isSignUp) {
      success = await auth.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
    } else {
      success = await auth.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSignUp ? 'Account created successfully!' : 'Welcome back!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Please check your credentials.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _googleSignIn() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final success = await auth.loginWithGoogle();
    setState(() => _isLoading = false);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Logged in with Google!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            key: const ValueKey('login_form_scroll'),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 72,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'FINMATE',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your AI Personal Finance Partner',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 48),
                
                // CARD FORM
                GlassCard(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isSignUp ? 'Create Account' : 'Welcome Back',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(Icons.person_outline_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                          ),
                          validator: (val) => val == null || !val.contains('@') ? 'Please enter a valid email' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                          ),
                          validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                        ),
                        
                        if (!_isSignUp) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                if (_emailController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter your email above first.')),
                                  );
                                  return;
                                }
                                Provider.of<AuthService>(context, listen: false)
                                    .sendForgotPasswordEmail(_emailController.text.trim());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Password reset email sent to ${_emailController.text.trim()}')),
                                );
                              },
                              child: const Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 24),
                        ],
                        
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  _isSignUp ? 'Sign Up' : 'Sign In',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // ALTERNATIVE SIGN IN
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 32),
                
                // GOOGLE SIGN IN
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _googleSignIn,
                  icon: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                    height: 20,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24),
                  ),
                  label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                  ),
                ),
                const SizedBox(height: 40),
                
                // TOGGLE SIGNUP/SIGNIN
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                        });
                      },
                      child: Text(
                        _isSignUp ? 'Sign In' : 'Sign Up',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
