# 📱 ExamTrack

ExamTrack is a Flutter-based mobile application designed to help students organize and track important examinations and opportunities in one place.

The application brings together:

* 🏛️ Government Exams
* 🎓 College Exams
* 💼 Placement Exams
* 📝 Entrance Exams

Users can browse exams, search and filter opportunities, view exam dates on a calendar, maintain a personal **My Exams** list, track application status, and monitor preparation progress.

---

## ✨ Features

### 🏠 Home

* View today's exams
* View upcoming exams
* Search exams and organizations
* Filter exams by category
* Open detailed exam information

### 📅 Exam Calendar

* Monthly calendar view
* Exam dates displayed on the calendar
* Select a date to view scheduled exams

### 📋 My Exams

Add important exams to your personal list.

The application remembers:

* Selected exams
* Application status
* Preparation progress

### 🔔 Alerts & Reminders

View selected exams and their:

* Exam dates
* Application status
* Reminder information

### 👤 Profile

Provides a place for student-related preferences and application settings.

### 📊 Exam Details

Each exam can contain:

* Exam name
* Organization
* Category
* Exam date
* Application window
* Eligibility
* Exam mode
* Application fee
* Syllabus
* Description
* Source information
* Preparation progress
* Application status

---

# 🛠️ Technology Stack

* **Flutter**
* **Dart**
* **Material 3**
* **SharedPreferences**
* **Table Calendar**
* **Intl**

### Packages

The project uses the following main packages:

```yaml
table_calendar
shared_preferences
intl
```

The exact dependency versions are defined in:

```text
pubspec.yaml
```

and the resolved versions are recorded in:

```text
pubspec.lock
```

---

# 📁 Project Structure

```text
ExamTrack/
│
├── android/              # Android platform configuration
├── ios/                  # iOS platform configuration
├── linux/                # Linux platform configuration
├── macos/                # macOS platform configuration
├── web/                  # Web platform configuration
├── windows/              # Windows platform configuration
│
├── lib/
│   └── main.dart         # Main application source
│
├── test/                 # Flutter tests
│
├── assets/               # Application assets
│
├── pubspec.yaml          # Project configuration and dependencies
├── pubspec.lock          # Resolved dependency versions
├── README.md             # Project documentation
└── .gitignore            # Files ignored by Git
```

---

# 💻 Requirements

Before running ExamTrack locally, install:

1. Flutter SDK
2. Android Studio
3. Android SDK
4. Git

Verify Flutter:

```bash
flutter --version
```

Verify the development environment:

```bash
flutter doctor
```

For Android development, make sure the Android toolchain is working.

---

# 🚀 Getting Started

## 1. Clone the Repository

Open a terminal and run:

```bash
git clone https://github.com/DurgaPrasad127/ExamTrack.git
```

Replace:

```text
DurgaPrasad127
```

with the GitHub username that owns the repository.

Example:

```bash
git clone https://github.com/DurgaPrasad127/ExamTrack.git
```

---

## 2. Enter the Project

```bash
cd ExamTrack
```

---

## 3. Install Flutter Dependencies

Run:

```bash
flutter pub get
```

Flutter will read the dependencies from:

```text
pubspec.yaml
```

---

## 4. Check Available Devices

```bash
flutter devices
```

You can use:

* Android phone
* Android emulator
* Chrome
* Windows
* Other supported Flutter platforms

---

## 5. Run the Application

To let Flutter choose a connected device:

```bash
flutter run
```

To run on a specific Android device:

```bash
flutter run -d DEVICE_ID
```

Example:

#Your Own Device ID

```bash
flutter run -d d58129577d75
```

---

# 📱 Running on an Android Phone

### Enable Developer Options

On the Android phone:

1. Open Settings
2. Open About Phone
3. Tap Build Number several times
4. Enable Developer Options

Then enable:

```text
USB Debugging
```

Connect the phone to the computer using USB.

Check:

```bash
adb devices
```

Then:

```bash
flutter devices
```

Finally:

```bash
flutter run
```

---

# 🔨 Build an APK

To create a debug APK:

```bash
flutter build apk --debug
```

The APK will be generated inside the Flutter build directory.

For a release APK:

```bash
flutter build apk --release
```

The release APK can then be installed on compatible Android devices.

---

# 🧹 Useful Flutter Commands

Get dependencies:

```bash
flutter pub get
```

Clean the project:

```bash
flutter clean
```

Check the environment:

```bash
flutter doctor
```

List connected devices:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

Build APK:

```bash
flutter build apk --release
```

Analyze the project:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

---

# 🔄 Development Workflow

After cloning the repository:

```bash
git pull
```

Make your changes.

Check the project:

```bash
flutter analyze
```

Run the application:

```bash
flutter run
```

Then check Git:

```bash
git status
```

Stage your changes:

```bash
git add .
```

Create a commit:

```bash
git commit -m "Describe your changes"
```

Push to GitHub:

```bash
git push
```

---

# 🌿 Recommended Git Workflow

The main branch is:

```text
main
```

For new features, you can create a separate branch:

```bash
git checkout -b feature/new-feature
```

After making changes:

```bash
git add .
git commit -m "Add new feature"
git push -u origin feature/new-feature
```

Then create a Pull Request on GitHub.

---

# 🔐 Security

Do **not** commit:

* Passwords
* API keys
* Access tokens
* Private credentials
* Secret configuration files
* Personal sensitive information

Never put secrets directly inside source code.

---

# 📌 Current Project Status

ExamTrack currently provides the foundation for an exam and opportunity tracking application.

The current implementation includes:

* Home screen
* Search
* Category filtering
* Exam calendar
* My Exams
* Exam details
* Application status
* Preparation progress
* Alerts section
* Profile section
* Local persistence

---

# 🔮 Future Improvements

Possible future development:

* Real-time exam database
* Official exam notifications
* Verified exam sources
* Application deadline reminders
* Firebase notifications
* User authentication
* Cloud synchronization
* Personalized exam recommendations
* Advanced preparation tracking
* Study schedules
* Exam-wise syllabus tracking
* Admit-card notifications
* Results and cutoff tracking
* Backend API
* Admin dashboard
* Production database

---

# 👨‍💻 Development

ExamTrack is developed using Flutter and Dart.

The project is intended to evolve into a centralized platform where students can manage their academic, recruitment, government, and entrance examination opportunities.

---

## 📄 License

Add your preferred open-source license before distributing the project publicly.

---

## ⭐ Contributing

Contributions are welcome.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the application
5. Commit your changes
6. Push your branch
7. Open a Pull Request

---

## 📞 Support

If you encounter a problem:

1. Run:

```bash
flutter doctor
```

2. Run:

```bash
flutter analyze
```

3. Check the Flutter and Dart versions:

```bash
flutter --version
```

4. Create an issue in the GitHub repository with the error details.

---

**ExamTrack — Track your exams. Track your opportunities.**
