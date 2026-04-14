# Scrib — Mobile Application Development Report

**Course:** Mobile Application Development  
**Group Members:** Rose-Alice Tsatsu, Joshua Agyemang, Osarume  
**Application Name:** Scrib  
**Platform:** Android (Flutter)  
**Repository:** https://github.com/joshuaagyemang08/Mobile_Dev_Group_Work  

---

## Activity 1: Planning, Case Scenario and Contract

### a. Background Information

**Organisation:** University Student Body — College of Computing and Information Sciences  
**Context:** Higher Education / Academic Productivity

Universities and colleges across the world face a common challenge: students struggle to keep up with the volume and pace of lecture content. Note-taking during lectures is inconsistent — students either write too little, miss key concepts, or spend so much time writing that they stop listening. This problem is especially acute in technical and science-based programmes where lectures are dense and fast-paced.

**Scrib** was conceived as a direct solution to this problem. It is a mobile application built for university students that automatically records lectures, transcribes the audio into text using AI, and then generates structured study materials from the transcript — including summaries, flashcards, key topics, and term definitions.

The target organisation is any university or college student body. The application is designed for individual student use. Its principal purpose is to reduce the cognitive load of note-taking so that students can focus entirely on understanding content during lectures, knowing that Scrib is capturing, processing, and organising everything for them afterward.

**Target Market:**
- Undergraduate and postgraduate university students
- Students with disabilities that make traditional note-taking difficult (e.g., dyslexia, motor impairments)
- Students studying in a second language
- Lecturers who wish to provide auto-generated study aids to their class

**Principal Services the App Provides:**
- Audio recording of lectures (up to several hours)
- Automatic transcription of recorded audio to text
- AI-generated structured notes (summary, flashcards, topics, definitions)
- Cloud storage of all lectures and notes tied to a user account
- Photo capture to supplement notes with images of whiteboards or slides
- Playback of original lecture audio
- Push notifications when AI processing completes

---

### b. Functional and Non-Functional Requirements

**Functional Requirements:**

| # | Requirement |
|---|---|
| FR1 | The app shall allow a user to create an account and log in securely |
| FR2 | The app shall record audio from the device microphone |
| FR3 | The app shall upload the recording to a backend server for processing |
| FR4 | The backend shall transcribe the audio using the AssemblyAI API |
| FR5 | The backend shall generate structured notes from the transcript using GPT-4o-mini |
| FR6 | The app shall display the transcript, summary, flashcards, topics and key terms |
| FR7 | The app shall allow users to attach photos to a lecture (via camera or gallery) |
| FR8 | The app shall play back the original recorded audio |
| FR9 | The app shall send a push notification when notes are ready |
| FR10 | The app shall persist all data to a cloud database across reinstalls |
| FR11 | The app shall allow the user to search and filter their lectures |
| FR12 | The app shall allow the user to delete lectures |
| FR13 | The app shall support dark and light themes |
| FR14 | The app shall allow users to reset their password via email |
| FR15 | The app shall support sign-in via Google account |

**Non-Functional Requirements:**

| # | Requirement |
|---|---|
| NFR1 | The backend server must remain online 24/7 (deployed to cloud, not local) |
| NFR2 | Authentication must be secure — passwords must not be stored in plain text |
| NFR3 | User data must be isolated — a user can only access their own lectures |
| NFR4 | The app must respond within 2 seconds for all local operations |
| NFR5 | The app must work on Android 8.0 (API 26) and above |
| NFR6 | The UI must remain usable on screen sizes from 5 to 7 inches |

**Local Resources Used (≥ 4 required):**

| Resource | Usage in Scrib |
|---|---|
| **Microphone** | Recording lecture audio |
| **Camera / Gallery** | Capturing photos to attach to lectures |
| **Audio Playback (Speaker)** | Playing back recorded lecture audio |
| **Push Notifications** | Alerting the user when AI notes are ready |
| **Splash Screen** | Branded loading screen on app launch |

---

## Activity 2: Prototyping, Specification, Architecture & Design

### Application Overview

Scrib follows a **client-server architecture**. The Flutter mobile app acts as the client. A Python FastAPI server hosted on Fly.io handles all AI processing. Supabase provides authentication and a PostgreSQL cloud database.

### High-Level Architecture / Communication Flow

```
┌─────────────────────────────────────────────────┐
│                 Flutter App (Client)             │
│                                                  │
│  Auth Screen → Home Screen → Recording Screen   │
│       ↓              ↓              ↓            │
│  Supabase Auth   Supabase DB    Audio File       │
│                                     ↓            │
│              Processing Screen      │            │
│                     ↓               │            │
│         ┌───────────────────────────┘            │
│         ▼                                        │
│   Python Backend (Fly.io)                        │
│         │                                        │
│   LangGraph Pipeline:                            │
│   [Upload] → [Transcribe/AssemblyAI]             │
│           → [Generate Notes/GPT-4o-mini]         │
│           → [Save to Supabase DB]                │
│                                                  │
│  Notes Screen ← Supabase DB                      │
└─────────────────────────────────────────────────┘
```

