<div align="center">
  <h1>🚀 HabitFlow</h1>
  <p><strong>Build habits, unlock tiers, compete with friends</strong></p>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
  [![License](https://img.shields.io/badge/License-Source%20Available-orange.svg)](LICENSE)
  [![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)](https://github.com/ankitraj4096/HabitFlow/releases)
</div>

---

## 📖 About

**HabitFlow** is a productivity and task management app designed to help you build better habits through a **competitive and friendly environment**. The app combines task management with gamification to make productivity fun and rewarding!

### Key Highlights
- ⏱️ **Timed task tracking** with pause/resume functionality and beautiful water droplet animations
- 🔄 **Daily recurring tasks** with calendar heatmap and history tracking
- 🎯 **17-tier progression system** from The Starter to The Ascended (100,000 tasks)
- 👥 **Social accountability** features to connect with friends and assign tasks
- 🏆 **Achievements & badges** with animated icons for top tiers
- 🎨 **Custom themes** that unlock as you progress through tiers
- 📝 **Note-taking system** for detailed task planning with cloud sync
- 🗓️ **Activity heatmap** showing your daily completion history
- 🧹 **Automatic cleanup** of old data (3+ months) for optimal performance
- 🔔 **Background timer notifications** to track tasks from anywhere

---

## ✨ Features 

### 🎯 Core Functionality
- **Task Management** - Create, edit, and delete tasks with ease
- **Timer System** - Track time spent on each task with pause/resume and visual progress indicators
- **Recurring Tasks** - Create daily habits that automatically reset each day
- **Note-Taking** - Add detailed notes and descriptions to any task with real-time cloud sync
- **Auto-completion** - Tasks automatically mark complete when timers finish
- **Smart Cleanup** - Automatic daily cleanup of tasks and recurring history older than 3 months
- **Offline Support** - View cached data offline, syncs when reconnected
- **Background Timers** - Timers run in background with persistent notifications

### 🏆 Progression & Rewards
- **17 Unique Tiers** - Progress from "The Starter" (0 tasks) to "The Ascended" (100,000 tasks)
- **Dynamic Themes** - Each tier unlocks unique gradient color schemes
- **Animated Tiers** - Top 2 tiers (Luminary & Ascended) feature special pulsating animations
- **Achievement System** - Earn badges for milestones and daily streaks
- **Activity Heatmap** - View your daily completion activity in a beautiful calendar heatmap
- **Statistics Dashboard** - View detailed analytics, completion history, and progress tracking
- **Progress Tracking** - Real-time progress bars showing tasks remaining to next tier
- **Lifetime Stats** - Track total tasks completed across all time

### 👥 Social Features
- **Friend System** - Add friends by username and build accountability
- **Task Assignment** - Assign both regular and recurring tasks to friends
- **Friend Profiles** - View friends' tiers, stats, heatmaps, and tier colors
- **View Friend Activity** - Tap any date on a friend's heatmap to see their completed tasks for that day
- **Friend Tier Themes** - Friend profiles display their unique tier colors
- **Activity Feed** - See friends' achievements and progress
- **Inbox System** - Manage pending task requests with accept/reject/modify options
- **Privacy Controls** - Friends only see limited information (username, tier, heatmap)

### 📊 Tracking & History
- **Heatmap Calendar** - Visual representation of your daily activity
- **Daily Task View** - Tap any date to see all tasks completed that day
- **Recurring Task History** - Track your daily habit streaks with calendar view
- **Task Filtering** - View all tasks, active tasks, or completed tasks
- **Search Functionality** - Find tasks quickly by name
- **Completion Statistics** - Track your progress over time

### 🎨 Customization
- **Theme Selection** - Choose from any unlocked tier theme
- **Auto Theme Mode** - Colors automatically update as you progress
- **Manual Theme Lock** - Select your favorite theme manually
- **Profile Customization** - Edit username and track personal statistics
- **Gradient Themes** - Multi-color gradients for higher tiers
- **Custom Toasts** - Beautiful animated toast notifications

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| **Frontend** | Flutter & Dart |
| **Backend** | Firebase (Authentication, Firestore, Cloud Messaging) |
| **State Management** | Provider (TierThemeProvider, UserStatsProvider) |
| **UI/UX** | Material Design, Custom Animations, Water Droplet Timer |
| **Database** | Firebase Firestore (Cloud + Local Caching) |
| **Notifications** | flutter_local_notifications, Background Services |
| **Additional Packages** | url_launcher, flutter_slidable, intl, flutter_lucide, flutter_heatmap_calendar |

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0 or higher)
- [Dart SDK](https://dart.dev/get-dart) (3.0 or higher)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/downloads)
- Android device or emulator (Android 5.0+ / API 21+)

## 🛠️ Installation Steps

### 1. Clone the repository
```bash
git clone https://github.com/ankitraj4096/HabitFlow.git
cd HabitFlow
```

### 2. Install dependencies
```bash
flutter pub get
```

---

## 🔥 Firebase Setup

### 1. Create a Firebase project
- Go to [Firebase Console](https://console.firebase.google.com/)
- Enable **Authentication (Email/Password)**
- Create a **Firestore Database**

### 2. Download configuration files
- `google-services.json` → Place in `android/app/`
- `GoogleService-Info.plist` → Place in `ios/Runner/` *(for iOS support)*

---

## 📘 Configure Firestore Database

### Collections structure:

#### `users` collection:
```json
{
  "username": "string",
  "email": "string",
  "lifetimeCompletedTasks": 0,
  "createdAt": "timestamp"
}
```

#### `user_notes` subcollection (under userID):
```json
{
  "taskName": "string",
  "hasTimer": "boolean",
  "elapsedSeconds": "number",
  "isCompleted": "boolean",
  "completedAt": "timestamp",
  "isRecurring": "boolean",
  "status": "accepted | pending | rejected",
  "assignedBy": "string (optional)",
  "assignedByUsername": "string (optional)"
}
```

#### `recurringHistory` collection:
Path: `recurringHistory/{userId}/{taskId}/completions/dates/{YYYY-MM-DD}`
```json
{
  "completedAt": "timestamp",
  "taskName": "string",
  "duration": "number"
}
```

---

## 🔒 Firestore Security Rules

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    match /user_notes/{userId}/notes/{noteId} {
      allow read, write: if request.auth.uid == userId;
    }

    match /recurringHistory/{userId}/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }

    match /chat_rooms/{roomId}/messages/{messageId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## ▶️ Run the App
```bash
flutter run
```

## 📦 Build APK (Android)
```bash
flutter build apk --release
```

The APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📂 Project Structure

```
lib/
├── Pages/
│   ├── login_components/          # Login & signup screens
│   │   ├── login.dart
│   │   ├── register.dart
│   │   └── main_page.dart
│   └── ui_components/             # Main app UI
│       ├── home_page.dart         # Main dashboard with tasks
│       ├── friend_components/     # Friend management
│       │   ├── friend_list.dart
│       │   ├── friend_profile.dart
│       │   ├── add_friend.dart
│       │   └── friend_tasks_manager.dart
│       └── profile_page_components/ # Profile & settings
│           ├── achievements.dart
│           ├── settings.dart
│           ├── user_stats.dart
│           └── profile_page.dart
│
├── component/                     # Reusable widgets
│   ├── achievements.dart           # Achievement badges
│   ├── custom_toast.dart           # Custom toast notifications
│   ├── water_droplet.dart          # Timer animation widget
│   ├── textfield.dart              # Custom fields
│   ├── todolist.dart               # Task card widget
│   ├── heat_map.dart               # Activity heatmap
│   ├── daily_task_show.dart        # Daily completed tasks view
│   └── recurring_history_page.dart # Recurring task history
│
├── services/
│   ├── auth/                       # Firebase authentication
│   │   └── auth_service.dart
│   ├── notes/                      # Firestore services
│   │   ├── firestore.dart          # Main database service
│   │   └── user_stats_provider.dart# User statistics provider
│   └── clean_up_service.dart       # Automatic data cleanup
│
├── themes/
│   └── tier_theme_provider.dart    # Theme management & tier colors
│
├── helper/
│   └── helper_function.dart        # Utility functions
│
└── main.dart                       # App entry point with splash screen
```


## 🎯 Tier Progression System

HabitFlow features **17 progression tiers**, each unlocked by completing tasks:

| Tier | Name | Tasks Required | Description | Special Features |
|:----:|------|:--------------:|-------------|------------------|
| 1 | The Starter | 0 | Welcome! Your journey begins here | Default theme |
| 2 | The Awakened | 10 | You've taken your first steps to greatness! | Purple-pink gradient |
| 3 | The Seeker | 50 | You're discovering your path | Bronze theme |
| 4 | The Novice | 100 | Learning the ropes | Green theme |
| 5 | The Apprentice | 250 | Building strong habits | Orange theme |
| 6 | The Adept | 500 | You've mastered the basics! | Orange-red gradient |
| 7 | The Disciplined | 1,000 | Discipline is your strength! | Purple theme |
| 8 | The Specialist | 2,500 | Specialized excellence achieved! | Pink theme |
| 9 | The Expert | 5,000 | True expertise unlocked! | Indigo theme |
| 10 | The Vanguard | 10,000 | Leading the way to greatness! | Red theme |
| 11 | The Sentinel | 15,000 | Watchful and unstoppable! | Cyan theme |
| 12 | The Virtuoso | 25,000 | Perfection in every task! | Teal theme |
| 13 | The Master | 40,000 | Mastery achieved! | Gold theme |
| 14 | The Grandmaster | 60,000 | Legendary prowess! | Green theme |
| 15 | The Titan | 75,000 | Unshakable and mighty! | Blue theme |
| 16 | The Luminary | 90,000 | Shining beacon of excellence! | ✨ **Animated gold gradient** |
| 17 | The Ascended | 100,000 | Beyond limits. Truly transcendent! | ✨ **Animated dark gradient** |

### Progression Milestones
- **Beginner (0-250)**: Learn the basics and build consistency
- **Intermediate (250-5K)**: Develop strong habits and discipline
- **Advanced (5K-40K)**: Expert-level commitment and mastery
- **Legendary (40K-100K)**: Elite status with special animated themes

---

## 🔄 Recurring Tasks Feature

### What Are Recurring Tasks?
Recurring tasks are daily habits that automatically reset every day at midnight. Perfect for tracking:
- 🏋️ Daily exercise
- 📚 Reading sessions
- 🧘 Meditation practice
- ✍️ Journaling
- 💻 Coding practice
- 🎯 Any daily habit you want to build!

### How It Works
1. **Create Task** - Enable "Daily Recurring" when creating a task
2. **Complete Daily** - Mark the task done each day
3. **Auto Reset** - Task resets at midnight, ready for the next day
4. **Track History** - View your completion history in a calendar heatmap
5. **Build Streaks** - See how many consecutive days you've completed the task

### Recurring Task Features
- ✅ Automatically resets at midnight (local time)
- 📅 Visual calendar heatmap showing all completions
- 📊 Track completion streaks and patterns
- ⏱️ Supports timers for timed habits
- 👥 Can be assigned to friends
- 🗑️ History older than 3 months is auto-archived

---

## 🤝 Contributing

We welcome contributions from the community! However, please note our distribution restrictions.

### ⚠️ Important: Distribution Restrictions

This project is **source-available** but NOT freely distributable.

**You MAY:**
- ✅ View and study the code
- ✅ Fork for personal or educational use
- ✅ Contribute improvements via pull requests
- ✅ Report bugs and suggest features

**You MAY NOT:**
- ❌ Distribute modified or unmodified versions
- ❌ Publish to app stores without permission
- ❌ Use for commercial purposes
- ❌ Rebrand and redistribute

For distribution or commercial licensing, contact us at the emails below.

### How to Contribute

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidelines.

### Areas for Contribution
- 🐛 Bug fixes
- ✨ New features
- 📝 Documentation improvements
- 🎨 UI/UX enhancements
- 🧪 Test coverage
- 🌐 Localization/translations
- ⚡ Performance optimizations

---

## 🐛 Known Issues & Roadmap

### Current Limitations
- Background timer accuracy depends on device battery optimization settings
- Friend search is case-sensitive
- Animation performance on devices with <2GB RAM needs optimization
- Data older than 3 months is automatically cleaned up

### Version 1.1 Roadmap
- [ ] Push notifications for task reminders
- [ ] Dark mode theme option
- [ ] Weekly/monthly recurring tasks
- [ ] Task categories/tags
- [ ] Export task data as CSV/JSON
- [ ] Advanced search and filtering
- [ ] Case-insensitive friend search

### Version 2.0 Roadmap
- [ ] iOS support
- [ ] Web version
- [ ] Desktop app (Windows, macOS, Linux)
- [ ] Calendar integration
- [ ] Team workspaces
- [ ] Advanced analytics dashboard
- [ ] Custom tier icons
- [ ] Widget support
- [ ] Pomodoro timer technique

Report bugs via [GitHub Issues](https://github.com/ankitraj4096/HabitFlow/issues)

---

## 📄 Documentation

- [Privacy Policy](./PRIVACY_POLICY.md) - How we handle your data
- [Help & Support](./HELP.md) - FAQs and troubleshooting guide
- [Contributing Guide](./CONTRIBUTING.md) - Guidelines for contributors
- [Changelog](./CHANGELOG.md) - Version history and updates (coming soon)

---

## 🏗️ Build Instructions

### ⚙️ Debug Build
```bash
flutter run
```

### 🚀 Release APK
```bash
flutter build apk --release
```

### 📦 Split APKs (Smaller Size)
```bash
flutter build apk --split-per-abi
```

### 🏬 App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### 🔐 With Obfuscation
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

---


## 👥 Developers

<table>
  <tr>
    <td align="center" width="50%">
      <img src="https://github.com/ankitraj4096.png" width="120px;" alt="Ankit Raj" style="border-radius: 50%;"/><br />
      <sub><b>Ankit Raj</b></sub><br />
      <sub>@ankitraj4096</sub><br /><br />
      <a href="https://github.com/ankitraj4096">
        <img src="https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white" />
      </a><br />
      <a href="https://linkedin.com/in/ankitraj4096">
        <img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" />
      </a><br />
      <a href="mailto:abhinavanand4096@gmail.com">
        <img src="https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white" />
      </a>
    </td>
    <td align="center" width="50%">
      <img src="https://github.com/ansharyan007.png" width="120px;" alt="Ansh Aryan" style="border-radius: 50%;"/><br />
      <sub><b>Ansh Aryan</b></sub><br />
      <sub>@ansharyan007</sub><br /><br />
      <a href="https://github.com/ansharyan007">
        <img src="https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white" />
      </a><br />
      <a href="https://www.linkedin.com/in/ansh-aryan-9925aa2b1/">
        <img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" />
      </a><br />
      <a href="mailto:Ansharyan57@gmail.com">
        <img src="https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white" />
      </a>
    </td>
  </tr>
</table>

---

## 📊 Stats

<div align="center">
  
  ![GitHub stars](https://img.shields.io/github/stars/ankitraj4096/HabitFlow?style=social)
  ![GitHub forks](https://img.shields.io/github/forks/ankitraj4096/HabitFlow?style=social)
  ![GitHub watchers](https://img.shields.io/github/watchers/ankitraj4096/HabitFlow?style=social)
  
</div>

---

## 📝 License

This project is **source-available** but not freely distributable.

**You may:**
- ✅ View and study the source code
- ✅ Modify for personal or educational purposes
- ✅ Contribute improvements via pull requests

**You may NOT:**
- ❌ Distribute modified or unmodified versions
- ❌ Publish to app stores without permission
- ❌ Use for commercial purposes without permission

For distribution or commercial use, contact:
- **Ankit Raj:** [abhinavanand4096@gmail.com](mailto:abhinavanand4096@gmail.com)
- **Ansh Aryan:** [Ansharyan57@gmail.com](mailto:Ansharyan57@gmail.com)

See [LICENSE](LICENSE) for full terms.

---

## 🌟 Support the Project

If you find HabitFlow useful, please consider:
- ⭐ **Starring** the repository
- 🐛 **Reporting bugs** via [GitHub Issues](https://github.com/ankitraj4096/HabitFlow/issues)
- 💡 **Suggesting features** you'd like to see
- 🔀 **Contributing** via pull requests
- 📢 **Sharing** with friends who need productivity tools
- 📝 **Writing a review** on your blog or social media

---

## 📞 Contact

**Project Repository:** [github.com/ankitraj4096/HabitFlow](https://github.com/ankitraj4096/HabitFlow)

**Report Issues:** [GitHub Issues](https://github.com/ankitraj4096/HabitFlow/issues)

**Developer Contact:**
- **Ankit Raj** - [abhinavanand4096@gmail.com](mailto:abhinavanand4096@gmail.com)
- **Ansh Aryan** - [Ansharyan57@gmail.com](mailto:Ansharyan57@gmail.com)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend infrastructure and real-time sync
- The open-source community for inspiration and packages
- All contributors who help improve HabitFlow
- Beta testers for valuable feedback

**Special Thanks:**
- Material Design for beautiful UI components
- Lucide Icons for the icon set
- Provider package for state management
- flutter_heatmap_calendar for activity tracking
- All users who trust HabitFlow with their productivity journey

---

## 💡 Inspiration

HabitFlow was inspired by the need for a **fun, competitive, and social approach to habit building**. We believe that productivity should be engaging and rewarding, not boring and solitary. By combining gamification with social accountability, HabitFlow transforms habit-building into an exciting journey with friends.

---

## 📈 Performance

- **App Size:** ~25MB
- **Startup Time:** <2 seconds (with splash screen)
- **Minimum RAM:** 2GB (4GB recommended)
- **Minimum Android:** 5.0 (Lollipop, API 21)
- **Target Android:** 13+ for best experience
- **Background Services:** Optimized for battery efficiency

---

<div align="center">
  <p><strong>Made with ❤️ by Ankit Raj & Ansh Aryan</strong></p>
  <p>© 2025 HabitFlow. All rights reserved.</p>
  <p>⭐ Star us on GitHub — it motivates us to build better!</p>
  
  <br/>
  
  <img src="https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Powered%20by-Firebase-FFCA28?logo=firebase&logoColor=white" />
  <img src="https://img.shields.io/badge/Source%20Available-❤-orange" />
</div>