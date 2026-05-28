// flutter run -d chrome

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://llddhtatznrbrhxoniqc.supabase.co',
    anonKey: 'sb_publishable_48nEIOwcY4KGdg4ClqIC-w_VGsKOXLZ',

    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasHandledLink = false;

  final _appLinks = AppLinks();
  late final StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      _handleDeepLink(uri);
    }

    _sub = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    print("HANDLING DEEPLINK: $uri");

    if (_hasHandledLink) return;
    _hasHandledLink = true;

    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      print("Session restored");
    } catch (e) {
      print("Auth error: $e");
    }

    final path = uri.path.replaceAll("/", "");

    if (uri.scheme == "feather" && path == "login-callback") {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => ResetPasswordPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(navigatorKey: navigatorKey, home: LoginPage());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// -------------------------- Home Page -------------------------- \\
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> callAPI() async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'bird-api',
        headers: {'Content-Type': 'application/json'},
        body: {},
      );

      print(response.data);
      print(response.status);
    } catch (e) {
      print("ERROR: $e");
    }
  }

  Future<void> testDB() async {
    final supabase = Supabase.instance.client;

    final user = supabase.auth.currentUser;

    if (user == null) {
      print("No logged-in user");
      return;
    }

    try {
      final response = await supabase
          .from('bird_sightings')
          .select()
          .eq('user_id', user.id);

      print("TABLE: bird_sightings");
      print(response);
    } catch (e) {
      print("Connection failed: $e");
    }
  }

  Future<void> getBirds() async {
    final response = await http.get(Uri.parse("http://127.0.0.1:8000/birds"));

    final data = jsonDecode(response.body);

    print(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Feather")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: callAPI, child: const Text("Call API")),
            ElevatedButton(onPressed: testDB, child: const Text("Test DB")),
            ElevatedButton(onPressed: getBirds, child: const Text("getBirds")),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              },
              child: const Text("Go to Login"),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordRequirementField extends StatelessWidget {
  const PasswordRequirementField({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Password requirements:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text("• At least 8 characters"),
        Text("• One uppercase letter"),
        Text("• One number"),
        Text("• One special character"),
      ],
    );
  }
}

// -------------------------- Nav Bar -------------------------- \\

class MainLayout extends StatefulWidget {
  final int initialIndex;

  const MainLayout({this.initialIndex = 0});

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;

  final List<Widget> _pages = [
    DashboardPage(),
    DeviceSpecsPage(),
    SearchPage(),
    SightingsPage(),
    HudPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        indicatorColor: _selectedIndex == 0
            ? Color(0xFFA9C1A0)
            : _selectedIndex == 1
            ? Color(0xFF6F7C5A).withOpacity(0.25)
            : _selectedIndex == 2
            ? Color(0xFFE6DFD3)
            : _selectedIndex == 3
            ? Color(0xFFAFC9dA)
            : _selectedIndex == 4
            ? Color(0xFFC2A991)
            : Colors.green.withOpacity(0.25),

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.center_focus_weak),
            selectedIcon: Icon(Icons.center_focus_strong),
            label: '',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: ''),
          NavigationDestination(icon: Icon(Icons.history), label: ''),
          NavigationDestination(icon: Icon(Icons.tune), label: ''),
        ],
      ),
    );
  }
}

// -------------------------- Landing Page -------------------------- \\

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Stack(children: [BackgroundImage(), LoginForm()]));
  }
}

class BackgroundImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.3),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 350),
        child: Image.asset("assets/images/logo.png", width: 400),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> login() async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainLayout()),
      );
    } catch (e) {
      final message = "Email or password does not match";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );

      print("FULL ERROR: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(0, 0.6),
      child: Padding(
        padding: EdgeInsets.only(bottom: 100, left: 20, right: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.all(20),
              color: Colors.white.withValues(alpha: 0.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UsernameField(controller: emailController),

                  SizedBox(height: 20),

                  PasswordField(controller: passwordController),

                  SizedBox(height: 20),

                  ElevatedButton(onPressed: login, child: Text("Login")),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UsernameField extends StatelessWidget {
  final TextEditingController controller;

  const UsernameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Email",
            filled: true,
            fillColor: Colors.grey[300],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: Icon(Icons.close),
          ),
        ),

        SizedBox(height: 5),

        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NewUserPage()),
            );
          },
          child: Text(
            "New User?",
            style: TextStyle(
              color: Color.fromARGB(255, 118, 111, 102),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

class PasswordField extends StatelessWidget {
  final TextEditingController controller;

  const PasswordField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "Password",
            filled: true,
            fillColor: Colors.grey[300],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: Icon(Icons.close),
          ),
        ),

        SizedBox(height: 5),

        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EmailRecoveryPage()),
            );
          },
          child: Text(
            "Forgot Password?",
            style: TextStyle(
              color: Color.fromARGB(255, 118, 111, 102),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

// -------------------------- Email Recovery Page -------------------------- \\

class EmailRecoveryPage extends StatefulWidget {
  @override
  State<EmailRecoveryPage> createState() => _EmailRecoveryPageState();
}

class _EmailRecoveryPageState extends State<EmailRecoveryPage> {
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;
  int cooldown = 0;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void startCooldown() {
    setState(() {
      cooldown = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return false;

      if (cooldown == 0) return false;

      setState(() {
        cooldown--;
      });

      return cooldown > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BackgroundImage(),

          Align(
            alignment: const Alignment(0, 0.6),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white.withValues(alpha: 0.5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmailField(controller: emailController),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginPage(),
                                  ),
                                );
                              },
                              child: const Text("Back to Login"),
                            ),

                            ElevatedButton(
                              onPressed: (isLoading || cooldown > 0)
                                  ? null
                                  : () async {
                                      final email = emailController.text.trim();

                                      if (email.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("Enter your email"),
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() {
                                        isLoading = true;
                                      });

                                      try {
                                        await Supabase.instance.client.auth
                                            .resetPasswordForEmail(
                                              emailController.text.trim(),
                                              redirectTo:
                                                  'feather://login-callback/',
                                            );

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("Reset email sent"),
                                          ),
                                        );

                                        startCooldown();
                                      } on AuthException catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(e.message)),
                                        );
                                      } finally {
                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    },
                              child: Text(
                                cooldown > 0
                                    ? "Wait ${cooldown}s"
                                    : (isLoading
                                          ? "Sending..."
                                          : "Send Reset Link"),
                              ),
                            ),
                          ],
                        ),
                      ],
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

class EmailField extends StatelessWidget {
  final TextEditingController controller;
  const EmailField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: "Email",
        filled: true,
        fillColor: Colors.grey[300],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: Icon(Icons.email),
      ),
    );
  }
}

// -------------------------- Forgot Password -------------------------- \\

class ResetPasswordPage extends StatefulWidget {
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final emailController = TextEditingController();
  final tempCodeController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    tempCodeController.dispose();
    super.dispose();
  }

  Future<void> updatePassword() async {
    final pass = passwordController.text.trim();
    final confirm = confirmController.text.trim();
    final email = emailController.text.trim();
    final tempCode = tempCodeController.text.trim();
    final supabase = Supabase.instance.client;

    // -------------------------
    // BASIC VALIDATION
    // -------------------------
    if (pass != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    final hasMinLength = pass.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(pass);
    final hasNumber = RegExp(r'[0-9]').hasMatch(pass);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass);

    if (!hasMinLength || !hasUppercase || !hasNumber || !hasSpecial) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password does not meet requirements")),
      );
      return;
    }

    try {
      final user = supabase.auth.currentUser;

      // =========================
      // RESET PASSWORD FLOW
      // =========================
      if (user != null) {
        final response = await supabase.auth.updateUser(
          UserAttributes(password: pass),
        );

        if (response.user == null) {
          throw Exception("Password update failed");
        }

        await supabase.auth.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully")),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
        );

        return; // IMPORTANT: stop here
      }

      // =========================
      // NEW ACCOUNT FLOW
      // =========================

      final result = await supabase
          .from('device_codes')
          .select()
          .eq('email', email)
          .eq('temp_code', tempCode)
          .eq('used', false)
          .maybeSingle();

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid activation code")),
        );
        return;
      }

      await supabase.auth.signInWithPassword(email: email, password: tempCode);

      await supabase.auth.updateUser(UserAttributes(password: pass));

      await supabase
          .from('device_codes')
          .update({'used': true, 'used_at': DateTime.now().toIso8601String()})
          .eq('id', result['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created! Please log in.")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BackgroundImage(),

          Align(
            alignment: const Alignment(0, 0.2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 200),
                  PasswordRequirementField(),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        color: Colors.white.withOpacity(0.5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NewPasswordField(controller: passwordController),
                            const SizedBox(height: 20),
                            VerifyNewPasswordField(
                              controller: confirmController,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: updatePassword,
                              child: const Text("Update Password"),
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
        ],
      ),
    );
  }
}
// -------------------------- New User -------------------------- \\

class NewUserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Stack(children: [NewUserPageForm()]));
  }
}

class NewUserPageForm extends StatefulWidget {
  const NewUserPageForm({super.key});

  @override
  State<NewUserPageForm> createState() => _NewUserPageFormState();
}

class _NewUserPageFormState extends State<NewUserPageForm> {
  final emailController = TextEditingController();
  final tempCodeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    emailController.dispose();
    tempCodeController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  bool passwordsMatch() {
    return passwordController.text.trim() == confirmController.text.trim();
  }

  bool isValidPassword(String pass) {
    final hasMinLength = pass.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(pass);
    final hasNumber = RegExp(r'[0-9]').hasMatch(pass);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass);

    return hasMinLength && hasUppercase && hasNumber && hasSpecial;
  }

  Future<void> activateAccount() async {
    final email = emailController.text.trim().toLowerCase();
    final tempCode = tempCodeController.text.trim();
    final newPassword = passwordController.text.trim();

    try {
      // 1. Call secure backend function (IMPORTANT)
      final response = await supabase.functions.invoke(
        'activate_device',
        body: {
          'email': email,
          'temp_code': tempCode,
          'new_password': newPassword,
        },
      );

      if (response.status != 200) {
        throw Exception("Activation failed");
      }

      // 2. Now log user in with new password
      final loginResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: newPassword,
      );

      if (loginResponse.user == null) {
        throw Exception("Login failed after activation");
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account activated successfully")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmailField(controller: emailController),
              const SizedBox(height: 20),
              TempPasswordField(controller: tempCodeController),
              const SizedBox(height: 20),
              NewPasswordField(controller: passwordController),
              const SizedBox(height: 20),
              VerifyNewPasswordField(controller: confirmController),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LoginPage()),
                      );
                    },
                    child: const Text("Back to Login"),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      final pass = passwordController.text.trim();

                      if (!passwordsMatch()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Passwords do not match"),
                          ),
                        );
                        return;
                      }

                      if (!isValidPassword(pass)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Password does not meet requirements",
                            ),
                          ),
                        );
                        return;
                      }

                      await activateAccount();
                    },
                    child: const Text("Activate Account"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TempPasswordField extends StatelessWidget {
  final TextEditingController controller;

  const TempPasswordField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: "Activation Code",
        helperText: "Use the activation code included with your device.",
      ),
    );
  }
}

class NewPasswordField extends StatelessWidget {
  final TextEditingController controller;

  const NewPasswordField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: "New Password",
        helperText: "Please create a new password.",
        filled: true,
        fillColor: Colors.grey[300],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class VerifyNewPasswordField extends StatelessWidget {
  final TextEditingController controller;

  const VerifyNewPasswordField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: "Confirm Password",
        helperText: "Please confirm your new password.",
        filled: true,
        fillColor: Colors.grey[300],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ---------------- DASHBOARD PAGE ----------------
class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? username;

  @override
  void initState() {
    super.initState();
    loadUser(); // 👈 ONLY load data
  }

  Future<void> loadUser() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      print("NO USER LOGGED IN");
      return;
    }

