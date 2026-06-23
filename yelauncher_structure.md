# YeLauncher Project Structure
**Stack:** Flutter/Dart (Windows/macOS/Linux)
**Architecture:** Clean Architecture (Data/Domain/UI) + MVVM
**Domain:** Minecraft Launcher (Vanilla, Forge, Fabric, MS Auth)

## Core Tree (`/lib`)
```text
lib/
├── config/                 # DI (dependencies.dart) & Asset mapping (assets.dart)
├── data/                   # Data Layer
│   ├── repositories/       # Abstractions & Impls (Local/Remote)
│   │   ├── instances/      # Minecraft instance management
│   │   ├── java/           # Java runtime management
│   │   ├── minecraft/      # Vanilla version manifests
│   │   └── mod_loader/     # Fabric & Forge integration
│   └── services/           # External & System Operations
│       ├── api/            # Clients (Microsoft, Minecraft, Forge, Fabric)
│       │   ├── models/     # DTOs (e.g., version_manifest_api_model)
│       │   └── strategies/ # Version requirement parsing strategies
│       ├── download_service.dart   # File fetching
│       ├── file_service.dart       # Local FS ops
│       ├── instance_service.dart   # Instance lifecycle
│       └── secure_storage_service.dart # Auth token storage
├── domain/                 # Business Logic & Core Models
│   └── models/             # download, instance, minecraft, mod_loader, task
├── routing/                # App navigation (router.dart, routes.dart)
├── ui/                     # Presentation Layer (MVVM)
│   ├── authentication/     # Login UI + ViewModel
│   ├── core/               # Reusable Widgets (Buttons, Inputs, Themes)
│   └── instances/          # Instance Grid/Cards + Creation Dialogs + ViewModels
├── utilities/              # Helpers (Result monad, CLI command wrapper)
├── main.dart               # Prod entry point
└── main_development.dart   # Dev entry point