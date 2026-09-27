# TrustCircle AI

### Catch the Lie. Test the Trust.

**TrustCircle AI** is a global, multilingual, cross-platform civilian **Lie Detection and Trust Intelligence** system designed to help users identify deception signals, inconsistencies, verification gaps, and trust-related risk indicators.

> **Before deception becomes damage.**

TrustCircle AI does not aim to declare a person "a liar," "a criminal," or "guilty." Instead, it combines multimodal AI, structured evidence, Knowledge Graphs, and reasoning systems to present observable signals and supporting evidence so that users can make informed decisions.

---

## Core Principles

**Signal ≠ Proof**
**Pattern ≠ Verdict**
**Risk ≠ Guilt**
**AI ≠ Decision Maker**

A detected contradiction, facial signal, voice characteristic, or external record is treated as evidence or an indicator requiring context and verification, not as an automatic conclusion.

---

## Product Vision

TrustCircle AI aims to make sophisticated deception and trust-analysis capabilities more accessible to civilian users.

Potential use cases include:

* Personal relationships
* New relationships and dating
* Business and partnerships
* Hiring and employment
* Online marketplaces
* Financial transactions
* Property and rental interactions
* Education and credential verification
* Social and community interactions
* Travel and new connections
* Everyday trust decisions

These represent potential applications, not guarantees of fraud prevention or deception detection.

---

## System Architecture

```text
                 TRUSTCIRCLE AI
                       │
                       ▼
              MULTI-MODAL INPUT
     ┌──────────┬─────────┬─────────┐
     │   Text   │  Voice  │  Images │
     │   Chat   │  Video  │  Docs   │
     └──────────┴─────────┴─────────┘
                       │
                       ▼
                 AI MODEL LAYER
     ┌─────────────────────────────────┐
     │ NER                             │
     │ NLI                             │
     │ ArcFace                         │
     │ Vev2Wav                         │
     │ XGBoost                         │
     └─────────────────────────────────┘
                       │
                       ▼
           TRUSTCIRCLE KNOWLEDGE GRAPH
     ┌─────────────────────────────────┐
     │ Persons                         │
     │ Claims                          │
     │ Statements                      │
     │ Events                          │
     │ Relationships                   │
     │ Evidence                        │
     │ Documents                       │
     │ Timeline                        │
     │ Identity                        │
     │ Transactions                    │
     └─────────────────────────────────┘
                       │
                       ▼
       EXTERNAL & CONNECTED EVIDENCE
     ┌─────────────────────────────────┐
     │ User-provided evidence           │
     │ Legally available public sources │
     │ NexForensics / NFX API           │
     └─────────────────────────────────┘
                       │
                       ▼
       EVIDENCE REASONING & TRUST
                 INTELLIGENCE
     ┌─────────────────────────────────┐
     │ Contradiction Analysis          │
     │ Claim Verification              │
     │ Timeline Consistency            │
     │ Identity Cross-check            │
     │ Missing Evidence                │
     │ Multi-signal Analysis           │
     │ Trust / Risk Indicators         │
     └─────────────────────────────────┘
                       │
                       ▼
                TRUSTCIRCLE OUTPUT
     ┌─────────────────────────────────┐
     │ Deception Signals               │
     │ Contradictions                  │
     │ Supporting Evidence             │
     │ Verification Gaps               │
     │ Confidence / Evidence Strength  │
     │ Trust Assessment                │
     │ Detailed Investigation Report  │
     └─────────────────────────────────┘
```

---

## AI Technology Stack

### 1. NER — DeBERTa V2

Named Entity Recognition is used to extract structured entities and information from statements and documents.

Examples include:

* Persons
* Organizations
* Locations
* Amounts
* Dates and times
* Identity information
* Claims
* Other relevant entities

TrustCircle uses the existing NexForensics DeBERTa-based NER architecture.

---

### 2. NLI — Natural Language Inference

The DeBERTa architecture has been adapted for Natural Language Inference.

Primary outputs:

* **Entailment**
* **Neutral**
* **Contradiction**

Potential applications include:

* Statement consistency
* Cross-statement comparison
* Temporal reasoning
* Claim contradiction
* Evidence comparison

---

### 3. ArcFace — Facial Representation

TrustCircle incorporates the existing Face V7 architecture based on ArcFace.

Current representation:

* 512-dimensional face representation
* Identity representation
* Facial representation
* Expression-related signals

Canonical merged model:

**TrustCircleFaceExpressionV1**

The system treats facial signals as observable model outputs rather than direct proof of deception.

---

### 4. Vev2Wav — Voice Analysis

The existing NexForensics Vev2Wav model provides an audio/voice representation layer.

Potential signals include:

* Voice representation
* Speech characteristics
* Observable hesitation-related patterns
* Observable stress-related patterns
* Speaker characteristics where applicable

Voice-derived signals require contextual interpretation and are not independently treated as proof of deception.

---

### 5. XGBoost — Multi-Signal Fusion

XGBoost is planned as a higher-level fusion layer combining engineered signals from multiple components.

Potential inputs include:

* NLI features
* Linguistic features
* Facial features
* Voice features
* Behavioral features
* Temporal features
* Knowledge Graph features
* Verification signals

The objective is to analyze combinations of signals rather than rely on a single modality.

---

## TrustCircle Knowledge Graph

The Knowledge Graph is a core architectural component of TrustCircle AI.

It provides structured context for:

* Entities
* Claims
* Statements
* Events
* Relationships
* Evidence
* Documents
* Timeline
* Identity
* Transactions
* Verification status

