import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:yelauncher/routing/routes.dart';
import 'package:yelauncher/ui/authentication/view_models/login_viewmodel.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/text_form_field.dart' as ye;
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class LoginScreen extends StatefulWidget {
  final LoginViewModel viewModel;

  const LoginScreen({super.key, required this.viewModel});

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nickname = TextEditingController();

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  void _onMicrosoftLogin() async {
    await widget.viewModel.loginMicrosoft.execute();
    if (mounted) {
      context.go(Routes.instances);
    }
  }

  void _onOfflineLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      await widget.viewModel.loginOffline.execute(_nickname.text.trim());
      if (mounted && widget.viewModel.loginOffline.complete) {
        context.go(Routes.instances);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final isAuthenticating = widget.viewModel.isAuthenticating;

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
                  constraints: const BoxConstraints(
                    minWidth: 230,
                    maxWidth: 430,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset("assets/logo.svg", height: 40),
                      const SizedBox(height: 8),
                      Text(
                        "Sign in to YeLauncher",
                        style: AppText.defaultTheme.titleSmall.copyWith(
                          color: AppColors.dark.onSurface,
                        ),
                      ),
                      if (widget.viewModel.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          widget.viewModel.errorMessage!,
                          style: AppText.defaultTheme.label.copyWith(
                            color: AppColors.dark.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 30),

                      // Microsoft Login Button
                      SizedBox(
                        width: double.infinity,
                        child: Button.primary(
                          "Login with Microsoft",
                          onPressed: isAuthenticating
                              ? null
                              : _onMicrosoftLogin,
                        ),
                      ),

                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: AppColors.dark.outline),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              "OR OFFLINE",
                              style: AppText.defaultTheme.label.copyWith(
                                color: AppColors.dark.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: AppColors.dark.outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Offline Login
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Nickname",
                          style: AppText.defaultTheme.label.copyWith(
                            color: AppColors.dark.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ye.TextFormField(
                        controller: _nickname,
                        labelText: "Enter nickname",
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Nickname cannot be empty";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Button.primary(
                          "Play Offline",
                          onPressed: isAuthenticating ? null : _onOfflineLogin,
                        ),
                      ),

                      if (isAuthenticating) ...[
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