### Key Modules and Assigned Members

| Module | Description | Assigned To |
|---|---|---|
| Authentication (Login, Register, Forgot Password) | Supabase Auth integration, form validation, Google Sign-In | Rose-Alice |
| Home Screen & Search | Lecture listing, search, filter by subject, stats | Joshua |
| Recording Screen | Microphone recording, timer, waveform animation | Joshua |
| Notes Screen | Tabs: Summary, Transcript, Flashcards, Topics, Photos | Rose-Alice |
| Profile Screen | Edit name/photo, theme toggle, logout | Osarume |
| Notification Settings | Toggle preferences for push notifications | Osarume |
| Python Backend | FastAPI server, LangGraph pipeline, AssemblyAI, OpenAI | Joshua |
| Cloud Database (Supabase) | Schema design, RLS policies, data persistence | Rose-Alice |
| Theme System | Dark/Light theme, ThemeProvider, shared palette | Osarume |

### Users and Use Case Diagram

**Actors:**
- **Student (Primary User)** — creates an account, records lectures, views notes
- **System (Backend)** — processes audio, generates notes, sends notifications

```
Student
  ├── Register / Login
  ├── Sign in with Google
  ├── Reset Password
  ├── Record Lecture
  │     └── System: Upload → Transcribe → Generate Notes → Notify
  ├── View Notes
  │     ├── Read Summary
  │     ├── Study Flashcards
  │     ├── View Transcript
  │     ├── Browse Topics
  │     └── View / Add Photos
  ├── Search & Filter Lectures
  ├── Delete Lecture
  ├── Edit Profile
  └── Toggle Dark/Light Theme
```

### Database Schema (Supabase PostgreSQL)

**Table: `lectures`**

| Column | Type | Description |
|---|---|---|
| id | UUID (PK) | Unique lecture identifier |
| user_id | UUID (FK) | References Supabase auth.users |
| title | TEXT | Lecture title |
| subject | TEXT | Subject / course name |
| audio_path | TEXT | Local path to recorded audio file |
| duration_seconds | INTEGER | Length of recording in seconds |
| status | TEXT | uploading / transcribing / generatingNotes / completed / failed |
| upload_progress | FLOAT | Upload progress 0.0–1.0 |
| transcript | TEXT | Full transcript from AssemblyAI |
| notes_json | JSONB | AI-generated notes (summary, flashcards, topics, key terms) |
| photo_paths | TEXT[] | Array of local photo file paths |
| error_message | TEXT | Error detail if status = failed |
| recorded_at | TIMESTAMPTZ | When the lecture was recorded |
| created_at | TIMESTAMPTZ | Row creation timestamp |

**Row Level Security:** Each user can only SELECT, INSERT, UPDATE, DELETE their own rows (`user_id = auth.uid()`).

---

## Activity 3: Implementation

### Tools, Libraries, Frameworks, APIs and Languages

**Mobile Frontend:**

| Tool / Library | Version | Purpose |
|---|---|---|
| Flutter | 3.x | Cross-platform mobile UI framework |
| Dart | 3.x | Programming language |
| Provider | ^6.1.2 | State management |
| supabase_flutter | ^2.5.0 | Authentication + database client |
| google_sign_in | ^6.2.1 | Native Google OAuth sign-in |
| record | ^6.2.0 | Microphone audio recording |
| audioplayers | ^6.1.0 | Audio playback of recordings |
| image_picker | ^1.1.2 | Camera and gallery photo capture |
| flutter_local_notifications | ^18.0.0 | Push notifications |
| flutter_markdown | ^0.7.3 | Rendering markdown notes |
| flutter_animate | ^4.5.0 | UI animations |
| shared_preferences | ^2.2.3 | Local settings (theme, notification toggles) |
| path_provider | ^2.1.3 | Local file system access |
| google_fonts | ^6.2.1 | Inter font family |
| permission_handler | ^11.3.0 | Runtime permissions (mic, camera, notifications) |
| intl | ^0.19.0 | Date formatting |

**Backend:**

| Tool / Library | Purpose |
|---|---|
| Python 3.11 | Backend language |
| FastAPI | HTTP API server |
| LangGraph | Pipeline orchestration (upload → transcribe → notes → cleanup) |
| LangChain | AI model abstraction layer |
| AssemblyAI | Speech-to-text transcription API |
| OpenAI GPT-4o-mini | AI note generation from transcript |
| Uvicorn | ASGI server |
| Docker | Containerisation for deployment |
| Fly.io | Cloud hosting (always-on, min 1 machine running) |

**Database & Auth:**

| Service | Purpose |
|---|---|
| Supabase (PostgreSQL) | Cloud relational database for lecture storage |
| Supabase Auth | Email/password and Google OAuth authentication |
| SharedPreferences | Device-local settings only (theme, notification toggles) |

### Implementation Description

The app is structured around a **Provider-based state management** pattern. `LectureProvider` holds the list of lectures and communicates with Supabase. `ThemeProvider` manages dark/light mode persistence.

