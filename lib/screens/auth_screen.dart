import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _rememberMe = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final shouldRemember = prefs.getBool('remember_me') ?? false;
    
    if (savedEmail != null && shouldRemember) {
      _emailCtrl.text = savedEmail;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailCtrl.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> _checkEmailStatus() async {
  if (_emailCtrl.text.trim().isEmpty) {
    setState(() => _error = 'הכנסי כתובת מייל לבדיקה');
    return;
  }
  // אין יותר API לבדיקת קיום מייל מראש - מעבירים פוקוס לסיסמה
  FocusScope.of(context).nextFocus();
}

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'לא נמצא משתמש עם כתובת מייל זו';
      case 'wrong-password':
        return 'סיסמה לא נכונה';
      case 'invalid-credential':
        return 'פרטי ההתחברות שגויים. בדקי את המייל והסיסמה';
      case 'user-disabled':
        return 'המשתמש חסום';
      case 'email-already-in-use':
        return 'כתובת המייל כבר בשימוש';
      case 'weak-password':
        return 'הסיסמה חלשה מדי';
      case 'invalid-email':
        return 'כתובת מייל לא תקינה';
      case 'network-request-failed':
        return 'בעיית רשת. בדקי את החיבור לאינטרנט';
      default:
        return 'שגיאה לא צפויה. נסי שנית';
    }
  }

  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() { _loading = true; _error = null; });

  try {
    if (_isLogin) {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      await _saveEmail();
    } else {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      await cred.user?.updateDisplayName(_nameCtrl.text.trim());
      await _saveEmail();
    }
  } on FirebaseAuthException catch (e) {
    setState(() => _error = _getErrorMessage(e.code));
  } catch (e) {
    setState(() => _error = 'שגיאה לא צפויה. נסי שנית');
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hiking, size: 60, color: Color(0xFF2E7D32)),
                      const SizedBox(height: 8),
                      Text(
                        'טיולים בטבע',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 24),
                      if (!_isLogin)
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'שם מלא', 
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
                        ),
                      if (!_isLogin) const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: InputDecoration(
                          labelText: 'אימייל', 
                          prefixIcon: const Icon(Icons.email),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                            onPressed: _loading ? null : _checkEmailStatus,
                            tooltip: 'בדוק אם המייל רשום',
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passCtrl,
                        decoration: const InputDecoration(
                          labelText: 'סיסמה', 
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (v) => v!.length < 6 ? 'סיסמה צריכה להיות לפחות 6 תווים' : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) => setState(() => _rememberMe = value ?? false),
                            activeColor: const Color(0xFF2E7D32),
                          ),
                          const Text('זכור אותי'),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[300]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!, 
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(_isLogin ? 'כניסה' : 'הרשמה'),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _error = null;
                          });
                        },
                        child: Text(_isLogin ? 'אין לך חשבון? הירשמי' : 'כבר רשומה? התחברי'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
