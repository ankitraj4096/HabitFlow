# Contributing to HabitFlow

Thank you for your interest in contributing to HabitFlow! 🎉

We welcome contributions from the community while maintaining the project's integrity and vision.

---

## 📋 Important: Distribution Restrictions

⚠️ **Please note:** This project is **source-available** but NOT freely distributable.

### You MAY:
- ✅ View and study the code
- ✅ Fork for personal or educational use
- ✅ Modify for personal learning
- ✅ Contribute improvements via pull requests
- ✅ Report bugs and suggest features

### You MAY NOT:
- ❌ Distribute modified or unmodified versions
- ❌ Publish to app stores (Google Play, App Store, etc.)
- ❌ Use for commercial purposes
- ❌ Rebrand and redistribute
- ❌ Create derivative works for distribution

**For distribution or commercial licensing**, please contact:
- **Ankit Raj:** [abhinavanand4096@gmail.com](mailto:abhinavanand4096@gmail.com)
- **Ansh Aryan:** [Ansharyan57@gmail.com](mailto:Ansharyan57@gmail.com)

---

## 🤝 How to Contribute

We appreciate all contributions, whether they're bug reports, feature suggestions, or code improvements!

### 🐛 Report Bugs

Found a bug? Help us fix it! Open an issue with:
- **Clear title** describing the problem
- **Steps to reproduce** the bug
- **Expected behavior** vs **actual behavior**
- **Screenshots or videos** (if applicable)
- **Device/OS information**:
  - Device model (e.g., iPhone 13, Samsung Galaxy S21)
  - OS version (e.g., iOS 17.1, Android 14)
  - App version
- **Console logs** (if available)

**Template:**
Bug Description:
[Brief description]

Steps to Reproduce:

- Open app

- Navigate to...

- Tap on...

- Expected Behavior:
[What should happen]

- Actual Behavior:
[What actually happens]

- Screenshots:
[Attach screenshots]

- Device Info:

- Device: [Model]

- OS: [Version]

- App Version: [Version]

---

### 💡 Suggest Features

Have an idea to improve HabitFlow? We'd love to hear it!

Open a **Feature Request** issue with:
- **Feature title** (clear and concise)
- **Problem it solves** (why is this needed?)
- **Proposed solution** (how should it work?)
- **Alternative solutions** (if any)
- **Mockups or diagrams** (optional but helpful!)

**Template:**
Feature Title:
[Clear, concise title]

Problem:
[What problem does this solve?]

Proposed Solution:
[How would this feature work?]

Alternatives:
[Any other ways to solve this?]

Additional Context:
[Mockups, examples, etc.]

---

### 🔧 Submit Code

Ready to contribute code? Follow these steps:

#### 1. **Fork & Clone**
- Fork the repository on GitHub
- then:
- git clone https://github.com/YOUR_USERNAME/HabitFlow.git
- cd HabitFlow

#### 2. **Create a Branch**
- git checkout -b fix/amazing-fix

or

- git checkout -b feature/cool-feature


 Use descriptive branch names:
- `fix/timer-pause-bug`
- `feature/dark-mode`
- `refactor/firebase-service`
- `docs/update-readme`

#### 3. **Set Up Your Environment**
- Install dependencies
- flutter pub get

- Set up Firebase (create your own test project)
- Add your google-services.json (Android) and GoogleService-Info.plist (iOS)
- Run the app
- flutter run


**Note:** You'll need to set up your own Firebase project for testing. DO NOT commit Firebase config files.

#### 4. **Make Your Changes**
- Write clean, readable code
- Follow Flutter/Dart best practices
- Add comments for complex logic
- Keep functions small and focused
- Update documentation if needed

#### 5. **Test Thoroughly**
- Format code
- flutter format .

- Analyze code
- flutter analyze

- Run tests (if available)
- flutter test


- Test on multiple devices/emulators if possible!

#### 6. **Commit Your Changes**
- git add .
- git commit -m "Fix: Timer not pausing correctly"