    final data = await Supabase.instance.client
        .from('profiles')
        .select('username')
        .eq('id', user.id)
        .maybeSingle();

    setState(() {
      final value = data?['username'];

      username = (value == null || value.toString().trim().isEmpty)
          ? 'User'
          : value.toString();
    });
  }

  Future<void> updateUsername() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    await Supabase.instance.client
        .from('profiles')
        .update({'username': 'Gracie'})
        .eq('id', user.id);

    await loadUser(); // refresh UI
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 👋 Welcome Text (FIXED LOCATION)
          Positioned(
            top: 20,
            left: 20,
            child: Text(
              "Welcome ${username ?? "..."}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          // 🔋 Battery box
          Positioned(
            top: 70,
            left: 20,
            child: Container(
              width: 170,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFC6C3C3),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.battery_full,
                  size: 100,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // ➕ Top right box
          Positioned(
            top: 70,
            right: 20,
            child: Container(
              width: 170,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFC6C3C3),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  size: 100,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // ➕ Bottom left
          Positioned(
            top: 250,
            left: 20,
            child: Container(
              width: 170,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFC6C3C3),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  size: 100,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // ➕ Bottom right
          Positioned(
            top: 250,
            right: 20,
            child: Container(
              width: 170,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFC6C3C3),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  size: 100,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // ⭐ Favorites section
          Positioned(
            top: 370,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50),
                Text(
                  "Favorites",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 10),

                Container(
                  width: 360,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC6C3C3),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: logout,
              child: const Text("Log Out"),
            ),
          ),
        ],
      ),
    );
  }
}
// -------------------------- Device Specs Page -------------------------- \\

class DeviceSpecsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              "Device Specs",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(child: SpecsTable()),
          ],
        ),
      ),
    );
  }
}

class SpecsTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ["Subsystem", "Key Specifications"],

      [
        "Processing Unit\nRaspberry Pi 5",
        "Quad-core Cortex-A76 (2.4 GHz)\nVideoCore VII GPU\nUp to 16GB RAM",
      ],

      ["Image Sensor\nIMX477", "12.3 MP\nHigh-resolution CMOS sensor"],

      [
        "Lens System\n16mm C-mount",
        "F1.4–F16 aperture\nAdjustable focus\nMid-range field of view",
      ],

      [
        "Control Module\nESP32-S3",
        "Dual-core MCU\nWiFi + Bluetooth\nMultiple GPIO",
      ],

      [
        "Environmental Sensor\nBME280",
        "Temperature\nHumidity\nPressure (I2C/SPI)",
      ],

      [
        "Power Monitor\nINA260",
        "Voltage + current monitoring\nI2C, no external shunt required",
      ],

      [
        "GPS Module\nNEO-6M",
        "GNSS positioning\n~2.5m accuracy\nUART interface",
      ],

      ["Power System\n11.1V Li-ion", "3S2P configuration\n~5.7Ah capacity"],

      [
        "Voltage Regulation\nLM2679",
        "3.3V / 5V output\nHigh-efficiency switching regulator",
      ],

      ["System Display\nOLED", "48×64 resolution\nLow power\nI2C interface"],

      ["Eyepiece Display\nDM-OLED071", "1920×1080 microOLED\nHDMI input"],

      ["USB Interface\nCP2102", "USB-to-UART bridge"],
    ];

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: items.length,

      itemBuilder: (context, index) {
        final item = items[index];

        return TableRowSpecsItem(name: item[0], type: item[1], index: index);
      },
    );
  }
}

class TableRowSpecsItem extends StatelessWidget {
  final String name;
  final String type;
  final int index;

  TableRowSpecsItem({
    required this.name,
    required this.type,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),

      decoration: BoxDecoration(
        color: index % 2 == 0
            ? Color(0xFFC6C3C3)
            : Color.fromARGB(255, 221, 221, 221),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),

          SizedBox(width: 10),

          Expanded(
            flex: 3,
            child: Text(
              type,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------- Search Page -------------------------- \\

class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              "Search",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            SearchField(),
          ],
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search Bird",
        filled: true,
        fillColor: Colors.grey[300],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: Icon(Icons.search),
      ),
    );
  }
}

