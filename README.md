# 🎙️ VocalNova

### Speak • Practice • Adapt

VocalNova is an adaptive speech-practice application designed to make speech practice more personalized, engaging, and continuous between therapy sessions.

The system combines **speech analysis, learner state, engagement signals, child interests, and adaptive recommendations** to determine what the child should practice next.

---

## 🎯 Problem

Children may face challenges during practice between therapy sessions:

- Repetitive exercises
- Inconsistent home practice
- Limited immediate feedback
- Low engagement
- Lack of personalization
- Limited continuity between therapy sessions

### Our Question

> **How can speech practice adapt to the child instead of making every child follow the same practice path?**

---

## 💡 Solution

VocalNova creates an adaptive learning loop:

```text
Teach
  ↓
Listen
  ↓
Repeat
  ↓
Analyze
  ↓
Update Learner State
  ↓
Adapt
  ↓
Next Activity
  ↺

Speech performance and engagement information influence the next practice activity.

🚀 Key Features
👧 Child
Personalized child profile
Target sounds and words
Interest-based activities
Sound Adventure
Word Explorer
Picture Quest
Adaptive Practice
Speech recording and analysis
Text-to-speech teaching
Progress tracking
👨‍👩‍👧 Parent
Child profile management
Practice history
Speech performance
Engagement information
Target-word performance
👨‍⚕️ Therapist
Connected children
Practice sessions
Speech attempts
Success rate
Practice duration
Target performance
Practice insights
🧠 Adaptive Intelligence

VocalNova maintains a learner state containing information such as:

Recent scores
Average performance
Attempts
Successful attempts
Difficulty
Performance trend
Engagement
Target sounds and words

The system can adapt teaching between:

Full Model
    ↓
Guided Practice
    ↓
Independent Practice
    ↓
Phrase Practice

The current adaptive engine is a lightweight personalization/recommendation system, not a newly trained clinical deep-learning model.

🤖 Speech AI

The speech pipeline follows:

Child Speech
     ↓
Audio Recording
     ↓
Speech Analysis
     ↓
Speech Score
     ↓
Feedback
     ↓
Learner State
     ↓
Next Activity

VocalNova uses existing speech-recognition capabilities rather than training a new large speech model from scratch.

🏗️ Architecture
Flutter App
     ↓
Speech Recording
     ↓
FastAPI Backend
     ↓
Speech Analysis
     ↓
Learner State
     ↓
Adaptive Engine
     ↓
Next Activity
     ↓
Flutter App

        ↕
   Firebase / Firestore
        ↕
Parent & Therapist Dashboards
🛠️ Tech Stack
Technology	Purpose
Flutter / Dart	Mobile application
Python	Backend
FastAPI	REST API
Firebase Authentication	User authentication
Cloud Firestore	Database
Speech Recognition	Speech analysis
Flutter TTS	Teaching / audio feedback
📸 Screenshots

Add screenshots to:

assets/screenshots/

Example:

![Child Home](assets/screenshots/child-home.png)
![Practice](assets/screenshots/practice.png)
![Speech Result](assets/screenshots/speech-result.png)
![Parent Dashboard](assets/screenshots/parent-dashboard.png)
![Therapist Dashboard](assets/screenshots/therapist-dashboard.png)
⚙️ Setup
Requirements
Flutter
Dart
Python 3.x
Android Studio
Firebase
FFmpeg where required by the speech pipeline
Clone
git clone https://github.com/YOUR-USERNAME/VocalNova.git
cd VocalNova
Flutter
flutter pub get
flutter analyze
flutter test
flutter run
Backend
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000

For local Android development:

adb reverse tcp:8000 tcp:8000
📁 Project Structure
VocalNova/
├── assets/
│   └── screenshots/
├── android/
├── ios/
├── lib/
│   ├── models/
│   ├── screens/
│   ├── services/
│   └── widgets/
├── backend/
├── test/
├── pubspec.yaml
├── firebase.json
├── firestore.rules
├── .gitignore
└── README.md
🔮 Future Scope
Advanced pronunciation analysis
Phoneme-level feedback
ML-based recommendations
Multi-language support
Cloud backend deployment
Advanced therapist tools
Larger-scale evaluation and validation
⚠️ Disclaimer

VocalNova is a working prototype for adaptive speech practice.

It is not a medical device, diagnostic system, or replacement for a licensed speech-language pathologist. The current speech analysis, engagement scoring, and adaptive recommendations have not been clinically validated.

👥 Team
Member	Responsibility
Aatifa Mugheer	Backend & Adaptive Motivation Engine
Khubaib Alam	Flutter / Child Application
Shivam Gupta	Speech / AI
Vaidic Gupta	UX, Dashboards & Presentation
