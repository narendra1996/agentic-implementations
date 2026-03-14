# Frontend Implementation Plan - Tax Form Mapper

## Overview
This document outlines the React frontend architecture for the Tax Form Mapper utilizing the JP Morgan Chase Salt Design System. The UI is designed as an internal administrative tool (Maker-Checker paradigm).

## 1. Core Technologies
*   **Framework:** React 18+
*   **Design System:** JP Morgan Salt Design System (`@salt-ds/core`, `@salt-ds/icons`)
*   **State Management:** React Context API or Redux Toolkit (depending on existing app standards)
*   **Routing:** React Router v6
*   **Data Fetching:** Axios or React Query

## 2. Key Pages & Components

### View 1: Rule Configuration & Scan Submitter (The "Maker" UI)
This complex form allows business users to define exactly *how* the system should match entities.
*   **Form Type Selector:** Dropdown (e.g., W9, W8-BENE).
*   **Attribute Builder (Dynamic List):**
    *   Users can add multiple rows.
    *   Each row has: Attribute Dropdown (Name, SSN), Algorithm Dropdown (Exact, Cosine, Jaro-Winkler), and a Slider/Input for Weight %.
    *   *Validation:* The sum of all weights must equal exactly 100%.
*   **Confidence Threshold:** Slider input from 50% to 100%.
*   **Action:** Submit button that calls `POST /api/v1/scan-jobs` and redirects the user to the Job Status Tracker.

### View 2: Job Status Tracker
*   A polling dashboard that queries `GET /api/v1/scan-jobs/{id}/status`.
*   Displays a Progress Bar and status (PENDING -> RUNNING -> COMPLETED).
*   Upon completion, displays a "Review Results" button.

### View 3: Suggested Matches Review (The "Checker" UI)
*   A large Data Grid / Table displaying the payload from `GET /api/v1/suggestions`.
*   **Columns:** 
    *   Entity A (Name, ID, Role)
    *   Entity B (Name, ID, Role)
    *   Match Confidence (Rendered with color coding: Green > 95%, Yellow > 85%,  etc.)
    *   Checkbox for Selection.
*   **Action:** Bulk "Approve Selected" or "Reject Selected" buttons. Approving calls the backend to finalize the mapping.

### View 4: Intercept Modal / Dialog Component
This is a reusable React Component (`SharedFormSuggestionDialog`) that is injected into the existing "Upload Tax Form" screen of your main application.
*   When a new form is uploaded, the UI checks if it's mapped.
*   If true, this Modal pops up.
*   **Content:** *"We detected that this entity shares a Tax Form mapping with the following Managers/Clients [List...]. Would you like to update their records as well?"*
*   **Actions:** "Yes, Update All" / "No, Only This Entity".

## 3. UI/UX Considerations
*   **Data Grid Pagination:** The scan might return thousands of suggestions. The Data Grid must support server-side pagination.
*   **Algorithm Education:** The algorithm dropdowns in the Rule Builder should include Salt UI Tooltips explaining what the algorithm actually does (e.g., *Cosine: Best for words out of order. Jaro-Winkler: Best for typos.*)

## 4. Required User Clarifications
1.  **Salt Workflow Integration:** Are we injecting these screens into an existing React application shell, or is this a standalone greenfield app?
2.  **Authentication:** Does the UI need to integrate with an existing SSO provider (e.g., PingFederate, Okta) to determine User Identity and Roles (Maker vs Checker)?