**Recording Flow:**
1. User taps "Record Lecture" on the Home screen
2. `RecordingScreen` uses the `record` package to capture audio from the microphone
3. On stop, the audio file is saved locally and a new `Lecture` object is created with status `uploading`
4. The user is navigated to `ProcessingScreen` while the backend processes in the background

**Backend Pipeline (LangGraph):**
1. **Node 1 — Upload:** Receives the audio file via HTTP POST
2. **Node 2 — Transcribe:** Sends audio to AssemblyAI, polls for completion
3. **Node 3 — Generate Notes:** Sends transcript to GPT-4o-mini with a structured prompt requesting summary, flashcards, topics and key terms in JSON
4. **Node 4 — Save:** Updates the Supabase `lectures` table with the results
5. **Node 5 — Cleanup:** Deletes temporary audio file from server

**Authentication Flow:**
- Email/password: handled by `supabase_flutter` `signInWithPassword` / `signUp`
- Google Sign-In: `google_sign_in` package retrieves an ID token, passed to Supabase `signInWithIdToken`
- Password reset: `resetPasswordForEmail` sends a reset link to the user's inbox
- Email verification: after sign-up, user is directed to `EmailVerificationScreen` with a resend option

**Data Persistence:**
- All lectures are stored in Supabase PostgreSQL, not on the device
- Row Level Security ensures each user only sees their own data
- On login, `LectureProvider.loadLectures()` fetches all lectures for the authenticated user
- This means data survives app reinstalls and is accessible from any device

### Screens Implemented

| Screen | Description |
|---|---|
| SplashScreen | Checks auth session, routes to Home or Onboarding |
| OnboardingScreen | 3-slide first-time intro |
| AuthScreen | Login and Register with validation and password strength meter |
| ForgotPasswordScreen | Email-based password reset via Supabase |
| EmailVerificationScreen | Post-signup verification prompt with resend and cooldown |
| HomeScreen | Lecture list, search, subject filter, stats dashboard |
| RecordingScreen | Audio recording with timer and waveform animation |
| ProcessingScreen | Live pipeline progress (upload → transcribe → notes) |
| NotesScreen | 5-tab view: Summary, Transcript, Flashcards, Topics, Photos |
| ProfileScreen | Edit name/photo, theme toggle, notification settings, logout |
| NotificationSettingsScreen | Toggle individual notification types |

---

## Activity 4: Testing, Deployment & Presentation

### Deployment

**Backend:**  
The Python FastAPI server is deployed to **Fly.io** as a Docker container.  
- URL: `https://scrib-backend.fly.dev`  
- Configuration: `min_machines_running = 1` ensures the server never sleeps  
- Environment variables (API keys) are stored as Fly.io secrets, never in source code  

**Database & Auth:**  
Hosted on **Supabase** (managed PostgreSQL + Auth).  
- Project URL: `https://aumjypligwftjfcxqoci.supabase.co`  
- Row Level Security is enabled on all tables  

**Mobile App:**  
- Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`  
- Release APK: `build/app/outputs/flutter-apk/app-release.apk`  
- Build command: `flutter build apk --release`

### Test Cases

| # | Feature | Test | Expected Result |
|---|---|---|---|
| T1 | Registration | Register with valid email and password | Account created, email verification screen shown |
| T2 | Login | Login with correct credentials | Navigates to Home screen |
| T3 | Login | Login with wrong password | Error message shown |
| T4 | Forgot Password | Enter registered email | Reset email sent, success screen shown |
| T5 | Google Sign-In | Tap "Continue with Google" | Google account picker opens, signs in successfully |
| T6 | Record Lecture | Tap record, speak, tap stop | Audio file saved, processing begins |
| T7 | Notes Generation | Wait for processing to complete | Summary, flashcards, topics and transcript appear |
| T8 | Push Notification | Complete a recording | Notification fires: "Notes are ready" |
| T9 | Camera | Tap camera icon in Notes Photos tab | Camera opens, photo attaches to lecture |
| T10 | Audio Playback | Tap play in Notes screen | Original lecture audio plays with progress bar |
| T11 | Search | Type in search bar on Home | Lectures filter in real time |
| T12 | Delete | Swipe left on a lecture card | Lecture deleted from list and database |
| T13 | Theme Toggle | Toggle in Profile screen | App switches between dark and light theme |
| T14 | Logout | Tap Logout in Profile | Confirms dialog, signs out, returns to Auth screen |
| T15 | Data Persistence | Uninstall and reinstall app, log in | All previous lectures visible |

---

## Activity 5: App Store (Optional)

The application is not yet submitted to the Google Play Store. For future submission, the following steps would be required:

1. Change application ID from `com.example.scrib` to a unique identifier (e.g., `com.scrib.app`)
2. Generate a production signing keystore (separate from the debug keystore)
3. Register the production SHA-1 with Google Cloud Console
4. Complete Google Play Console registration and store listing
5. Submit for review

---

*Report prepared by: Rose-Alice Tsatsu, Joshua Agyemang, Osarume*  
*Submission Date: April 2026*
