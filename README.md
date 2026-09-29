# 🎙️ VocalNova

<p align="center">

## Speak • Practice • Adapt

### An Adaptive Speech-Practice Platform for Personalized and Engaging Learning

VocalNova is a child-centered speech-practice application that combines speech analysis, learner history, engagement signals, and adaptive recommendations to personalize what a child practices next.

</p>

<p align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.x-3776AB?logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?logo=fastapi&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&logoColor=black)
![Firestore](https://img.shields.io/badge/Firestore-Database-FFCA28?logo=firebase&logoColor=black)
![Status](https://img.shields.io/badge/Status-Working%20Prototype-2EA44F)

</p>

---

# 📖 Table of Contents

- [About VocalNova](#-about-vocalnova)
- [Problem Statement](#-problem-statement)
- [Our Solution](#-our-solution)
- [Core Idea](#-core-idea)
- [Novelty](#-novelty)
- [Key Features](#-key-features)
- [How VocalNova Works](#-how-vocalnova-works)
- [Adaptive Intelligence](#-adaptive-intelligence)
- [Speech AI](#-speech-ai)
- [Engagement Intelligence](#-engagement-intelligence)
- [System Architecture](#-system-architecture)
- [Technical Workflow](#-technical-workflow)
- [Technology Stack](#-technology-stack)
- [Application Modules](#-application-modules)
- [User Roles](#-user-roles)
- [Child Experience](#-child-experience)
- [Parent Dashboard](#-parent-dashboard)
- [Therapist Dashboard](#-therapist-dashboard)
- [Screenshots](#-screenshots)
- [Data Architecture](#-data-architecture)
- [Authentication](#-authentication)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Flutter Setup](#-flutter-setup)
- [Backend Setup](#-backend-setup)
- [Firebase Setup](#-firebase-setup)
- [Running the Application](#-running-the-application)
- [Testing](#-testing)
- [Prototype Demo Flow](#-prototype-demo-flow)
- [Scalability](#-scalability)
- [Limitations](#-limitations)
- [Future Scope](#-future-scope)
- [Privacy and Security](#-privacy-and-security)
- [Project Status](#-project-status)
- [Contributors](#-contributors)
- [Contribution](#-contribution)
- [Disclaimer](#-disclaimer)
- [Acknowledgements](#-acknowledgements)
- [Final Thought](#-final-thought)

---

# 🌟 About VocalNova

**VocalNova** is an adaptive speech-practice application designed to make speech practice more personalized, engaging, and continuous between therapy sessions.

Traditional practice can become repetitive when every learner follows the same fixed sequence of exercises.

VocalNova explores a different approach:

> **Instead of giving every child the same practice path, the system uses the learner's recent performance and engagement to help determine what the child should practice next.**

The platform combines:

- Speech analysis
- Learner state
- Engagement signals
- Child interests
- Target sounds
- Target words
- Adaptive teaching
- Personalized recommendations

into a continuous practice loop.

---

# ❗ Problem Statement

Speech practice does not only happen during a therapy session.

Between therapy sessions, children may experience challenges such as:

- Inconsistent home practice
- Repetitive exercises
- Limited immediate feedback
- Difficulty maintaining motivation
- Limited personalization
- Lack of continuity between therapy sessions and home practice

During a professional therapy session, a therapist can:

- Observe the child
- Listen to pronunciation
- Identify difficulties
- Give feedback
- Change the activity
- Adjust the difficulty

However, during independent home practice, the same level of continuous adaptation may not be available.

This led to our central question:

> **How can speech practice adapt to the child instead of making every child follow the same practice path?**

---

# 💡 Our Solution

VocalNova creates a continuous adaptive practice loop.

Instead of treating every practice attempt as an isolated event, the system maintains a learner state and uses recent performance and engagement information to influence subsequent practice.

### The core loop

```text
┌─────────────┐
│    TEACH    │
└──────┬──────┘
       ↓
┌─────────────┐
│    LISTEN   │
└──────┬──────┘
       ↓
┌─────────────┐
│    REPEAT   │
└──────┬──────┘
       ↓
┌─────────────┐
│   ANALYZE   │
└──────┬──────┘
       ↓
┌─────────────┐
│    LEARN    │
└──────┬──────┘
       ↓
┌─────────────┐
│    ADAPT    │
└──────┬──────┘
       ↓
┌─────────────┐
│ NEXT ACTIVITY│
└──────┬──────┘
       │
       └──────────────► Repeat