### Example Node Types

```text
Person
Organization
Location
Event
Claim
Statement
Relationship
Transaction
Document
Evidence
Time
Identity
```

### Example Relationships

```text
CLAIMED
SAID
WORKED_AT
KNOWS
RELATED_TO
TRANSFERRED
OCCURRED_AT
OCCURRED_ON
CONTRADICTS
SUPPORTS
REFUTES
VERIFIED_BY
UNVERIFIED
MISSING_EVIDENCE
```

The Knowledge Graph does not produce a verdict by itself.

It structures evidence and relationships so that downstream reasoning systems can evaluate consistency, verification, and context.

---

## NexForensics Integration

TrustCircle AI may connect to the NexForensics platform through a controlled, authenticated API.

Where legally accessible and appropriate, connected evidence may include:

* Case records
* Identity/entity intelligence
* References
* Other investigative evidence

NexForensics data is treated as an **evidence source**, not an automatic criminality or trust score.

TrustCircle must distinguish between:

```text
Allegation
Complaint
Investigation
Case
Conviction
Current Status
Source
Date
```

An allegation is not a conviction.

A criminal record or case record is not, by itself, proof that a person is currently dishonest or dangerous.

Raw investigative data should not be unnecessarily exposed to the client application. Controlled server-side access and authenticated APIs are preferred.

---

## Multilingual & Cross-Platform

TrustCircle AI is designed as an English-first global product with multilingual support.

Target platforms include:

* Android
* iOS
* Windows
* Web

Users should be able to receive analysis and reports in their preferred supported language while maintaining a consistent underlying evidence and reasoning structure.

---

## Current Model Components

| Component  | Technology                  | Primary Role                         |
| ---------- | --------------------------- | ------------------------------------ |
| NER        | DeBERTa V2                  | Entity & claim extraction            |
| NLI        | DeBERTa-based               | Entailment / contradiction reasoning |
| Face       | ArcFace / Face V7           | Facial representation                |
| Expression | TrustCircleFaceExpressionV1 | Facial expression signals            |
| Voice      | Vev2Wav                     | Voice representation                 |
| Fusion     | XGBoost                     | Multi-signal pattern fusion          |
| Knowledge  | TrustCircle KG              | Evidence & relationship structure    |
| Reasoning  | Evidence Reasoning Layer    | Trust intelligence                   |

---

## Development Status

TrustCircle AI is under active development.

Current engineering focus:

1. Stabilizing existing AI components
2. Building the TrustCircle Knowledge Graph
3. Integrating NER and NLI
4. Integrating face and voice representations
5. Designing multi-signal feature fusion
6. Building the evidence reasoning layer
7. Implementing controlled NexForensics integration
8. Developing cross-platform application interfaces
9. Building auditable reporting and verification workflows

---

## Research & Evaluation Notes

Model evaluation is performed component-by-component and should not be interpreted as proof of universal real-world deception-detection accuracy.

Cross-domain generalization is an important research challenge, particularly for facial-expression and behavioral signals.

Benchmark results are therefore documented separately from product claims.

TrustCircle AI does **not** claim that any individual AI modality can reliably determine whether a person is lying.

---

## Responsible AI

TrustCircle AI is designed around evidence-aware decision support.

The system should:

* Clearly distinguish evidence from inference
* Display uncertainty where appropriate
* Preserve source information
* Identify missing evidence
* Distinguish allegations from established findings
* Avoid automatic criminality conclusions
* Avoid presenting probabilistic signals as facts
* Allow human review
* Maintain appropriate privacy and access controls

The final decision remains with the human user.

---

## Repository Structure

The repository is organized to separate application code, AI components, reasoning systems, and documentation.

```text
TrustCircleAI/
│
├── android/
├── ios/
├── web/
├── windows/
├── lib/
│
├── ai/
│   ├── ner/
│   ├── nli/
│   ├── face/
│   ├── voice/
│   └── fusion/
│
├── knowledge_graph/
│
├── reasoning/
│
├── api/
│
├── data/
│
├── docs/
│
├── tests/
│
├── scripts/
│
├── assets/
│
├── .gitignore
├── README.md
└── LICENSE
```

The exact structure may evolve as implementation progresses.

---

## Model & Dataset Repositories

Large models and datasets are maintained separately from the main source repository.

Planned Hugging Face repositories include:

```text
trustcircle-nli-60k-v3
trustcircle-face-expression-v1
trustcircle-ner
trustcircle-voice
```

The main GitHub repository should contain model configuration, manifests, hashes, inference code, and documentation rather than unnecessarily storing large model binaries.

---

## Security & Privacy

TrustCircle AI is intended to handle potentially sensitive personal information.

The production architecture should therefore include:

* Authentication
* Authorization
* Encryption in transit
* Secure storage
* API access control
* Audit logging
* Data minimization
* Controlled external-source access
* Appropriate retention policies

Privacy and legal requirements will vary by jurisdiction and deployment model.

---

## Disclaimer

TrustCircle AI is an AI-assisted analysis and decision-support system.

Its outputs are signals, analyses, and evidence assessments. They are not automatically equivalent to factual determinations, criminal findings, legal conclusions, or proof that an individual is lying.

Users remain responsible for independently verifying important information and making their own decisions.

---

## License

License terms will be defined before public release.

---

## Project

**TrustCircle AI**

**Catch the Lie. Test the Trust.**

*Before deception becomes damage.*
