import 'dart:developer';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Calculator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Using the controller to manage the TextField's text
  final _controller = TextEditingController();
  String _result = '0';

  void _onButtonPressed(String buttonText) {
    setState(() {
      log("button pressed: $buttonText");
      if (buttonText == 'AC') {
        _controller.text = '';
        _result = '0';
      } else if (buttonText == 'C') {
        if (_controller.text.isNotEmpty) {
          _controller.text =
              _controller.text.substring(0, _controller.text.length - 1);
        }
      } else if (buttonText == '=') {
        _result = calculate(_controller.text);
      } else {
        if (_controller.text.isNotEmpty &&
            _controller.text.endsWith('.') &&
            buttonText == '.') {
          return; // Do nothing if trying to add a second dot.
        }
        _controller.text += buttonText;
      }
    });
  }

  /// Pre-processes the raw input string to make it safe for calculation.
  /// - Handles consecutive operators (e.g., "5*+-2" becomes "5 - 2").
  /// - Handles leading negative numbers (e.g., "-5" becomes a single token).
  List<String> _preprocessAndTokenize(String input) {
    if (input.isEmpty) return [];

    // First, handle consecutive operators by keeping only the last one.
    // A lookbehind `(?<=[0-9.])` ensures we don't affect a leading unary minus.
    String cleanedInput = input.replaceAllMapped(RegExp(r'(?<=[0-9.])([+\-*/]){2,}'), (match) {
      // Keep only the last character of the matched operator sequence.
      return match.group(0)!.substring(match.group(0)!.length - 1);
    });

    // Add spaces around all operators to ensure clean splitting.
    // This is a robust way to separate numbers and operators.
    cleanedInput = cleanedInput.replaceAllMapped(RegExp(r'([+\-*/])'), (match) {
      // A special case: if an operator is preceded by 'e' (scientific notation), don't add spaces.
      if (match.start > 0 && cleanedInput[match.start - 1].toLowerCase() == 'e') {
        return match.group(1)!;
      }
      return ' ${match.group(1)} ';
    });

    // Split the string by whitespace to get tokens.
    List<String> tokens = cleanedInput.trim().split(RegExp(r'\s+'));

    // Handle a leading unary minus (e.g., "- 5" becomes "-5").
    if (tokens.isNotEmpty && tokens.first == '-') {
      if (tokens.length > 1) {
        tokens[1] = '-${tokens[1]}'; // Combine '-' with the following number.
        tokens.removeAt(0);
      }
    }
    return tokens;
  }

  /// Calculates the result of a mathematical expression string.
  /// This function follows the standard order of operations (PEMDAS/BODMAS).
  String calculate(String input) {
    if (input.isEmpty) {
      return '0';
    }

    // Use the new pre-processing function to get clean tokens.
    List<String> tokens = _preprocessAndTokenize(input);

    // --- Validation ---
    if (tokens.isEmpty) return 'Error';

    bool isOperator(String token) => ['+', '-', '*', '/'].contains(token);

    // After cleaning, the expression should not end with an operator or start with `*` or `/`.
    if (isOperator(tokens.last) || ['*', '/'].contains(tokens.first)) {
      return 'Error';
    }

    try {
      // --- Pass 1: Handle Multiplication and Division (High Precedence) ---
      final List<dynamic> pass1 = [];
      for (int i = 0; i < tokens.length; i++) {
        final token = tokens[i];
        if (token == '*' || token == '/') {
          // The previous item in pass1 must be a number.
          final double left = pass1.removeLast();
          // The next token must be a number.
          final double right = double.parse(tokens[++i]);

          if (token == '/') {
            if (right == 0) return 'Error: Div by 0';
            pass1.add(left / right);
          } else {
            pass1.add(left * right);
          }
        } else if (!isOperator(token)) {
          pass1.add(double.parse(token)); // It's a number
        } else {
          pass1.add(token); // It's a '+' or '-'
        }
      }

      // --- Pass 2: Handle Addition and Subtraction (Low Precedence) ---
      // The `pass1` list now only contains numbers and `+` or `-` operators.
      double result = pass1.first as double;
      for (int i = 1; i < pass1.length; i += 2) {
        final String operator = pass1[i];
        final double right = pass1[i + 1] as double;

        if (operator == '+') {
          result += right;
        } else if (operator == '-') {
          result -= right;
        }
      }

      // --- Format the final result ---
      if (result.truncateToDouble() == result) {
        return result.toInt().toString();
      }
      String formattedResult = result.toStringAsFixed(10);
      formattedResult = formattedResult.replaceAll(RegExp(r'0+$'), '');
      if (formattedResult.endsWith('.')) {
        formattedResult = formattedResult.substring(0, formattedResult.length - 1);
      }
      return formattedResult;

    } catch (e) {
      log('Calculation Error: $e');
      return 'Error';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const buttonLabels = [
      'AC', 'C', '/', '*',
      '7', '8', '9', '-',
      '4', '5', '6', '+',
      '1', '2', '3', '=',
      '0', '.'
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _controller,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                    ),
                    style: Theme.of(context).textTheme.headlineMedium,
                    readOnly: true,
                    showCursor: true,
                  ),
                  Text(
                    _result,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1.0),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 1.5,
            children: buttonLabels.map((label) {
              return TextButton(
                onPressed: () => _onButtonPressed(label),
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 24),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
