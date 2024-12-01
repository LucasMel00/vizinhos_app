import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:vizinhos_app/widgets/login_option_button.dart';
import 'email_screen.dart';
import 'widgets/login_option_button.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController controller = TextEditingController();
  String initialCountry = 'BR';
  PhoneNumber number = PhoneNumber(isoCode: 'BR');
  bool isValidPhoneNumber = true;

  bool validateBrazilPhoneNumber(String phoneNumber) {
    final regex = RegExp(r'^\+55\d{2}\d{8,9}$');
    return regex.hasMatch(phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Coloque seu Número Celular",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            InternationalPhoneNumberInput(
              onInputChanged: (PhoneNumber number) {
                final formattedNumber = number.phoneNumber ?? '';
                final isValid = validateBrazilPhoneNumber(formattedNumber);

                setState(() {
                  isValidPhoneNumber = isValid;
                });

                print('Número de Telefone: $formattedNumber');
                print('Número válido: $isValid');
              },
              selectorConfig: SelectorConfig(
                selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
              ),
              ignoreBlank: false,
              autoValidateMode: AutovalidateMode.onUserInteraction,
              initialValue: number,
              textFieldController: controller,
              formatInput: true,
              keyboardType:
                  TextInputType.numberWithOptions(signed: true, decimal: true),
              inputDecoration: InputDecoration(
                hintText: 'Número Celular',
                errorText: isValidPhoneNumber ? null : 'Número inválido',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              selectorTextStyle: TextStyle(color: Colors.black),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: isValidPhoneNumber
                  ? () {
                      print('Número aceito: ${controller.text}');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Continue",
                style: TextStyle(color: Colors.white, fontSize: 16),
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
              iconWidget: Icon(Icons.g_mobiledata, color: Colors.black, size: 40),
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
    );
  }
}
