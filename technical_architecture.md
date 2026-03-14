# Comprehensive Technical Architecture: Tax Form Mapper

## 1. System Overview
The Tax Form Mapper is a scalable backend service responsible for establishing intelligent linkages between Managers, Child Clients, and Parent Clients based on configurable fuzzy-matching rules applied to Tax Form attributes (e.g., matching a W9 Name and SSN).

This architecture focuses on a robust, asynchronous, and scalable approach suitable for processing tens of thousands of records without degrading API performance.

## 2. Component Design & Responsibilities

### A. Core Engine (`TaxFormMatcherService`)
This central engine orchestration component coordinates the normalization, scoring, and rule evaluation.
*   **Normalizer Strategy:** Before comparing strings like "Narendra LLC" vs "Narendra Limited Liability Corporation," the system passes data through standardizer pipelines. You should maintain a metadata table (`entity_type_abbreviations`) to map common suffixes (Limited Liability Corporation $\rightarrow$ LLC, Incorporated $\rightarrow$ INC).
*   **Scoring Engine:** Iterates over the user's `RuleConfiguration`. For each attribute (Name, SSN):
    *   Determines the chosen algorithm (e.g., Jaro-Winkler, Cosine).
    *   Calls the respective library (`info.debatty:java-string-similarity` or Intuit's `fuzzy-matcher`).
    *   Multiplies the algorithm score by the configured `weight` (e.g., 0.60 for Name).
*   **Threshold Evaluator:** Sums the weighted scores and compares them against the user-defined `confidence_threshold` (e.g., >85.0%).

### B. Scalable Processing: Spring Batch Job (`ScanJobConfiguration`)
Because matching 20,000 clients and their respective managers is an $O(N \times M)$ operation, performing this in a standard HTTP `@Async` context is risky (memory bloat, transaction timeouts).
*   **Approach:** Implement **Spring Batch**.
*   **Job Trigger:** A user submits the configuration (`POST /api/v1/scan-jobs`). The API synchronously creates a `JobExecution` and returns a `202 Accepted` with a Job ID for UI polling.
*   **ItemReader:** A JdbcPagingItemReader that queries all unstructured/unmapped Managers in configurable chunk sizes (e.g., `chunk(100)`).
*   **ItemProcessor (The Core Logic):**
    1.  *External Lookup:* Takes the Manager ID, makes an HTTP REST call to your external Client Resolution Service to fetch the corresponding Child Client ID and Tax Form payload.
    2.  *Cache Optimization:* Wrap the external service call in `@Cacheable("childClientResolution")` (backed by Redis or simple Caffeine/Guava cache). If multiple managers map to the same child, we avoid hammering the external API.
    3.  *Match Evaluation:* Executes the `TaxFormMatcherService` logic against potential Parent Client targets.
    4.  *Returns:* A `MatchSuggestion` object if the threshold is met; otherwise, returns `null` (Spring Batch filters these out).
*   **ItemWriter:** Writes the generated `MatchSuggestion` entities to the database in bulk (`tax_form_suggestions` table), minimizing I/O overhead.

### C. Review & Approval API (`SuggestionsController`)
Supports the Checker UI.
*   **Data Retrieval:** `GET /api/v1/suggestions?jobId={id}&status=PENDING&page=0&size=50`
    *   Must support server-side pagination to render large grids efficiently.
*   **Approval Flow:** `POST /api/v1/suggestions/approve`
    *   Accepts a list of `suggestionIds`.
    *   Updates the status to `APPROVED` in the suggestions table.
    *   Inserts the final linkage into the core `tax_form_mappings` table.
    *   *Transactionality:* Essential that this is wrapped in a single `@Transactional` method to prevent orphaned records.

### D. Real-Time Interception API (`InterceptorController`)
This is the touchpoint for your existing systems when a new tax form is uploaded.
*   **Endpoint:** `GET /api/v1/mappings/shared-status?entityId={managerOrClientId}`
*   **Logic:** Performs a fast lookup on the indexed `tax_form_mappings` table.
*   **Response:**
    *   If no mapping: `{ shared: false }`
    *   If mapping exists: `{ shared: true, linkedEntities: [{ id: "A", type: "CLIENT" }] }`
    *   The upstream UI uses this to display the *"Do you want to update connected profiles?"* dialog.

## 3. Database Indexing Strategy
To ensure the Spring Batch read operations and Real-Time Interception API perform safely at scale:
*   `INDEX idx_mappings_source (source_entity_id)`
*   `INDEX idx_mappings_target (target_entity_id)`
*   `INDEX idx_suggestions_job (job_id, status)`

## 4. Why this Architecture is Robust
1.  **Fault Tolerance:** If the external Child Resolution API returns a 5xx error or times out, Spring Batch's connection rules can implement `SkipPolicy` or `RetryPolicy` parameters, ensuring 1 bad client response doesn't kill the scanning job for the other 19,999 records.
2.  **Memory Safe:** Chunked processing prevents the JVM from trying to load all 20k managers and their text-heavy Form attributes into memory simultaneously.
3.  **Auditability:** The Maker-Checker database flow (Suggestions $\rightarrow$ Mappings) provides a clear audit trail of *who* approved *which* AI-suggested AI mapping and *when*.
