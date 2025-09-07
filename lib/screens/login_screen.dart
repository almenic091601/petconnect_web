import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _isAdminUser(String uid) async {
    try {
      final adminDoc =
          await FirebaseFirestore.instance.collection('admins').doc(uid).get();
      return adminDoc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Sign in
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = userCredential.user!.uid;

      // Step 2: Check if UID exists in admins collection
      final isAdmin = await _isAdminUser(uid);
      if (!isAdmin) {
        setState(() {
          _errorMessage = 'Access denied. Only admin users can login.';
          _isLoading = false;
        });
        // Optionally sign out the user
        await FirebaseAuth.instance.signOut();
        return;
      }

      // Proceed to admin dashboard or next screen
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'user-not-found' => 'No admin account found with this email.',
          'wrong-password' => 'Invalid password.',
          'invalid-email' => 'Invalid email address.',
          _ => 'An error occurred. Please try again.',
        };
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left side - Static Image Section
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/good.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Right side - Login Form
          Expanded(
            flex: 1,
            child: Container(
              color: const Color.fromARGB(255, 0, 77, 64),
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo
                          Center(
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          // Title
                          const Column(
                            children: [
                              Text(
                                'PetConnect Admin',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Admin Access Only',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Login Form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: const InputDecoration(
                                    labelText: 'Admin Email',
                                    labelStyle:
                                        TextStyle(color: Colors.black87),
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.admin_panel_settings,
                                        color: Color.fromARGB(255, 0, 77, 64)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintStyle: TextStyle(color: Colors.black38),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    // Move focus to password field
                                    FocusScope.of(context).nextFocus();
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your admin email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle:
                                        const TextStyle(color: Colors.black87),
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.lock,
                                        color: Color.fromARGB(255, 0, 77, 64)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintStyle:
                                        const TextStyle(color: Colors.black38),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: const Color.fromARGB(
                                            255, 0, 77, 64),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    // Trigger login when Enter is pressed
                                    if (_formKey.currentState!.validate()) {
                                      _signIn();
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                if (_errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _signIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor:
                                          const Color.fromARGB(255, 0, 77, 64),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Color.fromARGB(
                                                  255, 0, 77, 64),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
