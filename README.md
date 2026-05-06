# ShorkariIQ

ShorkariIQ is an adaptive learning quiz app built with Flutter. It combines quiz practice, review sessions, progress tracking, and AI-assisted chat in one lightweight study companion.

## Project Overview

The app is designed to help students learn through short quiz cycles, revisit mistakes with spaced review, and keep track of their improvement over time. It also includes a Gemini-powered chat experience for quick explanations and study support.

## Key Features

- Quiz mode with timed question rounds
- Review mode for revisiting missed questions
- Progress and performance tracking
- AI chat support with Gemini
- Login flow and user-specific study data
- English and Bangla support in the chat experience

## Course Note

This project was developed for the CSE299 Junior Design course.
It is part of my academic work and class project submissions.

## Setup

The chat feature expects a `GEMINI_API_KEY` at runtime. Pass it with `--dart-define` when running the app:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

## Build

To run the app on a connected device or emulator:

```bash
flutter pub get
flutter run
```

