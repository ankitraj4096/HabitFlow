<div align="center">
  <h1>🚀 HabitFlow</h1>
  <p><strong>Build habits, unlock tiers, compete with friends</strong></p>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
  [![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)](https://github.com/ankitraj4096/HabitFlow/releases)
</div>

---

## 📖 About

**HabitFlow** is a productivity and task management app designed to help you build better habits through a **competitive and friendly environment**. The app combines task management with gamification to make productivity fun and rewarding!

### Key Highlights
- ⏱️ **Timed task tracking** with beautiful water-filling animations
- 🎯 **16-tier progression system** that rewards consistency
- 👥 **Social accountability** features to connect with friends
- 🏆 **Achievements & badges** for reaching milestones
- 🎨 **Custom themes** that unlock as you progress through tiers

---

## ✨ Features

### 🎯 Core Functionality
- **Task Management** - Create, edit, and delete tasks with ease
- **Timer System** - Track time spent on each task with visual progress indicators
- **Auto-completion** - Tasks automatically mark complete when timers finish
- **Friend System** - Add friends by username and build accountability
- **Task Assignment** - Assign tasks to friends and accept/decline requests

### 🏆 Progression & Rewards
- **16 Unique Tiers** - Progress from "The Initiate" to "The Ascended"
- **Dynamic Themes** - Each tier unlocks unique gradient color schemes
- **Achievement System** - Earn badges for milestones and daily streaks
- **Statistics Dashboard** - View detailed analytics and heatmaps
- **Leaderboard** - Compare your progress with friends

### 👥 Social Features
- **Friend Profiles** - View friends' tiers, stats, and completed tasks
- **Task Collaboration** - Assign tasks to motivate each other
- **Activity Feed** - See friends' achievements and completed tasks
- **Inbox System** - Manage pending task requests

### 🎨 Customization
- **Theme Selection** - Choose from any unlocked tier theme
- **Auto Theme Mode** - Colors automatically update as you progress
- **Manual Theme Lock** - Select your favorite theme manually
- **Profile Customization** - Edit username and track personal statistics

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| **Frontend** | Flutter & Dart |
| **Backend** | Firebase (Authentication, Firestore, Crashlytics) |
| **State Management** | Provider |
| **UI/UX** | Material Design, Custom Animations |
| **Additional Packages** | url_launcher, flutter_slidable, intl, flutter_lucide |

---

## 📱 Screenshots

> Add app screenshots here to showcase the UI

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0 or higher)
- [Dart SDK](https://dart.dev/get-dart) (3.0 or higher)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/downloads)

### Installation Steps

1. **Clone the repository**
git clone https://github.com/ankitraj4096/HabitFlow.git
cd HabitFlow

text

2. **Install dependencies**
flutter pub get

text

3. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable **Authentication** (Email/Password)
   - Create a **Firestore Database**
   - Download configuration files:
     - `google-services.json` → Place in `android/app/`
     - `GoogleService-Info.plist` → Place in `ios/Runner/`

4. **Run the app**
flutter run

text

---

## 📂 Project Structure

lib/
├── Pages/
│ ├── login_components/ # Login & signup screens
│ ├── ui_components/ # Main app UI
│ │ ├── friend_components/ # Friend management
│ │ └── profile_page_components/ # Profile & settings
├── component/ # Reusable widgets
│ ├── achievements.dart # Achievement badges
│ ├── customToast.dart # Toast notifications
│ └── water_droplet.dart # Timer animation
├── services/
│ ├── auth/ # Firebase authentication
│ └── notes/ # Firestore services
├── themes/
│ └── tier_theme_provider.dart # Theme management
└── main.dart # App entry point

text

---

## 🎯 Tier Progression System

HabitFlow features **16 progression tiers**, each unlocked by completing tasks:

| Tier | Name | Tasks Required | Theme Color |
|:----:|------|:--------------:|-------------|
| 1 | The Initiate | 1 | Grey |
| 2 | The Seeker | 5 | Blue |
| 3 | The Novice | 10 | Green |
| 4 | The Apprentice | 25 | Yellow |
| 5 | The Adept | 50 | Orange |
| 6 | The Disciplined | 100 | Purple |
| 7 | The Specialist | 250 | Pink |
| 8 | The Expert | 500 | Indigo |
| 9 | The Vanguard | 1000 | Red |
| 10 | The Sentinel | 1750 | Cyan |
| 11 | The Virtuoso | 2500 | Teal |
| 12 | The Master | 4000 | Amber |
| 13 | The Grandmaster | 6000 | Light Green |
| 14 | The Titan | 8000 | Blue Grey |
| 15 | The Luminary | 10000 | Multi-gradient |
| 16 | The Ascended | 10001+ | Animated gradient ✨ |

---

## 🤝 Contributing

We welcome contributions from the community! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Contribution Guidelines
- Follow Flutter/Dart best practices and conventions
- Write clear, meaningful commit messages
- Update documentation for new features
- Test thoroughly before submitting PR
- Keep PRs focused on a single feature or fix

---

## 🐛 Known Issues & Roadmap

### Current Issues
- Timer may pause when app goes to background (investigating background execution)
- Animation performance on older devices needs optimization

### Future Enhancements
- Push notifications for task reminders
- Dark mode theme option
- Weekly/monthly challenge system
- Export task data as CSV
- Integration with calendar apps

Report bugs via [GitHub Issues](https://github.com/ankitraj4096/HabitFlow/issues)

---

## 📄 Documentation

- [Privacy Policy](./PRIVACY_POLICY.md) - How we handle your data
- [Help & Support](./HELP_SUPPORT.md) - FAQs and troubleshooting guide

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

## 📝 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

MIT License

Copyright (c) 2025 Ankit Raj & Ansh Aryan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

text

---

## 🌟 Support the Project

If you find HabitFlow useful, please consider:
- ⭐ **Starring** the repository
- 🐛 **Reporting bugs** via [GitHub Issues](https://github.com/ankitraj4096/HabitFlow/issues)
- 💡 **Suggesting features** you'd like to see
- 🔀 **Contributing** via pull requests
- 📢 **Sharing** with friends who need productivity tools

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
- Firebase for backend infrastructure
- The open-source community for inspiration
- All contributors who help improve HabitFlow

---

<div align="center">
  <p><strong>Made with ❤️ by Ankit Raj & Ansh Aryan</strong></p>
  <p>© 2025 HabitFlow. All rights reserved.</p>
  <p>⭐ Star us on GitHub — it motivates us to build better!</p>
</div>
