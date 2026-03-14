# Backend Implementation Plan - Tax Form Mapper

## Overview
This document outlines the architecture and implementation steps for the Java Spring Boot backend that powers the Tax Form Mapper system. The core of this system is an asynchronous scanning engine that uses configurable fuzzy matching algorithms to link Clients and Managers based on their Tax Form attributes.

## 1. Core Technologies
*   **Framework:** Spring Boot 3.x, Java 17+
*   **Database:** PostgreSQL / MySQL (Spring Data JPA)
*   **Fuzzy Matching Libraries:**
    *   `com.intuit.fuzzymatcher:fuzzy-matcher` (For aggregate scoring of multiple attributes)
    *   `info.debatty:java-string-similarity` (For fine-grained, individual algorithm control)
*   **Async Processing:** Spring `@Async` or Spring Batch for the scanning jobs.

## 2. System Components

### A. Data Models (Entities)
Standard JPA entities mapped directly to the `sql_schema.sql` definitions:
*   `MatchingRule` (1-to-many with `RuleAttribute`)
*   `RuleAttribute` (Defines Weight, Algorithm, and the Field to match: Name, SSN)
*   `ScanJob` (Tracks state: PENDING, RUNNING, COMPLETED)
*   `MatchSuggestion` (The output of the heuristic engine)
*   `TaxFormMapping` (The final, user-approved mapping)

### B. The Matching Engine (`MatchingService.java`)
This is the brains of the operation.
1.  **Normalization Step:**
    Before any fuzzy matching, fields (especially Company Names) must be normalized.
    *   `"Limited Liability Corporation"` -> `"LLC"`
    *   `"Incorporated"` -> `"INC"`
    *   *Implementation:* A structured dictionary replacement utility.
2.  **Algorithm Selection Strategy:**
    Based on the `algorithm` defined in the `RuleAttribute`, the engine dynamically selects the strategy using the Strategy Pattern.
    *   *Exact:* Standard `.equalsIgnoreCase()`
    *   *Cosine:* Tokenizes the string and compares words (excellent for out-of-order words like "Narendra LLC" vs "LLC Narendra").
    *   *Jaro-Winkler:* Good for typos in single words or names.
3.  **Weighted Scoring:**
    ```java
    double totalScore = 0.0;
    for (RuleAttribute attr : rule.getAttributes()) {
        double attributeScore = algorithmEngine.calculateScore(val1, val2, attr.getAlgorithm());
        totalScore += (attributeScore * (attr.getWeightPercentage() / 100.0));
    }
    ```

### C. The Asynchronous Scan Job (`ScanJobOrchestrator.java`)
When a user submits a rule configuration via the UI:
1.  The API creates a `ScanJob` entity in the DB (State = `RUNNING`) and immediately returns a `202 Accepted` to the UI.
2.  An `@Async` method begins retrieving records in chunks (pagination) to prevent OOM errors on 20k+ records.
3.  **Crucial Step - Resolution:** For every Manager record retrieved, the engine makes an HTTP call (via `WebClient` or `RestTemplate`) to the **External Child Client Resolution API** to fetch the actual Child Client's attributes.
4.  The engine applies the `MatchingService` logic.
5.  If `totalScore >= rule.getConfidenceThreshold()`, a `MatchSuggestion` record is saved to the DB.
6.  The job completes, updating status to `COMPLETED`.

### D. Intercept & Suggest API (`TaxFormSuggestionController.java`)
Whenever a legacy process or user approves a *new* Tax Form, that external system will call this endpoint:
*   `GET /api/v1/tax-forms/suggestions?entityId=123&entityType=MANAGER&formType=W9`
*   The API queries the `tax_form_mappings` table.
*   If mappings exist, it returns `200 OK` with `{ hasSharedIdentities: true, identities: [...] }`. The UI uses this to show the popup: *"Hey, we know this form is being shared..."*

## 3. API Endpoints (REST)

| Method | Path | Description |
| :--- | :--- | :--- |
| `POST` | `/api/v1/rules` | Create a new Matching Rule configuration. |
| `GET` | `/api/v1/rules` | Fetch all configured rules. |
| `POST` | `/api/v1/scan-jobs` | Trigger a new async scan job using a specific `ruleId`. |
| `GET` | `/api/v1/scan-jobs/{id}/status` | Poll status of a running job. |
| `GET` | `/api/v1/suggestions?jobId={id}` | Retrieve paginated list of Match Suggestions for Maker UI. |
| `POST` | `/api/v1/suggestions/approve` | Approve a suggestion (moves it to `tax_form_mappings`). |

## 4. Required User Clarifications
1.  **External Resolution API:** What is the exact payload structure returned by the external service when resolving a Manager ID to a Child Client?
2.  **Data Ingestion:** How does the Spring Boot app initially access the 20,000 Client/Manager records? Is it a direct database connection to a central DB, or via another API?
3.  **Normalization Mapping:** Do we have a definitive list of legal entity abbreviations (LLC, INC, CORP, GMBH, etc.) that need to be supported in the Normalizer?
