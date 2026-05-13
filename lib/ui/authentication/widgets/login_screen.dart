import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/text_form_field.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        constraints: const BoxConstraints.expand(),
        color: AppColors.dark.surface,
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.dark.surfaceContainer,
              ),
              padding: const EdgeInsets.all(30),
              constraints: const BoxConstraints(minWidth: 230, maxWidth: 430),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset("assets/logo.svg", height: 40),
                  const SizedBox(height: 8),
                  Text(
                    "Вхід до YeLauncher",
                    style: AppText.defaultTheme.titleSmall.copyWith(
                      color: AppColors.dark.onSurface,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Пошта",
                      style: AppText.defaultTheme.label.copyWith(
                        color: AppColors.dark.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(controller: _email, labelText: "Введіть пошту"),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Пароль",
                      style: AppText.defaultTheme.label.copyWith(
                        color: AppColors.dark.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _password,
                    labelText: "Введіть пароль",
                  ),
                  SizedBox(height: 8),
                  Button.primary(
                    "Увійти",
                    onPressed: () {
                      _formKey.currentState!.validate();
                    },
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
