import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:vizinhos_app/widgets/login_option_button.dart';
import 'email_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController controller = TextEditingController();
  String initialCountry = 'BR';
  PhoneNumber number = PhoneNumber(isoCode: 'BR');
  bool isValidPhoneNumber = false;
  bool isLoading = false;

  bool validateBrazilPhoneNumber(String phoneNumber) {
    final regex = RegExp(r'^\+55\d{2}\d{8,9}$');
    return regex.hasMatch(phoneNumber);
  }

  void _handleContinue() async {
    if (!isValidPhoneNumber) return;

    setState(() {
      isLoading = true;
    });

    // Simulação de uma requisição assíncrona
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      isLoading = false;
    });

    print('Número aceito: ${controller.text}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.topCenter,
            colors: [const Color.fromARGB(255, 255, 255, 255), Colors.white.withOpacity(0.1)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Text(
                "Coloque seu Número Celular",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              InternationalPhoneNumberInput(
                onInputChanged: (PhoneNumber number) {
                  final formattedNumber = number.phoneNumber ?? '';
                  final isValid = validateBrazilPhoneNumber(formattedNumber);

                  setState(() {
                    isValidPhoneNumber = isValid;
                  });
                },
                selectorConfig: SelectorConfig(
                  selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                ),
                ignoreBlank: false,
                autoValidateMode: AutovalidateMode.onUserInteraction,
                initialValue: number,
                textFieldController: controller,
                formatInput: true,
                keyboardType: TextInputType.numberWithOptions(
                    signed: true, decimal: true),
                inputDecoration: InputDecoration(
                  hintText: 'Número Celular',
                  errorText: isValidPhoneNumber ? null : 'Número inválido',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                selectorTextStyle: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed:
                      isValidPhoneNumber && !isLoading ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Continue",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Colors.grey[400],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "Ou",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              LoginOptionButton(
                text: "Continue com Apple",
                iconWidget: Icon(Icons.apple, color: Colors.black, size: 30),
              ),
              SizedBox(height: 16),
              LoginOptionButton(
                text: "Continue com Google",
                iconWidget:
                    Icon(Icons.g_mobiledata, color: Colors.black, size: 40),
              ),
              SizedBox(height: 16),
              LoginOptionButton(
                text: "Continue com Email",
                iconWidget: Icon(Icons.email, color: Colors.black, size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EmailScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
