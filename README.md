# TrustCircle AI

Private, evidence-centered human decision-support prototype. Product principle:
**Catch the Lie. Test the Trust.**

## Current implementation

- Responsive Flutter workspace with case, person, claims, evidence, document, text, audio, image/face, OCR, analysis, verification, timeline, report, history, settings, FAQ, terms, privacy, and about destinations.
- Case intake preserves original statement text and records source/display language, purpose, confidentiality level, authorization and consent confirmations.
- Evidence records source, type, relation to the statement, timestamp and verification metadata. File-picker selections are linked to a case with name, size, kind and local path.
- Session-only case repository records action timestamps and SHA-256 input hashes without copying statement text into audit summaries. Cases can be deleted from the active session.
- Central theme tokens and a controlled six-verdict dictionary for English, Hindi, Bengali, Marathi, Tamil, Telugu, Gujarati, Kannada, Malayalam, Punjabi and Urdu. Other UI strings currently fall back to English.
- Confidential PDF export includes case/evidence details, limitations, confidentiality language and content/input integrity identifiers.

## Important limitations

The repository contains a Flutter app and the three specification prompts, but it does **not** contain the Investigator Hybrid V8 package, NER/NLI/OCR/face/voice/XGBoost model files, their manifests, a Gradio app, or a model API. No verified model inference is implemented. When a statement and evidence are available, the app can show a temporary rule-based verdict from the evidence relations manually recorded by the user. That verdict is explicitly provisional, has no confidence percentage, and is not a model assessment; its verdict and evidence-strength thresholds are not calibrated and must not be used to assess real people. Without the required inputs, the result is `INCONCLUSIVE`. Selected files are recorded but are not processed.

The login and plan screens are demo-only. Cases and audit events exist in memory for the active app session; there is no production authentication, encrypted persistent storage, server-side access control, external evidence API, billing, or retention service. Exported PDFs remain in the device documents folder and must be deleted separately. Legal and privacy text is a prototype notice, not legal advice or a compliance claim. Do not use this build to assess real people or enter sensitive personal information.

## Run and verify

```powershell
flutter pub get
flutter test
flutter analyze
flutter run -d windows
```

Demo credentials are shown on the login screen and provide no real security.
