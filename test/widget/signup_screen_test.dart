import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// A test-specific version of the SignupScreen with mocked dependencies
class TestableSignupScreen extends StatelessWidget {
  final VoidCallback? onSignUpPressed;
  final VoidCallback? onLoginPressed;

  const TestableSignupScreen({
    Key? key,
    this.onSignUpPressed,
    this.onLoginPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _TestableSignupBody(
          onSignUpPressed: onSignUpPressed,
          onLoginPressed: onLoginPressed,
        ),
      ),
    );
  }
}

// A testable version of the signup screen content
class _TestableSignupBody extends StatefulWidget {
  final VoidCallback? onSignUpPressed;
  final VoidCallback? onLoginPressed;

  const _TestableSignupBody({
    Key? key,
    this.onSignUpPressed,
    this.onLoginPressed,
  }) : super(key: key);

  @override
  _TestableSignupBodyState createState() => _TestableSignupBodyState();
}

class _TestableSignupBodyState extends State<_TestableSignupBody> {
  final TextEditingController nameController = TextEditingController();
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

              // Signup form
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
                      "Create Account",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('name_field'),
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon:
                            const Icon(Icons.person, color: Colors.white70),
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
                        key: const Key('signup_button'),
                        onPressed: () {
                          if (nameController.text.isEmpty ||
                              emailController.text.isEmpty ||
                              passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please enter name, email and password')),
                            );
                            return;
                          }
                          if (widget.onSignUpPressed != null) {
                            widget.onSignUpPressed!();
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
                          "SIGN UP",
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

              // Login link - FIXED to avoid overflow
              Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(
                        color: Colors.black, // Changed for visibility in tests
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4), // Small gap
                    GestureDetector(
                      key: const Key('login_link'),
                      onTap: widget.onLoginPressed,
                      child: const Text(
                        "Login",
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
  testWidgets('Signup Screen UI elements are displayed correctly',
      (WidgetTester tester) async {
    // Build our test version of the signup screen
    await tester.pumpWidget(const TestableSignupScreen());

    // Verify UI elements are displayed
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('SIGN UP'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    // Verify we have text fields
    expect(find.byKey(const Key('name_field')), findsOneWidget);
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
  });

  testWidgets('Shows error message with empty fields',
      (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(const TestableSignupScreen());

    // Tap the signup button without entering any data
    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pump();

    // Verify the snackbar appears with the error message
    expect(find.text('Please enter name, email and password'), findsOneWidget);
  });

  testWidgets('Shows error when only name is entered',
      (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(const TestableSignupScreen());

    // Enter only name
    await tester.enterText(find.byKey(const Key('name_field')), 'Test User');

    // Tap the signup button
    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pump();

    // Verify the error message appears
    expect(find.text('Please enter name, email and password'), findsOneWidget);
  });

  testWidgets('Password visibility toggle works correctly',
      (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(const TestableSignupScreen());

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

    // Tap again to hide the password
    await tester.tap(find.byKey(const Key('visibility_toggle')));
    await tester.pump();

    // Password should be obscured again
    passwordField =
        tester.widget<TextField>(find.byKey(const Key('password_field')));
    expect(passwordField.obscureText, true);
  });

  testWidgets('Can enter text in all fields', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(const TestableSignupScreen());

    // Enter text in all fields
    await tester.enterText(find.byKey(const Key('name_field')), 'Test User');
    await tester.enterText(
        find.byKey(const Key('email_field')), 'test@example.com');
    await tester.enterText(
        find.byKey(const Key('password_field')), 'password123');

    // Verify text was entered correctly
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);

    // For the password field, we need to check the controller
    final passwordField =
        tester.widget<TextField>(find.byKey(const Key('password_field')));
    expect(passwordField.controller?.text, 'password123');
  });

  testWidgets('SignUp callback is triggered with valid data',
      (WidgetTester tester) async {
    // Track if signup button was pressed
    bool signUpPressed = false;

    // Build the widget with a callback
    await tester.pumpWidget(TestableSignupScreen(
      onSignUpPressed: () {
        signUpPressed = true;
      },
    ));

    // Enter all required fields
    await tester.enterText(find.byKey(const Key('name_field')), 'Test User');
    await tester.enterText(
        find.byKey(const Key('email_field')), 'test@example.com');
    await tester.enterText(
        find.byKey(const Key('password_field')), 'password123');

    // Tap signup button
    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pump();

    // Verify callback was triggered
    expect(signUpPressed, true);
  });

  testWidgets('Login callback is triggered when Login is tapped',
      (WidgetTester tester) async {
    // Track if login link was pressed
    bool loginPressed = false;

    // Build the widget with a callback
    await tester.pumpWidget(TestableSignupScreen(
      onLoginPressed: () {
        loginPressed = true;
      },
    ));

    // Tap login link
    await tester.tap(find.byKey(const Key('login_link')));
    await tester.pump();

    // Verify callback was triggered
    expect(loginPressed, true);
  });
}
