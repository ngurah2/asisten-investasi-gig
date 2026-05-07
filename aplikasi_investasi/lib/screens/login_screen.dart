import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoginMode = true;
  bool isLoading = false;
  
  bool _isObscurePassword = true;
  bool _isObscureConfirm = true;

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _submitAuth() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    
    // Mode Login
    if (isLoginMode) {
      if (username.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap isi Username dan Password!'), backgroundColor: Colors.red));
        return;
      }
    } 
    // Mode Register
    else {
      String nama = _namaController.text.trim();
      String email = _emailController.text.trim();
      String confirmPassword = _confirmPasswordController.text.trim();

      if (nama.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap isi semua kolom pendaftaran!'), backgroundColor: Colors.red));
        return;
      }
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak cocok!'), backgroundColor: Colors.red));
        return;
      }
    }

    setState(() => isLoading = true);

    Map<String, dynamic> response;
    if (isLoginMode) {
      response = await ApiService.loginUser(username, password);
    } else {
      String nama = _namaController.text.trim();
      String email = _emailController.text.trim();
      response = await ApiService.registerUser(nama, username, email, password);
    }

    setState(() => isLoading = false);

    if (response['status'] == 'sukses') {
      if (isLoginMode) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', response['data']['nama']);
        await prefs.setInt('userId', response['data']['id']);
        
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registrasi Berhasil! Silakan Login.'), backgroundColor: Colors.teal));
        setState(() {
          isLoginMode = true;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['pesan']), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.account_balance_wallet, size: 64, color: Colors.teal[700]),
                const SizedBox(height: 16),
                Text(isLoginMode ? 'Selamat Datang Kembali' : 'Mulai Bersama GIM', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal[800])),
                const SizedBox(height: 8),
                Text(isLoginMode ? 'Masuk untuk kelola investasimu' : 'Daftar untuk jadikan AI manajer keuanganmu', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                
                // Form khusus Registrasi
                if (!isLoginMode) ...[
                  TextField(controller: _namaController, decoration: InputDecoration(labelText: 'Nama Lengkap', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 16),
                  TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 16),
                ],
                
                // Username digunakan di kedua mode
                TextField(controller: _usernameController, decoration: InputDecoration(labelText: 'Username', prefixIcon: const Icon(Icons.alternate_email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 16),
                
                // Password digunakan di kedua mode
                TextField(
                  controller: _passwordController, 
                  obscureText: _isObscurePassword, 
                  decoration: InputDecoration(
                    labelText: 'Password', 
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_isObscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.teal),
                      onPressed: () => setState(() => _isObscurePassword = !_isObscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                  )
                ),
                
                // Konfirmasi Password khusus Registrasi
                if (!isLoginMode) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController, 
                    obscureText: _isObscureConfirm, 
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password', 
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isObscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.teal),
                        onPressed: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                    )
                  ),
                ],
                
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isLoading ? null : _submitAuth,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : Text(isLoginMode ? 'MASUK' : 'DAFTAR', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() {
                    isLoginMode = !isLoginMode;
                    _passwordController.clear();
                    _confirmPasswordController.clear();
                  }),
                  child: Text(isLoginMode ? 'Belum punya akun? Daftar sekarang' : 'Sudah punya akun? Masuk di sini', style: TextStyle(color: Colors.teal[600])),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}