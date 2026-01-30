import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Manual Firebase init (uses google-services.json / GoogleService-Info.plist)
  await Firebase.initializeApp();

  runApp(const RocrizzApp());
}

class RocrizzApp extends StatelessWidget {
  const RocrizzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rocrizz',
      theme: ThemeData(useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}

/// ========================
/// LOGIN
/// ========================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged in successfully')),
      );

      _goToHome();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in with Google')),
      );

      _goToHome();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Google sign-in failed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? 420 : 920),
          child: Row(
            children: [
              if (!isMobile)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'DocRizz',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Welcome back. Please log in to continue.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 24,
                          offset: Offset(0, 10),
                          color: Colors.black12,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Google button (FittedBox prevents Row overflow)
                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _loading ? null : _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              backgroundColor: Colors.white,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.g_mobiledata, size: 30),
                                  SizedBox(width: 10),
                                  Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
                                    );
                                  },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              backgroundColor: Colors.white,
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.phone_android, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Continue with Phone',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Row(
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR CONTINUE WITH',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'Email',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        _input(_email, 'you@example.com', TextInputType.emailAddress),

                        const SizedBox(height: 14),

                        const Text(
                          'Password',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () async {
                              final email = _email.text.trim();
                              if (email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Enter your email first')),
                                );
                                return;
                              }
                              await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password reset email sent')),
                              );
                            },
                            child: const Text('Forgot password?'),
                          ),
                        ),

                        const SizedBox(height: 8),

                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Flexible(
                              child: Text("Don't have an account? ", overflow: TextOverflow.ellipsis),
                            ),
                            TextButton(
                              onPressed: () async {
                                final email = _email.text.trim();
                                final pass = _password.text;

                                if (email.isEmpty || pass.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Enter email + password to sign up')),
                                  );
                                  return;
                                }

                                setState(() => _loading = true);
                                try {
                                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                    email: email,
                                    password: pass,
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Account created')),
                                  );
                                  _goToHome();
                                } on FirebaseAuthException catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.message ?? 'Sign up failed')),
                                  );
                                } finally {
                                  if (mounted) setState(() => _loading = false);
                                }
                              },
                              child: const Text('Sign up'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String hint, TextInputType type) {
    return TextField(
      controller: c,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
  
}

/// ========================
/// HOME (Projects)
/// ========================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  String? _error;
  List<Project> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await DocRizzApi.getProjects();
      if (!mounted) return;
      setState(() => _projects = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Color _parseHex(String hex) {
    var h = hex.trim();
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  Widget _userInfoBlock(String name, String email) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'User';
    final email = user?.email ?? '';

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    final cols = width < 520
        ? 1
        : width < 900
            ? 2
            : 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 24,
                  offset: Offset(0, 10),
                  color: Colors.black12,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile) ...[
                  // ✅ FIX: Use Wrap in header actions to prevent Row overflow
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrowDesktop = constraints.maxWidth < 860;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DocRizz',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Manage your projects',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Wrap(
                                  alignment: WrapAlignment.end,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 12,
                                  runSpacing: 10,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const AllReceiptsScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.calendar_month, size: 18),
                                      label: const Text(
                                        'All Receipts',
                                        style: TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    if (!isNarrowDesktop)
                                      _userInfoBlock(name, email)
                                    else
                                      // on narrow desktop, show user info smaller to avoid overflow
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 180),
                                        child: _userInfoBlock(name, email),
                                      ),
                                    SizedBox(
                                      height: 38,
                                      child: ElevatedButton(
                                        onPressed: () => _logout(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF111827),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: const Text(
                                          'Logout',
                                          style: TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ] else ...[
                  // mobile header stays compact
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'DocRizz',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'All Receipts',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AllReceiptsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_month),
                      ),
                      SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: () => _logout(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF111827),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Manage your projects',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 18),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadProjects,
                    child: ListView(
                      children: [
                        if (_loading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 24),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_error!, style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _loadProjects,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        else if (_projects.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'No projects yet. Create your first project below.',
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _projects.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.4,
                            ),
                            itemBuilder: (context, i) {
                              final p = _projects[i];
                              final c = _parseHex(p.color);

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 18,
                                      offset: Offset(0, 10),
                                      color: Color(0x22000000),
                                    )
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: -8,
                                      left: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.white),
                                        onPressed: () async {
                                          final changed = await showDialog<bool>(
                                            context: context,
                                            barrierDismissible: true,
                                            builder: (_) => EditProjectDialog(project: p),
                                          );
                                          if (changed == true) {
                                            await _loadProjects();
                                          }
                                        },
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 6),
                                        const Spacer(),
                                        Text(
                                          p.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 1),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _pillButton(
                                                icon: Icons.upload,
                                                label: _uploading ? 'Uploading...' : 'Upload',
                                                onTap: () => _uploading ? null : _uploadReceiptForProject(p),

                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _pillButton(
                                                icon: Icons.remove_red_eye,
                                                label: 'View',
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => ProjectDetailsScreen(
                                                        projectId: p.id,
                                                        projectName: p.name,
                                                        projectColor: p.color,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 16),

                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final created = await showDialog<bool>(
                              context: context,
                              barrierDismissible: true,
                              builder: (_) => const CreateProjectDialog(),
                            );
                            if (created == true) await _loadProjects();
                          },
                          child: Container(
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Color(0xFFF3F4F6),
                                    child: Icon(Icons.add, color: Colors.black54),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'New Project',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;

  String _guessContentType(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
    if (p.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  Future<void> _uploadReceiptForProject(Project p) async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;

    setState(() => _uploading = true);

    try {
      final bytes = await picked.readAsBytes();
      final contentType = _guessContentType(picked.path);

      // 1) get upload url + receiptId
      final uploadResp = await DocRizzApi.getReceiptUploadUrl(
        projectId: p.id,
        contentType: contentType,
      );

      // 2) upload to presigned url (PUT)
      await DocRizzApi.uploadBytesToPresignedUrl(
        uploadUrl: uploadResp.uploadUrl,
        bytes: bytes,
        contentType: contentType,
      );

      // 3) ✅ CONFIRM (MANDATORY)
      final confirmed = await DocRizzApi.confirmReceipt(
        receiptId: uploadResp.receiptId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploaded & confirmed: ${confirmed.id}')),
      );

      // Refresh UI (receipts/projects)
      await _loadProjects();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}


class AllReceiptsScreen extends StatefulWidget {
  const AllReceiptsScreen({super.key});

  @override
  State<AllReceiptsScreen> createState() => _AllReceiptsScreenState();
}

class _AllReceiptsScreenState extends State<AllReceiptsScreen> {
  bool _loading = true;
  bool _opening = false;
  bool _listView = false; 
  String? _error;
  final _search = TextEditingController();
  String _q = '';

  final Map<String, ReceiptDetails> _detailsCache = {};
  final Set<String> _detailsLoading = {};

  List<Project> _projects = [];
  List<ReceiptItem> _receipts = [];

  String? _selectedProjectId; // null => All Projects

  @override
  void initState() {
    super.initState();
    _load();
  }
  
  @override
    void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        DocRizzApi.getProjects(),
        DocRizzApi.getReceipts(),
      ]);

      final projects = results[0] as List<Project>;
      final receipts = results[1] as List<ReceiptItem>;

      if (!mounted) return;

      setState(() {
        _projects = projects;
        _receipts = receipts;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  } 

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final nameById = _projectNameById();
    final q = _q.trim().toLowerCase();
    
    final base = _selectedProjectId == null
      ? _receipts
      : _receipts.where((r) => r.projectId == _selectedProjectId).toList();
    
    final shown = q.isEmpty
    ? base
    : base.where((r) { 
      final name = (r.name).toLowerCase();
      // If your list API later includes vendorName, add it here too.
      return name.contains(q);
    }).toList();

    Widget dropdown({double? width}) {
      final field = DropdownButtonFormField<String?>(
        value: _selectedProjectId,
        isExpanded: true,
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('All Projects'),
          ),
          ..._projects.map(
            (p) => DropdownMenuItem<String?>(
              value: p.id,
              child: Text(p.name, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (v) => setState(() => _selectedProjectId = v),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
      );

      if (width == null) return field;
      return SizedBox(width: width, child: field);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              if (isMobile) ...[
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Receipts',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_opening)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      _viewToggle(),
                      const SizedBox(width: 10),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'View and manage your project receipts',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                dropdown(),
                const SizedBox(height: 12),
                _searchBar(),
              ] else ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxW = constraints.maxWidth;
                    final ddW = (maxW * 0.34).clamp(200.0, 320.0);

                    return Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Receipts',
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'View and manage your project receipts',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            dropdown(width: ddW),
                            const SizedBox(width: 10),
                             _viewToggle(),
                             const SizedBox(width: 10),
                            if (_opening)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _searchBar(),
                      ],
                    );
                  },
                ),
              ],

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 16),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: _load, child: const Text('Retry')),
                  ],
                )
              else if (shown.isEmpty)
                const Text('No receipts found.', style: TextStyle(color: Colors.black54))
              else
              if (_listView) ...[
                // LIST VIEW
                ...shown.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _receiptListRow(
                    receipt: r,
                    projectName: nameById[r.projectId] ?? 'Project',
                    onView: () => _openReceiptImage(r),
                    onEdit: () => _openEditReceipt(r),
                    onDelete: () => _deleteReceipt(r),
                  ),
                )),
              ] else ...[
                // GRID/CARD VIEW (your existing UI)
                ...shown.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _receiptWebsiteCard(
                    receipt: r,
                    projectName: nameById[r.projectId] ?? 'Project',
                    onView: () => _openReceiptImage(r),
                    onEdit: () => _openEditReceipt(r),
                    onDelete: () => _deleteReceipt(r),
                  ),
                )),
              ]
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _receiptWebsiteCard({
    required ReceiptItem receipt,
    required String projectName,
    required VoidCallback onView,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final cached = _detailsCache[receipt.id];

    // If processed and not cached yet, fetch silently
    if (receipt.status.trim().toUpperCase() == 'PROCESSED' && cached == null) {
      _ensureDetails(receipt.id);
    }

    final d = cached;
    final vendor = (d?.vendorName?.trim().isNotEmpty ?? false)
        ? d!.vendorName!.trim()
        : (receipt.name.trim().isNotEmpty ? receipt.name : 'Receipt');

    final category = d?.category ?? '—';
    final date = d?.transactionDate ?? receipt.createdAtLabel;
    final cur = d?.currency ?? receipt.currency ?? '';
    final rate = d?.exchangeRateToUsd;
    final orig = d?.totalAmount;
    final usd = d?.totalUsd;
    final imgUrl = d?.downloadUrl;

    final isProcessed = receipt.status.trim().toUpperCase() == 'PROCESSED';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Color(0x11000000),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top image preview (like website)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imgUrl != null && imgUrl.trim().isNotEmpty)
                    Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF3F4F6)),
                      loadingBuilder: (context, child, prog) {
                        if (prog == null) return child;
                        return Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      },
                    )
                  else
                    Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Center(child: Icon(Icons.receipt_long, size: 40)),
                    ),

                  // PROCESSED badge
                  if (isProcessed)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'PROCESSED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ),
                    ),

                  // USD overlay (like website)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usd == null ? 'USD —' : 'USD ${usd.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                          ),
                        ),
                        if (orig != null && cur.isNotEmpty)
                          Text(
                            'Orig: ${orig.toStringAsFixed(2)} $cur',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details section
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projectName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  vendor,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _miniField('RECEIPT DATE', date.isEmpty ? '—' : date)),
                    const SizedBox(width: 12),
                    Expanded(child: _miniField('CATEGORY', category)),
                  ],
                ),

                const SizedBox(height: 12),

                _miniField(
                  'EXCHANGE RATE',
                  (rate == null || cur.isEmpty) ? '—' : 'Rate: 1 $cur = ${rate.toStringAsFixed(4)} USD',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Bottom actions: Edit / Delete + View (eye)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'View image',
                  icon: const Icon(Icons.remove_red_eye),
                  onPressed: onView,
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _miniField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black45,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Color(0x11000000),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _q = v),
              decoration: const InputDecoration(
                hintText: 'Search receipts by vendor or text...',
                border: InputBorder.none,
              ),
            ),
          ),
          if (_q.trim().isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              onPressed: () {
                _search.clear();
                setState(() => _q = '');
              },
              icon: const Icon(Icons.close, color: Colors.black45),
            ),
        ],
      ),
    );
  }
  
  Widget _viewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Grid view',
            onPressed: () => setState(() => _listView = false),
            icon: Icon(
              Icons.grid_view_rounded,
              color: _listView ? Colors.black45 : const Color(0xFF2563EB),
            ),
          ),
          IconButton(
            tooltip: 'List view',
            onPressed: () => setState(() => _listView = true),
            icon: Icon(
              Icons.view_list_rounded,
              color: _listView ? const Color(0xFF2563EB) : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _receiptListRow({
    required ReceiptItem receipt,
    required String projectName,
    required VoidCallback onView,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final cached = _detailsCache[receipt.id];
    if (receipt.status.trim().toUpperCase() == 'PROCESSED' && cached == null) {
      _ensureDetails(receipt.id); // silent fetch
    }

    final d = cached;

    final vendor = (d?.vendorName?.trim().isNotEmpty ?? false)
        ? d!.vendorName!.trim()
        : (receipt.name.trim().isNotEmpty ? receipt.name : 'Receipt');

    final category = d?.category ?? '—';
    final date = d?.transactionDate ?? receipt.createdAtLabel;
    final cur = d?.currency ?? receipt.currency ?? '';
    final orig = d?.totalAmount ?? receipt.totalAmount;
    final usd = d?.totalUsd;

    final isProcessed = receipt.status.trim().toUpperCase() == 'PROCESSED';
    final thumbUrl = d?.downloadUrl;

    Widget statusPill() {
      final bg = isProcessed ? const Color(0xFFD1FAE5) : const Color(0xFFEFF6FF);
      final fg = isProcessed ? const Color(0xFF065F46) : const Color(0xFF1D4ED8);
      final label = isProcessed ? 'PROCESSED' : receipt.status.toUpperCase();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: fg),
        ),
      );
    }

    Widget amountBlock({bool compact = false}) {
      final usdText = usd == null ? 'USD —' : 'USD ${usd.toStringAsFixed(2)}';
      final origText =
          (orig != null && cur.isNotEmpty) ? '${orig.toStringAsFixed(2)} $cur' : '';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            usdText,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (origText.isNotEmpty)
            Text(
              origText,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      );
    }

    Widget categoryChip() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          category.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(blurRadius: 12, offset: Offset(0, 6), color: Color(0x11000000)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final isNarrow = w < 520;         // phones
          final isWide = w > 900;           // big desktop

          final thumb = ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 54,
              height: 54,
              color: const Color(0xFFF3F4F6),
              child: (thumbUrl != null && thumbUrl.trim().isNotEmpty)
                  ? Image.network(
                      thumbUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.receipt_long),
                    )
                  : const Icon(Icons.receipt_long),
            ),
          );

          final vendorBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                projectName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                vendor,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isNarrow) ...[
                const SizedBox(height: 4),
                Text(
                  date.isEmpty ? '—' : date,
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          );

          // ✅ Mobile layout: 2 rows (prevents squeezing => no vertical USD text)
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    thumb,
                    const SizedBox(width: 12),
                    Expanded(child: vendorBlock),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120, // reserve space so USD never collapses
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: amountBlock(compact: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    statusPill(),
                    const SizedBox(width: 10),
                    Flexible(child: categoryChip()),
                    const Spacer(),
                    IconButton(
                      tooltip: 'View',
                      onPressed: onView,
                      icon: const Icon(Icons.remove_red_eye),
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ],
            );
          }

          // ✅ Desktop layout (table-ish)
          return Row(
            children: [
              thumb,
              const SizedBox(width: 12),

              Expanded(flex: 3, child: vendorBlock),

              const SizedBox(width: 12),

              if (isWide)
                Expanded(
                  flex: 2,
                  child: Text(
                    date.isEmpty ? '—' : date,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              if (isWide) const SizedBox(width: 12),
              if (isWide) categoryChip(),
              if (isWide) const SizedBox(width: 12),

              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: amountBlock(),
                ),
              ),

              const SizedBox(width: 12),
              statusPill(),
              const SizedBox(width: 10),

              IconButton(tooltip: 'View', onPressed: onView, icon: const Icon(Icons.remove_red_eye)),
              IconButton(tooltip: 'Edit', onPressed: onEdit, icon: const Icon(Icons.edit)),
              IconButton(tooltip: 'Delete', onPressed: onDelete, icon: const Icon(Icons.delete, color: Colors.red)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteReceipt(ReceiptItem r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete receipt?'),
        content: Text('Are you sure you want to delete "${r.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _opening = true);
    try {
      await DocRizzApi.deleteReceipt(id: r.id);

      if (!mounted) return;

      // remove locally so UI updates instantly
      setState(() {
        _receipts.removeWhere((x) => x.id == r.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete receipt: $e')),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }
  
  
  Future<ReceiptDetails?> _ensureDetails(String receiptId) async {
    if (_detailsCache.containsKey(receiptId)) return _detailsCache[receiptId];
    if (_detailsLoading.contains(receiptId)) return null;

    _detailsLoading.add(receiptId);
    try {
      final d = await DocRizzApi.getReceiptDetails(id: receiptId);
      if (!mounted) return null;
      setState(() => _detailsCache[receiptId] = d);
      return d;
    } catch (_) {
      return null;
    } finally {
      _detailsLoading.remove(receiptId);
    }
  }
  
  Future<void> _openReceiptImage(ReceiptItem r) async {
    setState(() => _opening = true);
    try {
      final details = await DocRizzApi.getReceiptDetails(id: r.id);
      if (!mounted) return;

      final url = details.downloadUrl;
      if (url == null || url.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file available yet')),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceiptViewerScreen(
            url: url,
            title: details.vendorName ?? r.name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open receipt: $e')),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }
  
  Future<void> _openEditReceipt(ReceiptItem r) async {
    setState(() => _opening = true);
    ReceiptDetails? d;
    try {
      d = await DocRizzApi.getReceiptDetails(id: r.id);
    } finally {
      if (mounted) setState(() => _opening = false);
    }

    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => EditReceiptDialog(details: d!),
    );

    if (changed == true) {
      // refresh list + cache
      await _load();
      _detailsCache.remove(r.id);
      _ensureDetails(r.id);
    }
  }
  
  Map<String, String> _projectNameById() {
    final m = <String, String>{};
    for (final p in _projects) {
      m[p.id] = p.name;
    }
    return m;
  }
}

/// ========================
/// VIEW (Project Details) -> Receipts list for one project
/// ========================
class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final String projectColor;

  const ProjectDetailsScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.projectColor,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  bool _loading = true;
  bool _opening = false;
  String? _error;
  List<ReceiptItem> _receipts = [];
  final Map<String, ReceiptDetails> _detailsCache = {};
  final Set<String> _detailsLoading = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final all = await DocRizzApi.getReceipts();
      final filtered = all.where((r) => r.projectId == widget.projectId).toList();

      if (!mounted) return;
      setState(() => _receipts = filtered);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _parseHex(String hex) {
    var h = hex.trim();
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = _parseHex(widget.projectColor);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(widget.projectName),
        backgroundColor: headerColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              )
            else ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Receipts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (_opening)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_receipts.isEmpty)
                const Text(
                  'No receipts found for this project.',
                  style: TextStyle(color: Colors.black54),
                )
              else
              ..._receipts.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _receiptWebsiteCard(
                  receipt: r,
                  projectName: widget.projectName,
                  onView: () => _openReceiptImage(r),
                  onEdit: () => _openEditReceipt(r),
                  onDelete: () => _deleteReceipt(r),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReceipt(ReceiptItem r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete receipt?'),
        content: Text('Are you sure you want to delete "${r.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _opening = true);
    try {
      await DocRizzApi.deleteReceipt(id: r.id);

      if (!mounted) return;

      // remove from this project's list
      setState(() {
        _receipts.removeWhere((x) => x.id == r.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete receipt: $e')),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }
  
  Widget _receiptWebsiteCard({
    required ReceiptItem receipt,
    required String projectName,
    required VoidCallback onView,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final cached = _detailsCache[receipt.id];

    // If processed and not cached yet, fetch silently
    if (receipt.status.trim().toUpperCase() == 'PROCESSED' && cached == null) {
      _ensureDetails(receipt.id);
    }

    final d = cached;
    final vendor = (d?.vendorName?.trim().isNotEmpty ?? false)
        ? d!.vendorName!.trim()
        : (receipt.name.trim().isNotEmpty ? receipt.name : 'Receipt');

    final category = d?.category ?? '—';
    final date = d?.transactionDate ?? receipt.createdAtLabel;
    final cur = d?.currency ?? receipt.currency ?? '';
    final rate = d?.exchangeRateToUsd;
    final orig = d?.totalAmount;
    final usd = d?.totalUsd;
    final imgUrl = d?.downloadUrl;

    final isProcessed = receipt.status.trim().toUpperCase() == 'PROCESSED';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Color(0x11000000),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top image preview (like website)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imgUrl != null && imgUrl.trim().isNotEmpty)
                    Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF3F4F6)),
                      loadingBuilder: (context, child, prog) {
                        if (prog == null) return child;
                        return Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      },
                    )
                  else
                    Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Center(child: Icon(Icons.receipt_long, size: 40)),
                    ),

                  // PROCESSED badge
                  if (isProcessed)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'PROCESSED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ),
                    ),

                  // USD overlay (like website)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usd == null ? 'USD —' : 'USD ${usd.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                          ),
                        ),
                        if (orig != null && cur.isNotEmpty)
                          Text(
                            'Orig: ${orig.toStringAsFixed(2)} $cur',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details section
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projectName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  vendor,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _miniField('RECEIPT DATE', date.isEmpty ? '—' : date)),
                    const SizedBox(width: 12),
                    Expanded(child: _miniField('CATEGORY', category)),
                  ],
                ),

                const SizedBox(height: 12),

                _miniField(
                  'EXCHANGE RATE',
                  (rate == null || cur.isEmpty) ? '—' : 'Rate: 1 $cur = ${rate.toStringAsFixed(4)} USD',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Bottom actions: Edit / Delete + View (eye)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'View image',
                  icon: const Icon(Icons.remove_red_eye),
                  onPressed: onView,
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black45,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }


  Future<ReceiptDetails?> _ensureDetails(String receiptId) async {
    if (_detailsCache.containsKey(receiptId)) return _detailsCache[receiptId];
    if (_detailsLoading.contains(receiptId)) return null;

    _detailsLoading.add(receiptId);
    try {
      final d = await DocRizzApi.getReceiptDetails(id: receiptId);
      if (!mounted) return null;
      setState(() => _detailsCache[receiptId] = d);
      return d;
    } catch (_) {
      return null;
    } finally {
      _detailsLoading.remove(receiptId);
    }
  }
  
  Future<void> _openReceiptImage(ReceiptItem r) async {
    setState(() => _opening = true);
    try {
      final details = await DocRizzApi.getReceiptDetails(id: r.id);
      if (!mounted) return;

      final url = details.downloadUrl;
      if (url == null || url.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file available yet')),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceiptViewerScreen(
            url: url,
            title: details.vendorName ?? r.name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open receipt: $e')),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }
  
  Future<void> _openEditReceipt(ReceiptItem r) async {
    setState(() => _opening = true);
    ReceiptDetails? d;
    try {
      d = await DocRizzApi.getReceiptDetails(id: r.id);
    } finally {
      if (mounted) setState(() => _opening = false);
    }

    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => EditReceiptDialog(details: d!),
    );

    if (changed == true) {
      // refresh list + cache
      await _load();
      _detailsCache.remove(r.id);
      _ensureDetails(r.id);
    }
  }
}

/// ========================
/// DIALOGS (Create / Edit Projects)
/// ========================
class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _name = TextEditingController(text: 'Documentation App');
  bool _saving = false;
  
  final _rng = Random();
  
  // same palette you show as dots
  final List<Color> _palette = const [
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF111827),
  ];
  
  late Color _selected;

  @override
  void initState() {
    super.initState();
    _selected = _palette[_rng.nextInt(_palette.length)]; // ✅ random on open
  }

    @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) {
    return '#'
        '${c.red.toRadixString(16).padLeft(2, '0')}'
        '${c.green.toRadixString(16).padLeft(2, '0')}'
        '${c.blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project name is required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final hex = _colorToHex(_selected);

      await DocRizzApi.createProject(
        projectName: name,
        projectColorHex: hex,
      );

      if (!mounted) return;
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project created')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create project: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final dialogWidth = w < 520 ? w - 32.0 : 520.0;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: dialogWidth,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create New Project',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              const Text(
                'Project Name',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  hintText: 'Documentation App',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Project Color',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _selected,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _colorDot(const Color(0xFF2563EB)),
                  _colorDot(const Color(0xFF16A34A)),
                  _colorDot(const Color(0xFFF59E0B)),
                  _colorDot(const Color(0xFFEF4444)),
                  _colorDot(const Color(0xFF8B5CF6)),
                  _colorDot(const Color(0xFF111827)),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Save Project',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorDot(Color c) {
    final selected = c.value == _selected.value;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _selected = c),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

class EditProjectDialog extends StatefulWidget {
  final Project project;
  const EditProjectDialog({super.key, required this.project});

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  late final TextEditingController _name;
  bool _saving = false;
  bool _deleting = false;

  late Color _selected;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.project.name);
    _selected = _parseHex(widget.project.color);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    var h = hex.trim();
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  String _colorToHex(Color c) {
    return '#'
        '${c.red.toRadixString(16).padLeft(2, '0')}'
        '${c.green.toRadixString(16).padLeft(2, '0')}'
        '${c.blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project name is required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await DocRizzApi.updateProject(
        id: widget.project.id,
        projectName: name,
        projectColorHex: _colorToHex(_selected),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update project: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text('Are you sure you want to delete "${widget.project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      await DocRizzApi.deleteProject(id: widget.project.id);

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete project: $e')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final dialogWidth = w < 520 ? w - 32.0 : 520.0;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: dialogWidth,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit Project',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              const Text(
                'Project Name',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Project Color',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _selected,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _colorDot(const Color(0xFF2563EB)),
                  _colorDot(const Color(0xFF16A34A)),
                  _colorDot(const Color(0xFFF59E0B)),
                  _colorDot(const Color(0xFFEF4444)),
                  _colorDot(const Color(0xFF8B5CF6)),
                  _colorDot(const Color(0xFF111827)),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: (_saving || _deleting) ? null : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: (_saving || _deleting) ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Save Project',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: (_saving || _deleting) ? null : _delete,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: _deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Delete Project',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorDot(Color c) {
    final selected = c.value == _selected.value;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _selected = c),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

/// ========================
/// MODELS
/// ========================
class Project {
  final String id;
  final String name;
  final String color;

  Project({required this.id, required this.name, required this.color});

  factory Project.fromJson(Map<String, dynamic> j) {
    return Project(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      color: (j['color'] ?? '#2563EB').toString(),
    );
  }
}

class ReceiptItem {
  final String id;
  final String name;
  final String status;
  final String createdAtLabel;
  final String projectId;

  // ✅ NEW (optional from list endpoint)
  final double? totalAmount;
  final String? currency;

  ReceiptItem({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAtLabel,
    required this.projectId,
    this.totalAmount,
    this.currency,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> j) {
    final created =
        (j['createdAt'] ?? j['created_at'] ?? j['date'] ?? j['uploadedAt'])
            ?.toString();

    final pid = (j['projectId'] ??
            j['project_id'] ??
            (j['project'] is Map ? (j['project'] as Map)['id'] : null) ??
            '')
        .toString();

    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return ReceiptItem(
      id: (j['id'] ?? '').toString(),
      name: (j['vendorName'] ?? j['vendor_name'] ?? j['name'] ?? j['fileName'] ?? j['title'] ?? 'Receipt').toString(),
      status: (j['status'] ?? 'UPLOADED').toString(),
      createdAtLabel: (created == null || created.isEmpty) ? '' : created,
      projectId: pid,
      totalAmount: toDouble(j['totalAmount'] ?? j['total_amount']),
      currency: (j['currency'])?.toString(),
    );
  }
}

class ReceiptDetails {
  final int id;
  final int projectId;
  final String status;

  final String? vendorName;
  final String? category;
  final String? currency;

  final double? totalAmount;           // original total in currency
  final double? exchangeRateToUsd;     // 1 currency = X USD
  final double? taxAmount;

  final String? transactionDate;
  final String? createdAt;

  final String? downloadUrl;
  final String? urlExpiresAt;
  final String? errorMessage;

  ReceiptDetails({
    required this.id,
    required this.projectId,
    required this.status,
    required this.vendorName,
    required this.category,
    required this.currency,
    required this.totalAmount,
    required this.exchangeRateToUsd,
    required this.taxAmount,
    required this.transactionDate,
    required this.createdAt,
    required this.downloadUrl,
    required this.urlExpiresAt,
    required this.errorMessage,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static String? _toStr(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory ReceiptDetails.fromJson(Map<String, dynamic> j) {
    return ReceiptDetails(
      id: _toInt(j['id']),
      projectId: _toInt(j['projectId']),
      status: (j['status'] ?? '').toString(),

      vendorName: _toStr(j['vendorName']),
      category: _toStr(j['category']),
      currency: _toStr(j['currency']),

      totalAmount: _toDouble(j['totalAmount']),
      exchangeRateToUsd: _toDouble(j['exchangeRateToUsd']),
      taxAmount: _toDouble(j['taxAmount']),

      transactionDate: _toStr(j['transactionDate']),
      createdAt: _toStr(j['createdAt']),

      downloadUrl: _toStr(j['downloadUrl']),
      urlExpiresAt: _toStr(j['urlExpiresAt']),
      errorMessage: _toStr(j['errorMessage']),
    );
  }

  bool get isProcessed => status.trim().toUpperCase() == 'PROCESSED';

  double? get totalUsd {
    if (totalAmount == null || exchangeRateToUsd == null) return null;
    return totalAmount! * exchangeRateToUsd!;
  }
}

/// ========================
/// API
/// ========================
class DocRizzApi {
  static const String _projectsEndpoint = 'https://docrizz.com/api/v1/projects';
  static const String _receiptsEndpoint = 'https://docrizz.com/api/v1/receipts';

  static Future<String> _bearer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');
    final idToken = await user.getIdToken();
    return 'Bearer $idToken';
  }

  static Future<void> createProject({
    required String projectName,
    required String projectColorHex,
  }) async {
    final bearer = await _bearer();

    final res = await http.post(
      Uri.parse(_projectsEndpoint),
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': bearer,
      },
      body: jsonEncode({
        'color': projectColorHex,
        'name': projectName,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  static Future<List<Project>> getProjects() async {
    final bearer = await _bearer();

    final res = await http.get(
      Uri.parse(_projectsEndpoint),
      headers: {
        'accept': 'application/json',
        'Authorization': bearer,
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    if (decoded is List) {
      return decoded.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (decoded is Map && decoded['projects'] is List) {
      return (decoded['projects'] as List)
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (decoded is Map && decoded['items'] is List) {
      return (decoded['items'] as List)
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Unexpected response: ${res.body}');
  }

  static Future<List<ReceiptItem>> getReceipts() async {
    final bearer = await _bearer();

    final res = await http.get(
      Uri.parse(_receiptsEndpoint),
      headers: {
        'accept': 'application/json',
        'Authorization': bearer,
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    if (decoded is List) {
      return decoded.map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (decoded is Map && decoded['items'] is List) {
      return (decoded['items'] as List)
          .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (decoded is Map && decoded['receipts'] is List) {
      return (decoded['receipts'] as List)
          .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Unexpected response: ${res.body}');
  }
  
  static Future<ReceiptDetails> getReceiptDetails({required String id}) async {
    final bearer = await _bearer();

    final res = await http.get(
      Uri.parse('$_receiptsEndpoint/$id'),
      headers: {
        'accept': 'application/json',
        'Authorization': bearer,
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return ReceiptDetails.fromJson(decoded);
    if (decoded is Map) return ReceiptDetails.fromJson(decoded.cast<String, dynamic>());

    throw Exception('Unexpected response: ${res.body}');
  }

  static Future<void> updateProject({
    required String id,
    required String projectName,
    required String projectColorHex,
  }) async {
    final bearer = await _bearer();

    final res = await http.put(
      Uri.parse('$_projectsEndpoint/$id'),
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': bearer,
      },
      body: jsonEncode({
        'color': projectColorHex,
        'name': projectName,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  static Future<void> deleteProject({required String id}) async {
    final bearer = await _bearer();

    final res = await http.delete(
      Uri.parse('$_projectsEndpoint/$id'),
      headers: {
        'accept': 'application/json',
        'Authorization': bearer,
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  static Future<Uint8List> downloadFileBytes(String fileUrl) async {
    final bearer = await _bearer();

    final res = await http.get(
      Uri.parse(fileUrl),
      headers: {
        'Authorization': bearer,
        'accept': '*/*',
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    return res.bodyBytes;
  }

  static Future<Uint8List> downloadImageBytes(String url) async {
    final uri = Uri.parse(url);

    // If it's an AWS pre-signed URL, DO NOT send Authorization header.
    final looksPresigned =
        uri.queryParameters.keys.any((k) => k.toLowerCase().startsWith('x-amz-')) ||
        url.contains('X-Amz-') ||
        (uri.host.contains('amazonaws.com') || uri.host.contains('cloudfront.net'));

    http.Response res;

    if (looksPresigned) {
      res = await http.get(uri); // ✅ no headers
    } else {
      // Try with bearer for non-S3 protected endpoints
      final bearer = await _bearer();
      res = await http.get(
        uri,
        headers: {
          'accept': '*/*',
          'Authorization': bearer,
        },
      );
    }

    // If we got an XML error page, show it clearly
    final ct = (res.headers['content-type'] ?? '').toLowerCase();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    if (ct.contains('xml') || ct.contains('text')) {
      // Sometimes S3 sends XML error with 200 in rare proxy cases, so guard anyway
      if (res.bodyBytes.isNotEmpty && res.body.startsWith('<?xml')) {
        throw Exception('Received XML error instead of image: ${res.body}');
      }
    }

    return res.bodyBytes;
  }

  static Future<void> deleteReceipt({required String id}) async {
      final bearer = await _bearer();

      final res = await http.delete(
        Uri.parse('$_receiptsEndpoint/$id'),
        headers: {
          'accept': 'application/json',
          'Authorization': bearer,
        },
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
  }
  
  static Future<UploadUrlResponse> getReceiptUploadUrl({
    required String projectId,
    required String contentType,
  }) async {
    final bearer = await _bearer();

    final res = await http.post(
      Uri.parse('$_receiptsEndpoint/upload-url'),
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': bearer,
      },
      body: jsonEncode({
        'contentType': contentType,
        'projectId': int.tryParse(projectId) ?? projectId, // supports int or string IDs
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return UploadUrlResponse.fromJson(decoded);
    if (decoded is Map) return UploadUrlResponse.fromJson(decoded.cast<String, dynamic>());

    throw Exception('Unexpected response: ${res.body}');
  }

  /// Upload bytes to the presigned URL (most commonly PUT to S3)
  static Future<void> uploadBytesToPresignedUrl({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final res = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': contentType,
      },
      body: bytes,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Upload failed HTTP ${res.statusCode}: ${res.body}');
    }
  }

  static Future<ReceiptDetails> confirmReceipt({required String receiptId}) async {
    // Some backends require auth; some don't. We'll include it safely.
    String? bearer;
    try {
      bearer = await _bearer();
    } catch (_) {
      bearer = null;
    }

    final headers = <String, String>{
      'accept': 'application/json',
      if (bearer != null) 'Authorization': bearer,
    };

    final res = await http.post(
      Uri.parse('$_receiptsEndpoint/$receiptId/confirm'),
      headers: headers,
      body: '', // curl shows empty body
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Confirm failed HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return ReceiptDetails.fromJson(decoded);
    if (decoded is Map) return ReceiptDetails.fromJson(decoded.cast<String, dynamic>());

    throw Exception('Unexpected confirm response: ${res.body}');
  }
  
  static Future<ReceiptDetails> updateReceipt({
    required String id,
    required String vendorName,
    required String category,
    required String currency,
    required double totalAmount,
    required double taxAmount,
    required double exchangeRateToUsd,
    required String transactionDate, // ISO string
  }) async {
    final bearer = await _bearer();

    final res = await http.put(
      Uri.parse('$_receiptsEndpoint/$id'),
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': bearer,
      },
      body: jsonEncode({
        "vendorName": vendorName,
        "category": category,
        "currency": currency,
        "totalAmount": totalAmount,
        "taxAmount": taxAmount,
        "exchangeRateToUsd": exchangeRateToUsd,
        "transactionDate": transactionDate,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return ReceiptDetails.fromJson(decoded);
    if (decoded is Map) return ReceiptDetails.fromJson(decoded.cast<String, dynamic>());
    throw Exception('Unexpected response: ${res.body}');
  }
}

class ReceiptImageViewerScreen extends StatefulWidget {
  final String imageUrl;
  final String title;

  const ReceiptImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  State<ReceiptImageViewerScreen> createState() => _ReceiptImageViewerScreenState();
}

class _ReceiptImageViewerScreenState extends State<ReceiptImageViewerScreen> {
  Uint8List? _bytes;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  Future<void> _loadBytes() async {
    setState(() {
      _loading = true;
      _error = null;
      _bytes = null;
    });

    try {
      final bytes = await DocRizzApi.downloadFileBytes(widget.imageUrl);
      if (!mounted) return;
      setState(() => _bytes = bytes);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: _loading ? null : _loadBytes,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadBytes, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _bytes == null
                  ? const Center(child: Text('No image to display.'))
                  : InteractiveViewer(
                      minScale: 1,
                      maxScale: 6,
                      child: Center(
                        child: Image.memory(
                          _bytes!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Text('Could not decode image bytes.'),
                        ),
                      ),
                    ),
    );
  }
}

class ReceiptViewerScreen extends StatelessWidget {
  final String url;
  final String title;

  const ReceiptViewerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator();
            },
            errorBuilder: (_, __, ___) {
              return const Text('Failed to load image');
            },
          ),
        ),
      ),
    );
  }
}

class UploadUrlResponse {
  final String uploadUrl;
  final String receiptId; // REQUIRED for confirm

  UploadUrlResponse({
    required this.uploadUrl,
    required this.receiptId,
  });

  factory UploadUrlResponse.fromJson(Map<String, dynamic> j) {
    final url = (j['uploadUrl'] ?? j['upload_url'] ?? j['url'] ?? '').toString();

    // try common keys for receipt id
    final rid = (j['receiptId'] ??
            j['receipt_id'] ??
            j['id'] ??
            j['receipt']?['id'])
        ?.toString();

    if (url.isEmpty) throw Exception('uploadUrl missing from upload-url response');
    if (rid == null || rid.isEmpty) {
      throw Exception('receiptId missing from upload-url response (needed for confirm)');
    }

    return UploadUrlResponse(uploadUrl: url, receiptId: rid);
  }
}

class ReceiptProcessedDetailsScreen extends StatelessWidget {
  final ReceiptDetails details;

  const ReceiptProcessedDetailsScreen({super.key, required this.details});

  String _fmtMoney(double? v) {
    if (v == null) return '—';
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final vendor = details.vendorName ?? 'Unknown Vendor';
    final cat = details.category ?? '—';
    final cur = details.currency ?? '';
    final orig = details.totalAmount;
    final rate = details.exchangeRateToUsd;
    final usd = details.totalUsd;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(vendor, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status badge
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'PROCESSED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF065F46),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Main card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 12,
                  offset: Offset(0, 6),
                  color: Color(0x11000000),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),

                _row('CATEGORY', cat),
                const SizedBox(height: 10),

                _row('TOTAL (USD)', usd == null ? '—' : 'USD ${_fmtMoney(usd)}'),
                const SizedBox(height: 10),

                _row(
                  'ORIGINAL TOTAL',
                  orig == null ? '—' : '$cur ${_fmtMoney(orig)}',
                ),
                const SizedBox(height: 10),

                _row(
                  'EXCHANGE RATE',
                  (rate == null || cur.isEmpty) ? '—' : 'Rate: 1 $cur = ${rate.toStringAsFixed(4)} USD',
                ),
                const SizedBox(height: 10),

                _row('RECEIPT DATE', details.transactionDate ?? '—'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String left, String right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            left,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Expanded(
          child: Text(
            right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  String _fullNumber = '';
  bool _loading = false;

  Future<void> _sendCode() async {
    if (_fullNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your phone number')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _fullNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval on Android sometimes works
          final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
          if (!mounted) return;

          final isNew = userCred.additionalUserInfo?.isNewUser ?? false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isNew ? 'Phone registered & signed in' : 'Signed in')),
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
          );
        },
        
        verificationFailed: (FirebaseAuthException e) {
          final msg = (e.message ?? e.code).toLowerCase();

          if (msg.contains('blocked') || msg.contains('unusual activity')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Phone verification blocked on this device. Try a real phone, change network, or use Firebase test numbers.',
                ),
              ),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? e.code)),
          );
        },

        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpVerifyScreen(
                phoneNumber: _fullNumber,
                verificationId: verificationId,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Sign in with phone')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Phone number',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),

                  // ✅ looks like your screenshot (flag + country code + number)
                  IntlPhoneField(
                    initialCountryCode: 'US',
                    decoration: InputDecoration(
                      hintText: '1234567890',
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (phone) {
                      _fullNumber = phone.completeNumber; // ex: +1XXXXXXXXXX
                    },
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _sendCode,
                      child: _loading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Send code',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OtpVerifyScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpVerifyScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _code = TextEditingController();
  bool _loading = false;

  Future<void> _verify() async {
    final smsCode = _code.text.trim();
    if (smsCode.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the verification code')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(cred);
      if (!mounted) return;

      final isNew = userCred.additionalUserInfo?.isNewUser ?? false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNew ? 'Phone registered & signed in' : 'Signed in')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Verify code')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Code sent to ${widget.phoneNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '123456',
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _verify,
                      child: _loading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Verify & continue',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EditReceiptDialog extends StatefulWidget {
  final ReceiptDetails details;
  const EditReceiptDialog({super.key, required this.details});

  @override
  State<EditReceiptDialog> createState() => _EditReceiptDialogState();
}

class _EditReceiptDialogState extends State<EditReceiptDialog> {
  late final TextEditingController _vendor;
  late final TextEditingController _total;
  late final TextEditingController _currency;
  late final TextEditingController _tax;
  late final TextEditingController _category;
  late final TextEditingController _rate;
  DateTime? _date;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.details;
    _vendor = TextEditingController(text: d.vendorName ?? '');
    _total = TextEditingController(text: (d.totalAmount ?? 0).toString());
    _currency = TextEditingController(text: d.currency ?? '');
    _tax = TextEditingController(text: (d.taxAmount ?? 0).toString());
    _category = TextEditingController(text: d.category ?? '');
    _rate = TextEditingController(text: (d.exchangeRateToUsd ?? 0).toString());

    // try parse date
    if ((d.transactionDate ?? '').trim().isNotEmpty) {
      _date = DateTime.tryParse(d.transactionDate!.trim());
    }
  }

  @override
  void dispose() {
    _vendor.dispose();
    _total.dispose();
    _currency.dispose();
    _tax.dispose();
    _category.dispose();
    _rate.dispose();
    super.dispose();
  }

  double _toD(String s) => double.tryParse(s.trim()) ?? 0;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final init = _date ?? DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: init,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final iso = (_date ?? DateTime.now()).toUtc().toIso8601String();

      await DocRizzApi.updateReceipt(
        id: widget.details.id.toString(),
        vendorName: _vendor.text.trim(),
        category: _category.text.trim(),
        currency: _currency.text.trim(),
        totalAmount: _toD(_total.text),
        taxAmount: _toD(_tax.text),
        exchangeRateToUsd: _toD(_rate.text),
        transactionDate: iso,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, TextEditingController c, {TextInputType? type, Widget? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          keyboardType: type,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Edit Receipt', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  ),
                  IconButton(onPressed: _saving ? null : () => Navigator.pop(context, false), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),

              _field('VENDOR NAME', _vendor),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _field('TOTAL AMOUNT', _total, type: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('CURRENCY', _currency)),
                ],
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _field('TAX AMOUNT', _tax, type: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'DATE',
                      TextEditingController(
                        text: _date == null
                            ? ''
                            : '${_date!.month.toString().padLeft(2, '0')}/${_date!.day.toString().padLeft(2, '0')}/${_date!.year}',
                      ),
                      suffix: IconButton(onPressed: _saving ? null : _pickDate, icon: const Icon(Icons.calendar_month)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _field('CATEGORY', _category),

              const SizedBox(height: 16),
              _field('EXCHANGE RATE (1 CURRENCY = X USD)', _rate, type: TextInputType.number),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}