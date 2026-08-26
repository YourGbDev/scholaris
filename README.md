# Scholaris

> **Status: 🚧 In Development** — This repository contains the active implementation of Scholaris and is not yet production-ready.

Scholaris is a scholarship-matching mobile application that helps students discover scholarships based on their eligibility profile. Built with **Flutter** and **Dart**, with **Supabase** (backed by **PostgreSQL**) planned as the backend.

## Status

This project is **currently in development (WIP)**. The current state of this repository is an early Flutter project foundation:

- ✅ Flutter app skeleton created (Android, iOS, and web targets)
- ✅ Minimal app shell with a placeholder home screen
- ⏳ Planned features below are **not yet implemented**

This is **not** a released or production-ready product.

## Overview

Discovering scholarships is fragmented: opportunities are scattered across university bulletins, government pages, and third-party portals, each with its own format and deadlines. Students have to manually check eligibility criteria one scholarship at a time, which is time-consuming and easy to miss.

Scholaris aims to centralize this by letting students build a single eligibility profile and matching them against scholarship opportunities in one place.

## Planned / Core Functionality

The following features are **planned** for Scholaris and are not yet implemented:

- **Eligibility profile** — students build a profile covering their academic background, course, and relevant details
- **Scholarship matching** — discover scholarships that match the student's eligibility profile
- **Bookmarks** — save and organize interesting opportunities
- **Application tracking** — track the status of scholarship applications
- **Deadline reminders** — receive notifications for upcoming scholarship deadlines

## Technology Stack

| Layer      | Technology                                  | Status        |
| ---------- | ------------------------------------------- | ------------- |
| Frontend   | Flutter (Dart)                              | In development |
| Backend    | Supabase (PostgreSQL)                       | Planned       |
| Auth       | Supabase Auth (planned)                     | Planned       |

## Development Status

- **Current phase:** Initial project setup / foundation
- **Implemented:** Flutter project scaffold, app entry point, minimal home screen, initial widget test
- **In progress:** Core application architecture

## Architecture Direction

The project uses a standard Flutter project structure:

```
lib/
  main.dart              # App entry point
  app.dart               # Root ScholarisApp widget
  screens/               # App screens
    home_screen.dart     # Minimal placeholder home screen
```

Planned technical direction:

- Feature-based organization under `lib/features/` as functionality is added
- Supabase client integration for backend access and authentication
- Separate concerns between UI, state management, and data access as the app grows

## Future Plans

1. Set up Supabase schema (students, scholarships, bookmarks, applications) with PostgreSQL
2. Implement eligibility profile creation and editing
3. Implement scholarship search and matching
4. Add bookmarks and application tracking
5. Add deadline reminder notifications
6. Publish initial release for Android and iOS

## About

This is an **independent / student project**. Scholaris is built as a personal learning and portfolio project and is not affiliated with any organization.

## Getting Started

To run the app locally, ensure you have the [Flutter SDK](https://flutter.dev) installed, then:

```bash
flutter pub get
flutter run
```

To run the tests:

```bash
flutter test
```

## License

No license has been chosen yet.
