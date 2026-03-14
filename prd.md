# Product Requirements Document (PRD) - Tax Form Mapper System

## 1. Executive Summary
The Tax Form Mapper System aims to reduce redundant data entry and improve compliance by intelligently linking Client and Manager Tax Forms (W8, W9, etc.). When identities are sufficiently similar based on configurable string matching rules, the system will map them together and suggest sharing updated tax forms across the linked identities.

## 2. Background
- Organization has ~20k Clients, and multiple Asset Managers and Principle Managers.
- Each Client and Manager has their own Tax Form.
- **Hierarchy:** Parent Client -> Child Client. A Manager can manage a Child but is tagged under the Parent.
- If a form is updated, the system should suggest applying the new form to all mapped (shared) identities.

## 3. Core Features

### A. Dynamic Rule Configuration (UI)
Business users must be able to define Match Rules.
- **Target Form:** Select Form Type (e.g., W9).
- **Attributes:** Choose fields to compare (e.g., Name, SSN, Address).
- **Match Algorithms:** Dropdown of available algorithms (e.g., Exact Match, Jaccard Index, Cosine, Jaro-Winkler).
- **Weights:** Assign percentage weights to each attribute (must sum to 100%).
- **Threshold:** Define the minimum total confidence score required to suggest a match (e.g., 85%).

### B. Async Scanning Engine (Backend)
- A background job that scans the 20,000+ client/manager database.
- Uses `fuzzy-matcher` and `java-string-similarity` to compare attributes.
- Handles the complex **Manager -> Child -> Parent** resolution by calling an external Service API to fetch the *actual* mapped Child Client data before string comparison.
- Generates a report of potential "Matches" (Suggestions).

### C. Maker-Checker Review (UI)
- The user downloads or views the generated report of potential matches.
- The UI displays side-by-side data and the calculated Match Confidence %.
- User approves or rejects the suggested mapping. Approved mappings are saved to a central Database mapping table.

### D. Intercept & Suggest (Backend & UI)
- When a user uploads or approves a new Tax Form for an entity, the system checks the `tax_form_mappings` table.
- If the entity is mapped to others, the system prompts the UI: *"Hey, we know this form is being shared with these managers/clients. Do you want to update that as well with this latest form?"*

## 4. Technical Architecture

### Tech Stack
- **Frontend:** React with JPMC Salt Design System.
- **Backend:** Java 17+, Spring Boot, Maven.
- **Database:** Relational DB (PostgreSQL / Oracle / MySQL).
- **Libraries:**
  - `com.intuit.fuzzymatcher:fuzzy-matcher:1.0.4`
  - `info.debatty:java-string-similarity:2.0.0`

### External Dependencies
- **Child Client Resolution API:** The background scanner must call this external REST endpoint to resolve `managerId` to `childClientId` and fetch the respective data prior to mapping.

## 5. Edge Cases Addressed
- **Legal Entity Standardization:** Name matching algorithms must handle suffix variations (e.g., "Narendra LLC" vs "Narendra Limited Liability Corporation"). This requires a pre-processing normalization step before the fuzzy match algorithm.

---
*Created via AI Agent*
