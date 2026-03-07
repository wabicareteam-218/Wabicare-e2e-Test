# AI Features Module — PRD

> **Priority**: P2 - Nice to Have  
> **Status**: ⚪ Not Started

---

## Overview

The AI module provides AI-powered assistance for clinical workflows, including assessment report generation, session note summarization, and document analysis. Currently uses deterministic templates with placeholder for Azure OpenAI integration.

---

## User Stories

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| US-AI01 | As a BCBA, I want AI to draft assessment reports so that I can save time | P2 | ⚪ |
| US-AI02 | As a BCBA, I want AI to summarize session notes so that I can review quickly | P2 | ⚪ |
| US-AI03 | As a BCBA, I want AI to extract key info from documents so that I don't miss anything | P3 | ⚪ |

---

## Functional Requirements

### Assessment Report Generation

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AI01 | Generate initial auth assessment draft | P2 | ⚪ |
| FR-AI02 | Generate reauthorization assessment draft | P2 | ⚪ |
| FR-AI03 | Use intake form data as input | P2 | ⚪ |
| FR-AI04 | Use caregiver interview data as input | P2 | ⚪ |
| FR-AI05 | Use voice transcript as input | P2 | ⚪ |
| FR-AI06 | Use uploaded documents as context | P2 | ⚪ |
| FR-AI07 | Return editable HTML draft | P2 | ⚪ |
| FR-AI08 | Track which sections came from which sources | P2 | ⚪ |

### Session Notes

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AI10 | Summarize session notes | P2 | ⚪ |
| FR-AI11 | Extract key behaviors observed | P2 | ⚪ |
| FR-AI12 | Suggest next session focus | P3 | ⚪ |

### Document Analysis

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AI20 | Extract text from PDFs | P3 | ⚪ |
| FR-AI21 | Classify document type | P3 | ⚪ |
| FR-AI22 | Extract insurance info | P3 | ⚪ |

---

## API Requirements

```
# Assessment Reports
POST   /api/v1/ai/generate-assessment-report
       Body: { templateId, patientName, intakeFormData, caregiverInterview, voiceTranscript, uploadedDocuments }
       Response: { html, generatedAt, templateVersion, reportInputs, sourceMap }

# Session Notes
POST   /api/v1/ai/generate-session-notes
       Body: { sessionId, notes, behaviorsObserved }
       Response: { summary, keyBehaviors, suggestedFocus }

# Document Analysis
POST   /api/v1/ai/analyze-document
       Body: { documentUrl, documentType }
       Response: { extractedText, classifiedType, extractedData }
```

---

## Implementation Notes

### Phase 1: Deterministic Templates (Current)

```python
# No external AI yet - uses template-based generation
def generate_assessment_report(data):
    return fill_template(data)
```

### Phase 2: Azure OpenAI Integration (Future)

```python
# Swap to Azure OpenAI when ready
from openai import AzureOpenAI

client = AzureOpenAI(
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_key=os.environ["AZURE_OPENAI_KEY"],
    api_version="2024-02-15-preview"
)

def generate_assessment_report(data):
    response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": ASSESSMENT_PROMPT},
            {"role": "user", "content": json.dumps(data)}
        ]
    )
    return response.choices[0].message.content
```

---

## HIPAA Considerations

- **No PHI to External AI**: If using external LLM, de-identify data first
- **Azure OpenAI**: Compliant when using Azure's HIPAA-compliant regions
- **Audit Logs**: Log all AI requests (without PHI)
- **Human Review**: All AI outputs require BCBA review before use

---

## Data Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Intake Data  │     │ Session Data │     │  Documents   │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       └────────────┬───────┴────────────────────┘
                    ▼
           ┌────────────────┐
           │   AI Service   │
           │ (Django/Celery)│
           └────────┬───────┘
                    │
       ┌────────────┼────────────┐
       ▼            ▼            ▼
┌────────────┐ ┌─────────┐ ┌──────────┐
│ Azure      │ │ Local   │ │ Template │
│ OpenAI     │ │ Model   │ │ (Fallbk) │
└────────────┘ └─────────┘ └──────────┘
       │            │            │
       └────────────┼────────────┘
                    ▼
           ┌────────────────┐
           │  BCBA Review   │
           │  & Approval    │
           └────────────────┘
```

---

## Tasks Reference

See [tasks/ai.md](../tasks/ai.md) when created.
