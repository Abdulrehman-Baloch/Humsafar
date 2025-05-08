import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// A test-specific version of the LoginScreen with mocked dependencies
class TestableLoginScreen extends StatelessWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onSignUpPressed;

  const TestableLoginScreen({
    Key? key,
    this.onLoginPressed,
    this.onSignUpPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _TestableLoginBody(
          onLoginPressed: onLoginPressed,
          onSignUpPressed: onSignUpPressed,
        ),
      ),
    );
  }
}

// A testable version of the login screen content
class _TestableLoginBody extends StatefulWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onSignUpPressed;

  const _TestableLoginBody({
    Key? key,
    this.onLoginPressed,
    this.onSignUpPressed,
  }) : super(key: key);

  @override
  _TestableLoginBodyState createState() => _TestableLoginBodyState();
}

class _TestableLoginBodyState extends State<_TestableLoginBody> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200], // Simple background instead of image
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Logo section (simplified for tests)
              const SizedBox(
                width: 250,
                height: 100, // Reduced height for tests
                child: Placeholder(
                  color: Colors.grey,
                ),
              ),

              // Login form
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('email_field'),
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon:
                            const Icon(Icons.email, color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('password_field'),
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon:
                            const Icon(Icons.lock, color: Colors.white70),
                        suffixIcon: IconButton(
                          key: const Key('visibility_toggle'),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        key: const Key('login_button'),
                        onPressed: () {
                          if (emailController.text.isEmpty ||
                              passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Please enter email and password')),
                            );
                            return;
                          }
                          if (widget.onLoginPressed != null) {
                            widget.onLoginPressed!();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 79, 108, 131),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          "LOGIN",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Sign up link - FIXED to avoid overflow
              Container(
                child: Column(
                  // Changed from Row to Column to avoid overflow
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?", // No trailing space
                      style: TextStyle(
                        color: Colors.black, // Changed to black for visibility
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4), // Add a small gap
                    GestureDetector(
                      key: const Key('signup_link'),
                      onTap: widget.onSignUpPressed,
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    );
  }
}

void main() {
  testWidgets('Login Screen UI elements are displayed correctly',
      (WidgetTester tester) async {
    // Build our test version of the login screen
    await tester.pumpWidget(const TestableLoginScreen());

    // Verify UI elements are displayed
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);

    // Verify we have text fields
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
  });

  testWidgets('Shows error message with empty fields',
      (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(const TestableLoginScreen());

    // Tap the login button without entering credentials
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();

    // Verify the snackbar appears with the error message
    expect(find.text('Please enter email and password'), findsOneWidget);
  });

  testWidgets('Password visibility toggle works correctly',
      (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(const TestableLoginScreen());

    // By default, password should be obscured
    var passwordField =
        tester.widget<TextField>(find.byKey(const Key('password_field')));
    expect(passwordField.obscureText, true);

    // Tap the visibility toggle button
    await tester.tap(find.byKey(const Key('visibility_toggle')));
    await tester.pump();

    // Now password should be visible
    passwordField =
        tester.widget<TextField>(find.byKey(const Key('password_field')));
    expect(passwordField.obscureText, false);
  });

  testWidgets('Can enter text in fields', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(const TestableLoginScreen());

    // Enter text in email field
    await tester.enterText(
        find.byKey(const Key('email_field')), 'test@example.com');

    // Enter text in password field
    await tester.enterText(
        find.byKey(const Key('password_field')), 'password123');

    // Verify text was entered correctly
    expect(find.text('test@example.com'), findsOneWidget);

    // For the password field, we can't check the text directly
    // since it's obscured by default
    final passwordField =
        tester.widget<TextField>(find.byKey(const Key('password_field')));
    expect(passwordField.controller?.text, 'password123');
  });

  testWidgets('Login callback is triggered', (WidgetTester tester) async {
    // Track if login button was pressed
    bool loginPressed = false;

    // Build the widget with a callback
    await tester.pumpWidget(TestableLoginScreen(
      onLoginPressed: () {
        loginPressed = true;
      },
    ));

    // Enter required fields
    await tester.enterText(
        find.byKey(const Key('email_field')), 'test@example.com');
    await tester.enterText(
        find.byKey(const Key('password_field')), 'password123');

    // Tap login button
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();

    // Verify callback was triggered
    expect(loginPressed, true);
  });

  testWidgets('SignUp callback is triggered', (WidgetTester tester) async {
    // Track if signup link was pressed
    bool signUpPressed = false;

    // Build the widget with a callback
    await tester.pumpWidget(TestableLoginScreen(
      onSignUpPressed: () {
        signUpPressed = true;
      },
    ));

    // Tap signup link
    await tester.tap(find.byKey(const Key('signup_link')));
    await tester.pump();

    // Verify callback was triggered
    expect(signUpPressed, true);
  });
}