- See [Commit Message Guidelines](#commit-message-format) below.

#### 7. **Push & Create Pull Request**
- git push origin fix/amazing-fix

- Then open a Pull Request on GitHub!

---

## 📝 Code Guidelines

### Flutter/Dart Best Practices
- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- Use meaningful variable and function names
- Avoid deeply nested code
- Extract reusable widgets
- Handle errors gracefully
- Use `const` constructors where possible

### Project Structure
lib/
├── component/ # Reusable UI components
├── Pages/ # App screens/pages
├── services/ # Business logic (Firebase, Auth, etc.)
├── themes/ # Theme and styling
└── helper/ # Helper functions and utilities



### Code Formatting
- **Indentation:** 2 spaces
- **Line length:** Max 80-100 characters (flexible)
- **Imports:** Group by package type (dart, flutter, external, internal)

// ✅ Good
void updateTask(String taskId, bool isCompleted) {
if (taskId.isEmpty) return;

firestore.updateTask(
taskId: taskId,
isCompleted: isCompleted,
);
}

// ❌ Bad
void updateTask(String taskId,bool isCompleted){
if(taskId.isEmpty)return;
firestore.updateTask(taskId,isCompleted);}



### Comments
- Add comments for complex logic
- Use `//` for single-line comments
- Use `///` for documentation comments
- Use emojis in debug prints for clarity: `debugPrint('✅ Task updated');`

---

## 📬 Commit Message Format

Write clear, descriptive commit messages:

Type: Brief description (50 chars max)

Detailed explanation if needed (wrap at 72 chars)



### Commit Types
- `Fix:` Bug fixes
- `Feature:` New features
- `Refactor:` Code improvements without changing functionality
- `Docs:` Documentation updates
- `Style:` Code formatting (no logic changes)
- `Test:` Adding or updating tests
- `Chore:` Build, dependencies, configs

### Examples
#### Good commits
- git commit -m "Fix: Timer not pausing when app is minimized"
- git commit -m "Feature: Add dark mode support to profile page"
- git commit -m "Refactor: Simplify Firebase recurring task queries"
- git commit -m "Docs: Update README with Firebase setup instructions"

#### Bad commits (too vague)
- git commit -m "fixed bug"
- git commit -m "updated code"
- git commit -m "changes"



---

## 🔄 Pull Request Process

### Before Submitting
- [ ] Code is formatted (`flutter format .`)
- [ ] No analysis warnings (`flutter analyze`)
- [ ] Tested on at least one device/emulator
- [ ] Updated documentation (if needed)
- [ ] Branch is up-to-date with `main`

### PR Template
- When opening a PR, include:

- Description : 
[Brief description of changes]

#### Type of Change
 - Bug fix

 - New feature

 - Refactoring

 - Documentation update

#### Related Issue
- Fixes #[issue_number]

- Changes Made
- Changed X to Y

- Added feature Z

- Refactored ABC

#### Testing
 - Tested on Android

 - Tested on iOS

 - Tested on emulator

 - Tested on physical device

#### Screenshots (if applicable)
- [Add screenshots]

#### Additional Notes
- [Any extra context]



### Review Process
1. **Automated checks** will run (format, analyze)
2. **Maintainers** will review your code
3. **Feedback** may be provided - please address it
4. Once approved, your PR will be **merged**! 🎉

---

## 🚫 What We DON'T Accept

Please avoid PRs that:
- Change the core app structure without discussion
- Add unnecessary dependencies
- Break existing functionality
- Don't follow code guidelines
- Lack proper testing
- Include Firebase config files

---

## ❓ Questions or Need Help?

Feel free to reach out!

### Contact
- **Ankit Raj:** [abhinavanand4096@gmail.com](mailto:abhinavanand4096@gmail.com)
- **Ansh Aryan:** [Ansharyan57@gmail.com](mailto:Ansharyan57@gmail.com)

### Discussion
- Open a **Discussion** in the GitHub Discussions tab
- Ask in an **Issue** if it's bug/feature related

---

## 🎯 Priority Areas

We're especially interested in contributions for:
- 🐛 **Bug fixes** (especially crashes or data loss issues)
- ♿ **Accessibility improvements**
- 🌍 **Localization/translations**
- ⚡ **Performance optimizations**
- 📱 **UI/UX enhancements**
- 📚 **Documentation improvements**

---

## 📜 Code of Conduct

### Our Standards
- Be respectful and inclusive
- Provide constructive feedback
- Focus on the code, not the person
- Help create a welcoming environment

### Unacceptable Behavior
- Harassment or discrimination
- Trolling or insulting comments
- Personal attacks
- Publishing private information

**Violations** will result in temporary or permanent ban from the project.

---

## 🙏 Thank You!

Your contributions help make HabitFlow better for everyone. We appreciate your time and effort!

By contributing, you agree that your contributions will be licensed under the same license as the project.

Happy coding! 🚀✨

---

**Made with ❤️ by the HabitFlow Team**