# 🎙️ VocalNova

### Speak • Practice • Adapt

VocalNova is an adaptive speech-practice application designed to make speech practice more personalized, engaging, and continuous between therapy sessions.

## 🎯 Problem

Children often receive personalized guidance during speech-therapy sessions, but maintaining consistent and personalized practice at home can be difficult.

Common challenges include:

- One-size-fits-all practice activities
- Limited feedback during home practice
- Reduced motivation and engagement
- Limited continuity between therapy sessions and home practice

## 💡 Solution

VocalNova creates a continuous adaptive practice loop:

**Teach → Listen → Repeat → Analyze → Adapt**

The application analyzes a child's speech attempt, combines speech performance with learner progress and engagement signals, and recommends what the child should practice next.

Instead of following the same fixed sequence for every learner, VocalNova adapts:

- Practice difficulty
- Target words
- Teaching mode
- Practice themes
- Repetition
- Next activity

> VocalNova is a prototype for adaptive speech practice and is not intended to replace a speech-language pathologist.

## 🤖 AI & ML

VocalNova combines **Speech AI** with a lightweight **adaptive personalization model**.

### Speech AI
The speech-analysis pipeline processes the child's recorded speech and generates feedback such as:

- Speech score
- Success/failure feedback
- Target-word analysis

### Adaptive Intelligence
The system maintains a learner state containing information such as:

- Recent speech scores
- Average performance
- Attempts and successful attempts
- Difficulty level
- Performance trend
- Engagement signals

Engagement can include:

- Mission completion
- Voluntary retries
- Time on task
- Return frequency
- Practice consistency
- Skips

The **Learning Engine** uses this information to recommend the next activity.

> The current adaptive engine is a lightweight personalization/recommendation model. VocalNova does not claim to train a new large speech model from scratch.

## 🏗️ Architecture

```text
Child App
    ↓
Personalized Practice
    ↓
Speech Recording
    ↓
Speech AI Analysis
    ↓
Learner State
    ↓
Adaptive Learning Engine
    ↓
Next Practice Activity
    ↺
--
## 🛠️ Tech Stack

| Technology                         | Purpose                                                |
| ---------------------------------- | ------------------------------------------------------ |
| **Flutter / Dart**                 | Cross-platform mobile application                      |
| **Python / FastAPI**               | Backend and speech-analysis API                        |
| **Firebase Authentication**        | Parent & therapist authentication                      |
| **Cloud Firestore**                | Learner profiles, attempts, progress & recommendations |
| **Speech AI / Speech Recognition** | Speech attempt analysis                                |
| **Adaptive Learning Engine**       | Personalized activity recommendation                   |
| **Flutter TTS**                    | Teaching and pronunciation models                      |

App Screenshots

screenshots/
├── login.png
├── child-home.png
├── practice.png
├── speech-result.png
├── child-profile.png
├── parent-dashboard.png
└── therapist-dashboard.png

👥 Collaborators

Aatifa Mugheer — Backend & Adaptive Motivation Engine
Khubaib Alam — Flutter / Child-facing Application
Shivam Gupta — Speech AI / Speech Analysis
Vaidic Gupta — UX, Parent/Therapist Dashboard & Presentation

🚀 Project Status

Working Prototype

The prototype demonstrates:

Child profiles
Personalized practice
Speech recording and analysis
Adaptive recommendations
Learner-state persistence
Parent dashboard
Therapist dashboard
Engagement-aware adaptation

🔮 Future Scope

Larger and more diverse speech datasets
More robust speech assessment models
Clinical validation with speech-language professionals
Advanced personalization using machine learning
Expanded language support
Long-term progress analytics
