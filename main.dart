// flutter run -d chrome

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'bird_details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      if (event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => ResetPasswordPage()),
          (route) => false,
        );
      }
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    print("HANDLING DEEPLINK: $uri");

    if (_hasHandledLink) return;
    _hasHandledLink = true;
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
                                                  'feather://reset-password/',
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

  int totalSightings = 0;
  int? batteryPercent;
  String? mostCommonBird;
  String? rarestBird;

  List<dynamic> favorites = [];

  @override
  void initState() {
    super.initState();
    initDashboard();
    listenToBattery();
  }

  Future<void> initDashboard() async {
    await loadUser();
    await loadBirdStats();
    await loadFavorites();
    await loadDeviceStatus();
  }

  // ---------------- USER ----------------
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

    if (!mounted) return;

    setState(() {
      final raw = data?['username'];

      final clean = (raw == null) ? null : raw.toString().trim();

      username = (clean == null || clean.isEmpty) ? 'User' : clean;
    });
  }

  // ---------------- BATTERY ----------------
  Future<void> loadDeviceStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Get the device serial for this user
    final device = await Supabase.instance.client
        .from('device_codes')
        .select('device_serial')
        .eq('user_id', user.id)
        .eq('used', true)
        .maybeSingle();

    final serial = device?['device_serial'];
    if (serial == null) return;

    // Get battery
    final status = await Supabase.instance.client
        .from('device_status')
        .select('battery_percent')
        .eq('device_serial', serial)
        .maybeSingle();

    if (!mounted) return;

    setState(() {
      batteryPercent = status?['battery_percent'];
    });

    print("SERIAL: $serial");
    print("DEVICE STATUS RAW: $status");
  }

  void listenToBattery() {
    Supabase.instance.client
        .from('device_status')
        .stream(primaryKey: ['device_serial'])
        .listen((data) {
          if (data.isEmpty) return;

          setState(() {
            batteryPercent = data.first['battery_percent'];
          });
        });
  }

  // ---------------- STATS ----------------
  Future<void> loadBirdStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('bird_sightings')
        .select()
        .eq('user_id', user.id);

    final List rows = data;

    final Map<String, int> counts = {};

    for (final row in rows) {
      final species = row['predicted_species'];

      String? name;

      try {
        final ebird = jsonDecode(row['ebird_info'] ?? '{}');
        name = ebird['common_name'];
      } catch (_) {
        name = species;
      }

      final finalName = (name == null || name.toString().isEmpty)
          ? species
          : name;

      final displayName = finalName?.replaceAll('_', ' ');

      if (displayName != null) {
        counts[displayName] = (counts[displayName] ?? 0) + 1;
      }
    }

    String? mostCommon;
    String? rarest;

    if (counts.isNotEmpty) {
      mostCommon = counts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;

      final minCount = counts.values.reduce((a, b) => a < b ? a : b);

      final rareList = counts.entries
          .where((e) => e.value == minCount)
          .toList();

      rarest = rareList.first.key;
    }

    if (!mounted) return;

    setState(() {
      totalSightings = rows.length;
      mostCommonBird = mostCommon;
      rarestBird = rarest;
    });
  }

  // ---------------- FAVORITES ----------------
  Future<void> loadFavorites() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('user_favorites')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    if (!mounted) return;

    setState(() {
      favorites = data;
    });
  }

  // ---------------- USER ACTIONS ----------------
  Future<void> updateUsername() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client
        .from('profiles')
        .update({'username': 'Gracie'})
        .eq('id', user.id);

    await loadUser();
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Welcome ${username ?? "..."}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: logout,
                    icon: const Icon(Icons.logout),
                    label: const Text("Log Out"),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, // icon + text color
                      backgroundColor: const Color.fromARGB(255, 201, 170, 159),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // STATS ROW
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: buildBox(
                        null,
                        customIcon: Icon(
                          batteryPercent == null
                              ? Icons.battery_unknown
                              : batteryPercent! > 80
                              ? Icons.battery_full
                              : batteryPercent! > 50
                              ? Icons.battery_6_bar
                              : batteryPercent! > 20
                              ? Icons.battery_3_bar
                              : Icons.battery_alert,
                          size: 80,
                          color: Colors.black87,
                        ),
                        value: "${batteryPercent ?? 0}%",
                        label: "Field Device Battery",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildBox(
                        Icons.bar_chart,
                        value: mostCommonBird ?? "...",
                        label: "Common Sightings",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildBox(
                        Icons.emoji_events,
                        value: rarestBird ?? "...",
                        label: "Rarest Sightings",
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Favorites",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              // FAVORITES TABLE
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC6C3C3),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: favorites.isEmpty
                      ? const Center(
                          child: Text(
                            "No favorites yet",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: favorites.length,
                          itemBuilder: (context, index) {
                            final item = favorites[index];
                            final name = item['common_name'] ?? 'Unknown';

                            return InkWell(
                              borderRadius: BorderRadius.circular(10),

                              onTap: () async {
                                final abundanceResponse = await Supabase
                                    .instance
                                    .client
                                    .from('bird_abundance')
                                    .select()
                                    .eq('common_name', name)
                                    .maybeSingle();

                                final birdResponse = await Supabase
                                    .instance
                                    .client
                                    .from('birds')
                                    .select()
                                    .eq('common_name', name)
                                    .maybeSingle();

                                if (!context.mounted) return;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BirdDetailsPage(
                                      bird: {
                                        ...?birdResponse,
                                        'common_name': name,
                                        'abundance_index':
                                            abundanceResponse?['abundance_index'] ??
                                            0,
                                        'sightings':
                                            abundanceResponse?['sightings'] ??
                                            0,
                                      },
                                    ),
                                  ),
                                );
                              },

                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: index.isEven
                                      ? const Color(0xFFDADADA)
                                      : const Color(0xFFE8E8E8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        final user = Supabase
                                            .instance
                                            .client
                                            .auth
                                            .currentUser;
                                        if (user == null) return;

                                        final commonName = item['common_name'];

                                        final shouldDelete = await showDialog<bool>(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text(
                                                "Remove Favorite",
                                              ),
                                              content: const Text(
                                                "Are you sure you would like to remove this from your favorites?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                                  child: const Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(true),
                                                  child: const Text(
                                                    "Remove",
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        // user tapped outside or canceled
                                        if (shouldDelete != true) return;

                                        await Supabase.instance.client
                                            .from('user_favorites')
                                            .delete()
                                            .eq('user_id', user.id)
                                            .eq('common_name', commonName);

                                        setState(() {
                                          favorites.removeWhere(
                                            (fav) =>
                                                fav['common_name'] ==
                                                commonName,
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- BOX WIDGET ----------------
  Widget buildBox(
    IconData? icon, {
    Widget? customIcon,
    String? label,
    String? value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFC6C3C3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (customIcon != null)
              customIcon
            else if (icon != null)
              Icon(icon, size: 75),

            const SizedBox(height: 6),

            Text(
              value ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            Text(
              label ?? "",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
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
          children: [
            SizedBox(height: 30),
            Text(
              "Device Specs",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Detailed specifications of the field device hardware components",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
            Divider(),
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
        "Processing Unit: Raspberry Pi 5",
        "Quad-core Cortex-A76 (2.4 GHz)\nVideoCore VII GPU\t\t|\t\t\tUp to 16GB RAM",
      ],

      [
        "Image Sensor: IMX477",
        "12.3 MP\t\t\t|\t\t\tHigh-resolution CMOS sensor",
      ],

      [
        "Lens System: 16mm C-mount",
        "F1.4–F16 aperture\t\t\t|\t\t\tAdjustable focus\t\t\t|\t\t\tMid-range field of view",
      ],

      [
        "Control Module: ESP32-S3",
        "Dual-core MCU\t\t\t|\t\t\tWiFi + Bluetooth\t\t\t|\t\t\tMultiple GPIO",
      ],

      [
        "Environmental Sensor: BME280",
        "Temperature\t\t\t|\t\t\tHumidity\t\t\t|\t\t\tPressure (I2C/SPI)",
      ],

      [
        "Power Monitor: INA260",
        "Voltage + current monitoring\t\t\t|\t\t\tI2C, no external shunt required",
      ],

      [
        "GPS Module: NEO-6M",
        "GNSS positioning\t\t\t|\t\t\t~2.5m accuracy\t\t\t|\t\t\tUART interface",
      ],

      [
        "Power System: 11.1V Li-ion",
        "3S2P configuration\t\t\t|\t\t\t~5.7Ah capacity",
      ],

      [
        "Voltage Regulation: LM2679",
        "3.3V / 5V output\t\t\t|\t\t\tHigh-efficiency switching regulator",
      ],

      [
        "System Display: OLED",
        "48×64 resolution\t\t\t|\t\t\tLow power\t\t\t|\t\t\tI2C interface",
      ],

      [
        "Eyepiece Display: DM-OLED071",
        "1920×1080 microOLED\t\t\t|\t\t\tHDMI input",
      ],

      ["USB Interface: CP2102", "USB-to-UART bridge"],
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
              style: TextStyle(
                fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                fontStyle: FontStyle.italic,
                fontSize: 20,
              ),
            ),
          ),

          SizedBox(width: 0),

          Expanded(
            flex: 3,
            child: Text(
              type,
              style: TextStyle(
                fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                fontStyle: index == 0 ? FontStyle.italic : FontStyle.normal,
                fontSize: 20,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------- Search Page -------------------------- \\

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  final user = Supabase.instance.client.auth.currentUser;

  Set<String> favoriteBirds = {};

  List<Map<String, dynamic>> birds = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('user_favorites')
        .select('common_name')
        .eq('user_id', user!.id);

    setState(() {
      favoriteBirds = Set<String>.from(response.map((e) => e['common_name']));
    });
  }

  Future<void> searchBirds(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        birds = [];
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    final response = await Supabase.instance.client
        .from('birds')
        .select()
        .or('common_name.ilike.%$query%,scientific_name.ilike.%$query%');

    setState(() {
      birds = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> toggleFavorite(String name) async {
    if (user == null) return;

    final isFav = favoriteBirds.contains(name);

    setState(() {
      if (isFav) {
        favoriteBirds.remove(name);
      } else {
        favoriteBirds.add(name);
      }
    });

    if (!isFav) {
      await Supabase.instance.client.from('user_favorites').insert({
        'user_id': user!.id,
        'common_name': name,
      });
    } else {
      await Supabase.instance.client
          .from('user_favorites')
          .delete()
          .eq('user_id', user!.id)
          .eq('common_name', name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Text(
              "Search",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const Text(
              "Search for birds by common or scientific name",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),

            Divider(),
            const SizedBox(height: 20),

            TextField(
              controller: _searchController,
              onChanged: searchBirds,
              decoration: InputDecoration(
                hintText: "Search Bird",
                filled: true,
                fillColor: Colors.grey[300],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: const Icon(Icons.search),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : birds.isEmpty
                  ? const Center(
                      child: Text("Search for a bird to learn more about it"),
                    )
                  : ListView.builder(
                      itemCount: birds.length,
                      itemBuilder: (context, index) {
                        final bird = birds[index];
                        final name = bird['common_name'];

                        final isFavorite = favoriteBirds.contains(name);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Icons.flutter_dash),

                            title: Text(
                              name ?? 'Unknown Bird',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Text.rich(
                              TextSpan(
                                children: [
                                  // Scientific name
                                  if (bird['scientific_name'] != null &&
                                      bird['scientific_name']
                                          .toString()
                                          .isNotEmpty)
                                    TextSpan(
                                      text: '${bird['scientific_name']}\n',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.black87,
                                      ),
                                    ),

                                  // Order
                                  if (bird['order_name'] != null &&
                                      bird['order_name'].toString().isNotEmpty)
                                    TextSpan(
                                      text: 'ORDER: ${bird['order_name']}\n',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),

                                  // Family
                                  if (bird['family'] != null &&
                                      bird['family'].toString().isNotEmpty)
                                    TextSpan(
                                      text: 'FAMILY: ${bird['family']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            isThreeLine: true,

                            // ❤️ FAVORITE BUTTON
                            trailing: IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                              ),
                              onPressed: () => toggleFavorite(name),
                            ),

                            // 📌 DETAILS PAGE
                            onTap: () async {
                              final abundanceResponse = await Supabase
                                  .instance
                                  .client
                                  .from('bird_abundance')
                                  .select()
                                  .eq('common_name', name)
                                  .maybeSingle();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BirdDetailsPage(
                                    bird: {
                                      ...bird,
                                      'abundance_index':
                                          abundanceResponse?['abundance_index'] ??
                                          0,
                                      'sightings':
                                          abundanceResponse?['sightings'] ?? 0,
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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
        const SizedBox(height: 50),
        const Center(
          child: Column(
            children: [
              Text(
                "Sightings",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                "Your recent bird sightings will appear here",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: Colors.black, // 👈 this is what makes it match
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const Divider(),
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

class HudPage extends StatefulWidget {
  @override
  _HudPageState createState() => _HudPageState();
}

class _HudPageState extends State<HudPage> with AutomaticKeepAliveClientMixin {
  List<String?> selectedFields = List.filled(4, null);
  Color selectedColor = Colors.green;
  String? saveMessage;
  String selectedLayout = "layout1";

  Map<String, dynamic> buildHudJson() {
    return {
      "hud_fields": selectedFields.map((e) {
        if (e == null || e == "None") return null;
        return e;
      }).toList(),
      "hud_color":
          "#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}",
      "hud_layout": selectedLayout,
    };
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  final supabase = Supabase.instance.client;

  Future<void> saveSettings() async {
    final supabase = Supabase.instance.client;
    final prefs = await SharedPreferences.getInstance();

    final jsonData = buildHudJson();
    final userId = supabase.auth.currentUser!.id;

    // 1. SAVE TO SUPABASE (this is where your upsert goes)
    await supabase.from('user_hud_settings').upsert({
      'user_id': userId,
      'settings': jsonData,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');

    // 2. SAVE LOCAL CACHE
    await prefs.setString("hud_settings", jsonEncode(jsonData));

    if (!mounted) return;

    setState(() {
      saveMessage = "Settings saved successfully";
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        saveMessage = null;
      });
    });

    print("Saved HUD settings: $jsonData");
  }

  Future<void> loadSettings() async {
    final supabase = Supabase.instance.client;
    final prefs = await SharedPreferences.getInstance();

    final userId = supabase.auth.currentUser?.id;

    Map<String, dynamic>? json;

    // 1. ALWAYS try Supabase first
    if (userId != null) {
      final data = await supabase
          .from('user_hud_settings')
          .select('settings')
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null && data['settings'] != null) {
        json = data['settings'];

        // 🔥 overwrite local cache with fresh cloud data
        await prefs.setString("hud_settings", jsonEncode(json));
      }
    }

    // 2. ONLY fallback if Supabase returned nothing
    if (json == null) {
      final local = prefs.getString("hud_settings");
      if (local != null) {
        json = jsonDecode(local);
      }
    }

    if (json == null || !mounted) return;

    setState(() {
      selectedFields = List<String?>.from(
        (json!["hud_fields"] as List).map((e) {
          final v = e as String?;

          if (v == null || v == "None" || v.isEmpty) {
            return null;
          }

          return v;
        }),
      );

      selectedColor = Color(
        int.parse(json["hud_color"].replaceFirst('#', ''), radix: 16) |
            0xFF000000,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 👈 REQUIRED
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // HEADER
                const Text(
                  "HUD Settings",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const Text.rich(
                  TextSpan(
                    text: "Please ",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: "scroll down",
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                      TextSpan(
                        text:
                            " to save your settings after making changes. These settings will be used to configure the HUD display in your telescope eyepiece.",
                      ),
                    ],
                  ),
                ),

                Divider(),
                const SizedBox(height: 20),

                // MAIN ROW (still side-by-side)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            "Label Fields",
                            style: TextStyle(
                              fontSize: 22,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 20),

                          for (int i = 0; i < 4; i++)
                            CustomDropdownField(
                              value: selectedFields[i],
                              onChanged: (value) {
                                setState(() {
                                  selectedFields[i] = value;
                                });
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // RIGHT
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            "Color Picker",
                            style: TextStyle(
                              fontSize: 22,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 20),

                          HexColorPickerField(
                            color: selectedColor,
                            onChanged: (color) {
                              setState(() {
                                selectedColor = color;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                const Text(
                  "Layout Options",
                  style: TextStyle(fontSize: 22, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 30),

                // FOOTER CARDS (now scrollable naturally)
                Row(
                  children: [
                    Expanded(
                      child: buildBox(
                        null,
                        label: "Layout #1",
                        imagePath: "assets/images/layout1.png",
                        layoutId: "layout1",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildBox(
                        null,
                        label: "Layout #2",
                        imagePath: "assets/images/layout2.png",
                        layoutId: "layout2",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildBox(
                        null,
                        label: "Layout #3",
                        imagePath: "assets/images/layout3.png",
                        layoutId: "layout3",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                if (saveMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      saveMessage!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                Center(
                  child: ElevatedButton(
                    onPressed: saveSettings,

                    child: const Text("Save Settings"),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBox(
    IconData? icon, {
    String? label,
    String? value,
    String? imagePath,
    String? layoutId,
  }) {
    final isSelected = selectedLayout == layoutId;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLayout = layoutId!;
        });
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFC2C0C0) : const Color(0xFFC6C3C3),
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(
                    color: const Color.fromARGB(205, 55, 32, 23),
                    width: 3,
                  )
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (imagePath != null)
                  Image.asset(imagePath, height: 60, width: 60),

                if (label != null) Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomDropdownField extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;

  const CustomDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const options = [
    "Common Name",
    "Scientific Name",
    "Confidence Rate",
    "Conservation Status",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: CustomDropdownField.options.contains(value) ? value : null,

          items: [
            const DropdownMenuItem<String?>(value: null, child: Text("None")),
            ...CustomDropdownField.options.map((opt) {
              return DropdownMenuItem<String?>(value: opt, child: Text(opt));
            }),
          ],

          onChanged: onChanged,
        ),
      ),
    );
  }
}

class HexColorPickerField extends StatelessWidget {
  final Color color;
  final Function(Color) onChanged;

  const HexColorPickerField({
    super.key,
    required this.color,
    required this.onChanged,
  });

  String getHex(Color color) =>
      '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20)),

        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Pick a Color"),
                content: ColorPicker(
                  pickerColor: color,
                  onColorChanged: onChanged,
                ),
              ),
            );
          },
          child: Container(
            height: 315,
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.symmetric(horizontal: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),

            child: Center(
              child: Text(
                getHex(color),
                style: TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