// -------------------------- Sightings Page -------------------------- \\

class SightingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20),
        Text(
          "Sightings",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Expanded(child: FavoritesTable()),
      ],
    );
  }
}

class BirdSightingsService {
  final supabase = Supabase.instance.client;

  Future<List<dynamic>> getMySightings() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    return await supabase
        .from('bird_sightings')
        .select()
        .eq('user_id', user.id)
        .order('timestamp', ascending: false);
  }

  Future<void> addSighting({
    required String species,
    required double confidence,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('bird_sightings').insert({
      'user_id': user.id,
      'predicted_species': species,
      'confidence': confidence,
    });
  }
}

class FavoritesTable extends StatefulWidget {
  @override
  State<FavoritesTable> createState() => _FavoritesTableState();
}

class _FavoritesTableState extends State<FavoritesTable> {
  List<dynamic> sightings = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchSightings();
    });
  }

  Future<void> fetchSightings() async {
    final service = BirdSightingsService();

    final data = await service.getMySightings();

    if (!mounted) return;

    setState(() {
      sightings = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: sightings.length,
      itemBuilder: (context, index) {
        final item = sightings[index];

        final ebirdInfo = item['ebird_info'] is Map ? item['ebird_info'] : null;

        final commonName = item['common_name'] ?? ebirdInfo?['common_name'];

        final species = item['predicted_species'];
        final timestamp = item['timestamp'];
        final confidence = item['confidence'] ?? 0;

        return TableRowItem(
          name: commonName ?? species,
          type: timestamp.toString(),
          status: "${(confidence * 100).toStringAsFixed(1)}%",
          index: index,
        );
      },
    );
  }
}

class TableRowItem extends StatelessWidget {
  final String name;
  final String type;
  final String status;
  final int index;

  TableRowItem({
    required this.name,
    required this.type,
    required this.status,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),

      decoration: BoxDecoration(
        color: index % 2 == 0
            ? Color(0xFFC6C3C3) // light brown
            : Color.fromARGB(255, 221, 221, 221), // light grey

        borderRadius: BorderRadius.circular(0),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(type, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            status,
            style: TextStyle(
              color: status == "Active" ? Colors.green : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------- Hud Page -------------------------- \\

class HudPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            Text(
              "HUD Settings",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 15),

            CustomDropdownField(),
            SizedBox(height: 8),
            CustomDropdownField(),
            SizedBox(height: 8),
            CustomDropdownField(),
            SizedBox(height: 8),
            CustomDropdownField(),

            SizedBox(height: 20),

            Text(
              "HUD Color",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 15),

            HexColorPickerField(),

            SizedBox(height: 20),

            Text(
              "Data Callout",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 15),

            // Battery HUD tile (fixed version of your Positioned box)
            Container(
              width: 170,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFC6C3C3),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.battery_full,
                  size: 90,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(height: 20),

            Container(
              width: 170,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFC6C3C3),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.battery_full,
                  size: 90,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomDropdownField extends StatefulWidget {
  @override
  _CustomDropdownFieldState createState() => _CustomDropdownFieldState();
}

class _CustomDropdownFieldState extends State<CustomDropdownField> {
  String? selectedValue;
  final List<String> options = [
    "Common Name",
    "Scientific Name",
    "Confidence Rate",
    "Conservation Status",
  ];
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text("Option"),
          value: selectedValue,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down_circle_outlined),
          items: options.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              selectedValue = newValue;
            });
          },
        ),
      ),
    );
  }
}

class HexColorPickerField extends StatefulWidget {
  @override
  _HexColorPickerFieldState createState() => _HexColorPickerFieldState();
}

class _HexColorPickerFieldState extends State<HexColorPickerField> {
  Color selectedColor = Colors.blue;

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Pick a Color"),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                setState(() {
                  selectedColor = color;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text("Done"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  String get hexValue =>
      '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openColorPicker,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selectedColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          hexValue,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
