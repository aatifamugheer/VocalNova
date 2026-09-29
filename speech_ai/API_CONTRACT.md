# VocalNova Speech AI API Contract

## Purpose

This API allows the VocalNova client application to send a child's
recorded speech and receive a standardized speech-analysis result.

The client does NOT need to know how Azure Speech works internally.

---

# 1. Endpoint

## Analyze Speech

**Method:**

POST

**Endpoint:**

`/analyze-speech`

**Local development URL:**

`http://127.0.0.1:8000/analyze-speech`

---

# 2. Request

The request must be sent as `multipart/form-data`.

## Form fields

### targetWord

The word the child is expected to say.

Example:

`rabbit`

### attemptId

A unique ID for the child's attempt.

Example:

`ANDROID-SIM-001`

### language

Speech language.

Default:

`en-US`

### audio

The recorded audio file.

Example:

`rabbit.m4a`

---

# 3. Example Request

```text
POST /analyze-speech

Content-Type: multipart/form-data

targetWord = rabbit
attemptId = ANDROID-SIM-001
language = en-US
audio = rabbit.m4a