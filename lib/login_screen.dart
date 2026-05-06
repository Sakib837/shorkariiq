import 'package:flutter/material.dart';
import 'user_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool showSignup = false;

  final _loginUser = TextEditingController();
  final _loginPass = TextEditingController();

  final _signupUser = TextEditingController();
  final _signupPass = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _loginUser.dispose();
    _loginPass.dispose();
    _signupUser.dispose();
    _signupPass.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final u = await UserService.login(_loginUser.text.trim(), _loginPass.text);
      if (u == null) {
        setState(() => _error = 'Invalid username or password.');
      } else {
        widget.onLoginSuccess();
      }
    } catch (e) {
      setState(() => _error = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _doSignup() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final name = _signupUser.text.trim();
      if (name.isEmpty) {
        setState(() => _error = 'Username is required.');
      } else {
        await UserService.signup(name, _signupPass.text);
        widget.onLoginSuccess();
      }
    } catch (e) {
      setState(() => _error = 'Signup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _logo() {
    return Column(
      children: [
        Image.asset(
          'assets/ShorkariIQLogo.png',
          width: 140,
          height: 140,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 12),
        const Text(
          'ShorkariIQ',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = showSignup ? _buildSignup() : _buildLogin();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _logo(),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: form,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                if (_busy) const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _loginUser,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _loginPass,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _busy ? null : _doLogin,
          child: const Text('Login'),
        ),
        TextButton(
          onPressed: _busy ? null : () => setState(() => showSignup = true),
          child: const Text("Create an account"),
        ),
      ],
    );
  }

  Widget _buildSignup() {
    return Column(
      key: const ValueKey('signup'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _signupUser,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _signupPass,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password (optional)'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _busy ? null : _doSignup,
          child: const Text('Create Account'),
        ),
        TextButton(
          onPressed: _busy ? null : () => setState(() => showSignup = false),
          child: const Text("Have an account? Login"),
        ),
      ],
    );
  }
}
