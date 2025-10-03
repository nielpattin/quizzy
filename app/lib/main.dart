import "dart:convert";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:http/http.dart" as http;
import "firebase_options.dart";
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize(
    serverClientId:
        "119783050207-7dmtsbrrfdascr0ua882fc4t8dsmr0s7.apps.googleusercontent.com",
  );
  runApp(const QuizzyApp());
}

class QuizzyApp extends StatelessWidget {
  const QuizzyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Quizzy",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return UserInfoPage(user: snapshot.data!);
          }
          return const LoginPage();
        },
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  Future<void> login() async {
    try {
      print('Calling GoogleSignIn.instance.authenticate()');
      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate();
      print('Got account: ${account.email}');

      final GoogleSignInAuthentication googleAuth = account.authentication;
      print('Got auth: idToken=${googleAuth.idToken != null}');

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      print('Signing in with Firebase');
      await FirebaseAuth.instance.signInWithCredential(credential);

      print('Firebase sign in successful');

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken();
        final response = await http.post(
          Uri.parse('${dotenv.env['SERVER_URL']}/api/auth/verify'),
          headers: {'Authorization': 'Bearer $idToken'},
        );

        if (response.statusCode == 200) {
          print('Server verification successful: ${response.body}');
        } else {
          print(
            'Server verification failed: ${response.statusCode} ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Login failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/Logo.png', width: 300, height: 300),
            Text("Quizzy", style: Theme.of(context).textTheme.headlineMedium),
            ElevatedButton(onPressed: login, child: const Text("Google login")),
          ],
        ),
      ),
    );
  }
}

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key, required this.user});

  final User user;

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  String _serverMessage = "";
  bool _isLoading = false;

  Future<void> _fetchProtectedData() async {
    setState(() {
      _isLoading = true;
      _serverMessage = "";
    });

    try {
      final idToken = await widget.user.getIdToken();
      final response = await http.get(
        Uri.parse('${dotenv.env['SERVER_URL']}/api/data'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _serverMessage = data['message'];
        });
      } else {
        setState(() {
          _serverMessage = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _serverMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.user.photoURL != null)
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(widget.user.photoURL!),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Name: ${widget.user.displayName ?? 'N/A'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Email: ${widget.user.email ?? 'N/A'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'UID: ${widget.user.uid}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Email Verified: ${widget.user.emailVerified ? 'Yes' : 'No'}',
              style: const TextStyle(fontSize: 16),
            ),
            if (widget.user.phoneNumber != null) ...[
              const SizedBox(height: 10),
              Text(
                'Phone: ${widget.user.phoneNumber}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchProtectedData,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Fetch Protected Data'),
            ),
            const SizedBox(height: 10),
            if (_serverMessage.isNotEmpty)
              Text(
                _serverMessage,
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}
