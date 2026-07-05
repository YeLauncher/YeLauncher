import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:yelauncher/routing/routes.dart';
import 'package:yelauncher/ui/authentication/view_models/login_viewmodel.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  final LoginViewModel viewModel;

  const LoginScreen({super.key, required this.viewModel});

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  void _onMicrosoftLogin() async {
    await widget.viewModel.loginMicrosoft.execute();
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
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

        return Container(
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
                      if (widget.viewModel.loginMicrosoft.running) ...[
                        const SizedBox(height: 32),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        Text(
                          AppLocalizations.of(context)!.loginWaitingMicrosoft,
                          style: AppText.defaultTheme.title.copyWith(
                            color: AppColors.dark.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: Button.surface(
                            AppLocalizations.of(context)!.cancel,
                            onPressed: () => widget.viewModel.cancelMicrosoftLogin(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        SvgPicture.asset("assets/logo.svg", height: 40),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.signInToYeLauncher,
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
                            AppLocalizations.of(context)!.loginWithMicrosoft,
                            onPressed: isAuthenticating
                                ? null
                                : _onMicrosoftLogin,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
      },
    );
  }
}
