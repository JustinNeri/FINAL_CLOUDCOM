# Monster Control Center

A location-based monster-catching app built with Flutter. Players sign in, detect monsters
near their GPS position, catch them, and see their catches on a map and a leaderboard.

Live web version: https://pokemon-ip-tau.vercel.app

## Features

- Player accounts: create, log in, update profile and password
- Add monsters with a spawn point and radius picked on a map
- Detect and catch nearby monsters (with flashlight, sound and vibration alert)
- Edit and delete caught monsters
- Map of a player's catches and a Top Hunters leaderboard
- Start/stop the backend cloud instance from the app

## Project layout

| Path | What it is |
|------|------------|
| `lib/main.dart` | App entry, saved login, dashboard and navigation drawer |
| `lib/theme.dart`, `lib/widgets.dart` | App-wide theme and shared UI pieces |
| `lib/api.dart` | Backend addresses, HTTP client and response parsing |
| `lib/session.dart`, `lib/location.dart` | Remembered login and GPS access |
| `lib/caught_monsters.dart`, `lib/instance_status.dart` | Shared data models for monsters and the server instance |
| `lib/*_screen.dart`, `lib/*_monster.dart` | One file per screen |
| `test/` | Widget and unit tests using a fake server (`test/helpers.dart`) |
| `backend/` | CORS helper and setup guide for the PHP server |
| `vercel.json` | Builds the Flutter web app on Vercel |

## Running locally

```bash
flutter pub get
flutter run                     # phone or emulator
flutter run -d chrome           # web
flutter test
```

The app talks to a PHP backend. Its address defaults to the one in `lib/api.dart`; override it
without editing code:

```bash
flutter run --dart-define=API_BASE=https://your-backend.example.com
```

## Deploying

Every push to `main` deploys to Vercel. In Vercel's environment variables, set:

- `API_BASE` – https address of the PHP backend
- `INSTANCE_API` – URL of the instance start/stop API (optional)

The website only works once the backend is served over https with CORS enabled.
See [backend/SETUP.md](backend/SETUP.md).
