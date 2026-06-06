# AGENTS.md - LLM Context and Guidelines for YeLauncher

## Project Overview
* **Description:** YeLauncher is an early-stage Flutter desktop application serving as a Ukrainian Minecraft launcher.
* **Environment:** Dart SDK ^3.11.4.

## Architecture & Code Structure
* **Layered Architecture:** The codebase follows a strict dependency direction: UI -> theme tokens & view models -> domain models & services -> data repositories.
* **Foundational Directories:** The application is split into `config/`, `data/`, `domain/`, `routing/`, `ui/`, and `utilities/` inside the `lib/` directory.
* **Application Root:** The entry point is `main()` in `lib/main.dart`, which configures the desktop window via `window_manager` (default size 1200x750, minimum 800x600) and sets up root logging.
* **UI Framework:** The root widget is `YeLauncherApp`, which uses `WidgetsApp.router` instead of `MaterialApp`.
* **Editing Boundaries:** Only edit logic within the `lib/**` directory; treat platform runner folders (`windows/runner/**`, `linux/runner/**`, `macos/Runner/**`) and `build/**` as generated outputs unless native platform integration (like MSIX protocol activation) is explicitly required.

## State Management & Dependency Injection
* **State Management Strategy:** The project strictly relies on native-first solutions like `ValueNotifier`, `ChangeNotifier`, and `ListenableBuilder` utilizing the Model-View-ViewModel (MVVM) pattern.
* **Strict Restrictions:** Do NOT use Riverpod, Bloc, or GetX under any circumstances.
* **Dependency Injection:** Dependencies are wired up via the `provider` package using a `MultiProvider` relying on `providersRemote` from `lib/config/dependencies.dart`.
* **Data Consumption:** Widgets like `YeLauncherApp` consume domain data (e.g., `MinecraftRepository`) directly via `Consumer`.

## Routing & Navigation
* **Declarative Routing:** Navigation is handled by `go_router` (`^17.2.2`) configured in `lib/routing/router.dart`.
* **State-Based Routes:** The router dynamically consumes the repositories to handle deep linking, web paths, and unauthorized redirects.

## Design System & Theming
* **Immutable Tokens:** Theme tokens are strictly modeled as immutable value objects with static presets, utilizing `AppColors.dark`, `AppColors.light`, and `AppText.defaultTheme`.
* **Centralization:** Keep design values centralized; do not hardcode styles directly into widgets.
* **Typography:** The designated font family is `Montserrat`; ensure assets are properly declared before use.
* **Iconography:** Incorporates icons using `flutter_svg` and `material_symbols_icons`.

## Data Handling & Serialization
* **JSON:** Use `json_serializable` and `json_annotation` for data models, enforcing `fieldRename: FieldRename.snake` for consistency.
* **Data Dependencies:** Utilizes `http` for networking, `archive` for unzipping, and `flutter_secure_storage` / `path_provider` for secure local file management.

## Coding Conventions & Quality
* **Dart Features:** Write functional, declarative code using `async`/`await` for operations, `Stream` for events, switch expressions/pattern matching, and Records for multiple return values.
* **Immutability:** Always favor composition over inheritance and keep `StatelessWidget` and data classes completely immutable using `const` constructors.
* **Logging:** Avoid `print` or `debugPrint` directly; instead, log using the `logging` package (`Logger` class). The root logger captures `Level.FINE` messages.
* **Linting:** Code must strictly follow `flutter_lints` rules defined in `analysis_options.yaml`. Always format via `dart_format`.

## Critical Workflows
* **Install dependencies:** `flutter pub get`
* **Run static analysis:** `flutter analyze`
* **Run tests:** `flutter test`
* **Run desktop app (Windows):** `flutter run -d windows`
* **Code generation (e.g., Mocks/JSON):** `dart run build_runner build`

## Testing and PR Validation
* Maintain logic for existing tests (e.g., `test/minecraft_launch_test.dart`) when modifying core systems.
* Update unit and widget tests when making modifications to router or provider configurations.
* Keep Pull Requests tightly focused, coupling theme or root-wiring changes directly with their relevant widget tests.