# AGENTS.md

## Scope and Current State
- This is an early-stage Flutter desktop app (`README.md`: "Ukrainian Minecraft launcher").
- Dart UI surface and architectural foundation are growing. Foundational directories now include `config/`, `data/`, `domain/`, `routing/`, `ui/`, and `utilities/`.
- Existing AI guidance files were searched once via glob; only `README.md` is present.

## Big Picture Architecture
- App entrypoint is `main()` in `lib/main.dart` which sets up window configuration, logging, and calls `runApp`.
- Root widget is `YeLauncherApp`, built with `WidgetsApp.router` (not `MaterialApp`).
- **Routing**: `go_router` is used for declarative routing (`lib/routing/router.dart`).
- **Dependency Injection**: `provider` is wired up via `MultiProvider` using `providersRemote` from `lib/config/dependencies.dart`.
- Theme tokens are modeled as immutable value objects:
  - `AppColors.dark` and `AppColors.light` in `lib/ui/core/themes/colors.dart`.
  - `AppText.defaultTheme` in `lib/ui/core/themes/text.dart`.
- Intended dependency direction: UI -> theme tokens & view models -> domain models & services -> data repositories.

## Editing Boundaries
- Prefer editing `lib/**` for product logic; this is the hand-written app layer.
- Treat `build/**`, `windows/flutter/**`, `linux/flutter/**`, and `macos/Flutter/ephemeral/**` as generated.
- Platform runner code under `windows/runner/**`, `linux/runner/**`, `macos/Runner/**` should only change for platform integration needs.

## Project-Specific Conventions
- Keep design values centralized in `AppColors`/`AppText`; do not hardcode repeated style constants in widgets.
- Continue immutable token classes pattern (`final` fields + `const` constructors + static presets).
- App shell currently uses `WidgetsApp.router`; if adding Material widgets, switch deliberately or ensure they do not require a Material parent unless explicitly provided.
- Font family in text tokens is `Montserrat`; ensure assets are declared before relying on runtime font rendering.
- State management relies on `provider`. Avoid StatefulWidgets when state can be managed reactively. Ensure dependencies pass through providers.
- Logging is centralized with the `logging` package. Use `Logger` instead of `print` or `debugPrint` directly.

## Critical Workflows
- Install deps: `flutter pub get`
- Static analysis: `flutter analyze`
- Tests: `flutter test`
- Run desktop app (Windows): `flutter run -d windows`
- Regenerate platform/build outputs by rerunning Flutter commands rather than manually editing generated files.
- Code generation (e.g., mocks): `dart run build_runner build`

## Testing and Validation Notes
- Existing tests (e.g., `test/minecraft_launch_test.dart`) should be maintained when making logic changes.
- Ensure unit and widget tests are updated for any router or provider configuration changes.
- Keep PRs focused: theme-token changes and root-app wiring changes should include corresponding widget test updates.
