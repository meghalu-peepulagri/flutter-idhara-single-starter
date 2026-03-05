# iDhara

A Flutter-based IoT motor/pump monitoring and remote control application. iDhara connects to industrial motor starters via MQTT and a REST API, enabling real-time monitoring, control, and diagnostics from a mobile device.

FlutterFlow projects are built to run on the Flutter _stable_ release.

---

## Table of Contents

- [Getting Started](#getting-started)
- [Architecture](#architecture)
- [Features](#features)
  - [Authentication](#authentication)
  - [Dashboard](#dashboard)
  - [Motor Details](#motor-details)
  - [Test Run](#test-run)
  - [Device Settings](#device-settings)
  - [Device Management](#device-management)
  - [Location Management](#location-management)
  - [User Profile](#user-profile)
  - [Notifications](#notifications)
- [Real-Time Communication (MQTT)](#real-time-communication-mqtt)
- [Project Structure](#project-structure)

---

## Getting Started

1. Install Flutter (stable channel).
2. Clone the repository and navigate to the `i_dhara` directory.
3. Run `flutter pub get` to install dependencies.
4. Configure environment variables in `lib/app/core/config/env.dart` (API base URL, MQTT broker, etc.).
5. Run the app with `flutter run`.

---

## Architecture

iDhara follows **GetX MVC** pattern with a clean separation of concerns:

- **Presentation** — Pages, widgets, and controllers (`lib/app/presentation/`)
- **Data** — Models, DTOs, repositories, and services (`lib/app/data/`)
- **Core** — Theme, routing, utilities, and FlutterFlow helpers (`lib/app/core/`)

Real-time motor data is delivered over **MQTT** and merged with REST API responses.

---

## Features

### Authentication

- **Mobile OTP login** — Users log in with a mobile number; an OTP is sent for verification.
- **Registration** — New users can register an account.
- **Session persistence** — Auth tokens are stored in SharedPreferences and restored on app launch.
- **Logout** — Clears session and redirects to the login screen.

---

### Dashboard

The dashboard is the home screen showing all motors assigned to the user.

- Displays a paginated list of motor cards with live MQTT data.
- Each card shows motor name, state (ON/OFF), mode (Auto/Manual), voltage (R/Y/B phases), current (R/Y/B phases), fault status, and signal quality.
- **Location filter** — Filter motors by location using a dropdown.
- **Load more** — Infinite scroll pagination for large motor lists.
- **Pull-to-refresh** — Refreshes motor list and re-subscribes to MQTT topics.
- **Motor toggle** — Turn individual motors ON or OFF directly from the card via MQTT command.
- **Mode toggle** — Switch a motor between Auto and Manual mode from the card via MQTT command.
- **Test Run** — Initiate or complete a test run for a motor directly from the dashboard card.

---

### Motor Details

Accessed by tapping a motor card on the dashboard. Provides an in-depth view of a single motor with three tabs:

#### Tab 1 — Motor Mode

- Displays the current operating mode: **Auto** or **Manual**.
- Toggle switch to change the mode.
- Mode change is sent via MQTT; the UI waits for an acknowledgement before allowing another change (`_ackTimeout = 13 seconds`).
- Toggle is disabled while waiting for acknowledgement or when the motor cannot accept mode commands.

#### Tab 2 — Motor Runtime

- Visual timeline chart showing motor ON/OFF segments and power ON/OFF segments for a selected date or date range.
- **Date navigation** — Left/right arrows to move day by day.
- **Date range picker** — Select a custom date range.
- Displays total motor run time and total power run time in `h m sec` format.
- Data is fetched from the analytics REST API and converted to chart segments.

#### Tab 3 — Motor Logs

- Paginated activity log for the motor.
- **Filters** (via popup menu):
  - **All** — Shows every log entry.
  - **Faults** — Motor fault events with descriptions and timestamps.
  - **Alerts** — Threshold-based alert events.
  - **ON** — Motor start events.
  - **OFF** — Motor stop events.
  - **MODE** — Mode change events.
- Active filter displayed as a removable chip; tap to clear.
- Infinite scroll loads more entries automatically.

---

### Test Run

Test Run allows a technician to verify motor operation after installation or maintenance.

**Flow:**

1. From the dashboard motor card, tap the **Test Run** action.
2. The app calls the API with status `IN_TEST` to mark the motor as under test (`startTestRun`).
3. The motor can be monitored live via MQTT during the test.
4. Once verification is complete, tap **Complete** to call the API with status `COMPLETED` (`completeTestRun`).

**API statuses:** `IN_TEST` | `COMPLETED`

The feature is implemented in `DashboardController` (`dashboard_controller.dart`) using `DevicesRepository.testRun()` and the `TestRunResponse` model.

---

### Device Settings

Device Settings allow configuration of motor protection parameters. Accessed from the sidebar under **User Settings**.

**Protection Parameters:**

| Parameter | Description |
|-----------|-------------|
| **FLC** | Full Load Current — rated motor current in amps |
| **LVF** | Low Voltage Fault threshold (V) |
| **HVF** | High Voltage Fault threshold (V) |
| **LVR** | Low Voltage Recovery threshold (V) |
| **HVR** | High Voltage Recovery threshold (V) |
| **DRF** | Dry Run Fault threshold (% of FLC) |
| **OLF** | Overload Fault threshold (% of FLC) |
| **LRF** | Low Run Fault threshold (% of FLC) |
| **OLR** | Overload Recovery threshold (% of FLC) |
| **LRR** | Low Run Recovery threshold (% of FLC) |

**Functionality:**

- Settings are fetched from the REST API on page load.
- Editable sliders/fields within allowed min-max limits (`UserSettingsLimits`).
- **Save** — Sends updated values to the API and pushes them to the device via MQTT (`payload` map with `dvc_c` key).
- **Restore Defaults** — Fetches manufacturer default settings and applies them with a confirmation dialog.
- **Acknowledgement** — After settings are pushed, the app polls for device acknowledgement to confirm the device received the new configuration.
- Voltage card and current card components display current live readings alongside editable thresholds.
- Settings page also shows device info: pump name, HP, PCB/MAC address.

Settings are implemented in `SettingsController` and `SettingsWidget` (`settings_controller.dart`, `settings_page.dart`).

---

### Device Management

Manage the physical motor starter devices assigned to the account.

- **Devices list** — Lists all assigned devices with their serial numbers and assigned motors.
- **Add Device** — Assign a new device by entering:
  - Serial number (PCB number) — auto-populated from QR scan.
  - Pump name.
  - Horsepower (HP).
  - Location (auto-detected via GPS or selected from a list; new locations can be added inline).
- **QR Code Scanner** — Scan the device's QR code to pre-fill the serial number on the Add Device form.
- **Edit Device** — Rename a device or change its assigned location.
- **Delete Device** — Remove a device from the account.

---

### Location Management

Locations group motors geographically.

- **View locations** — List of all locations with the number of motors in each.
- **Add Location** — Create a new location by name.
- **Rename Location** — Update a location's name via a bottom sheet.
- **Delete Location** — Remove a location (motors in the location are unassigned).

---

### User Profile

- View and edit user account information.
- Profile settings button card for quick navigation to related settings.

---

### Notifications

iDhara uses **Firebase Cloud Messaging (FCM)** for push notifications and **flutter_local_notifications** to display them on the device.

**Setup (handled in `main.dart`):**

- Firebase is initialised at app startup.
- FCM token is fetched after login and saved to SharedPreferences so the backend can target the device.
- Notification permissions are requested on first launch for both Android (`permission_handler`) and iOS (FCM `requestPermission`).
- A dedicated Android notification channel — `high_importance_channel` — is created with `Importance.max` so notifications appear as heads-up banners.
- Notifications display the iDhara brand logo icon and brand colour (`#1B5E8A`).

**Delivery scenarios:**

| App state | Mechanism | Handler |
|-----------|-----------|---------|
| Foreground | `FirebaseMessaging.onMessage` | Shows a local notification via `flutter_local_notifications` |
| Background / terminated | FCM background isolate | `_firebasemessageBackgroundHandler` shows a local notification |
| Launched from notification | `getNotificationAppLaunchDetails` | Deep-links to the relevant screen on launch |
| Tapped from notification tray | `onMessageOpenedApp` / notification response | Deep-links to the relevant screen |

**Deep-link routing on notification tap:**

The notification title determines where the app navigates. The `motor_id` and `starter_id` fields in the notification payload are used to target the correct motor.

| Notification title contains | Navigation destination |
|-----------------------------|------------------------|
| `state` | Dashboard |
| `mode` | Motor Details — Motor Mode tab |
| `fault` | Motor Details — Logs tab (Faults filter) |
| `alert` | Motor Details — Logs tab (Alerts filter) |
| _(anything else)_ | Dashboard |

**Notification types sent by the backend:**

- **State change** — Motor turned ON or OFF remotely or by schedule.
- **Mode change** — Motor switched between Auto and Manual.
- **Fault** — A protection fault was triggered (e.g. low voltage, overload, dry run).
- **Alert** — A threshold-based alert was raised.

---

## Real-Time Communication (MQTT)

iDhara uses MQTT for live motor telemetry and remote commands.

**Subscriptions:**

Each motor is identified by its MAC address or PCB number. The app subscribes to topics for groups `G01` through `G04` to ensure data is received regardless of which group the device publishes on.

**Telemetry data received per motor:**

- Motor state (ON = 1 / OFF = 0)
- Operating mode (Auto / Manual)
- Line voltage — R, Y, B phases (V)
- Line current — R, Y, B phases (A)
- Power consumption (W)
- Fault code and description
- Signal quality

**Commands published:**

| Command | Payload key | Value |
|---------|-------------|-------|
| Motor ON/OFF | `state` | `1` / `0` |
| Mode change | `mode` | `0` (Manual) / `1` (Auto) |
| Settings update | `dvc_c` | JSON object with protection parameters |

The `MqttService` manages connection, subscriptions, and a `dataUpdateNotifier` that triggers UI rebuilds via `ValueNotifier`.

---

## Project Structure

```
lib/
  app/
    core/
      config/          # Environment variables
      constants/       # App-wide constants
      flutter_flow/    # FlutterFlow theme, widgets, nav utilities
      mixins/          # ConnectivityMixin for auto-retry on reconnect
      services/        # ConnectivityService
      utils/           # Snack bars, dialogs, text fields, loading widgets
    data/
      dto/             # Data transfer objects for API requests
      models/          # Response models (auth, devices, motors, graphs, settings, test_run)
      repository/      # Repository interfaces and implementations
      services/
        mqtt_manager/  # MqttService — connection, subscriptions, commands
        storages/      # SharedPreferences helpers
        weather_service/ # GPS location permission
    presentation/
      components/      # Reusable cards, graphs, tab content, filter sheets
      modules/
        auth/          # Login, OTP, Register screens
        dashboard/     # Dashboard with motor list and MQTT integration
        devices/       # Device list, add, edit screens
        locations/     # Location list, add, rename/delete screens
        motor_details/ # Motor mode, runtime, logs tabs
        settings/      # Device Settings screen
        sidebar/       # Navigation drawer
        user_profile/  # User profile screen
        qr_code/       # QR scanner screen
        splash_screen/ # Splash / auth gate
      routes/          # GetX route definitions
      widgets/         # Shared widgets (app bar, back button, no-data, no-internet)
```
