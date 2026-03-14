# Tax Form Mapper - Master Blueprint for AI Agents

**Target Engineer:** AI Agent / Development Team  
**System Objective:** Build a scalable, asynchronous backend and React frontend that intelligently links Clients and Managers based on matching Tax Form attributes (W9, W8, etc.) to enable form sharing.

## Overview
This directory contains a complete, robust system architecture. The system must process 20,000+ (scaling to 100k+) records, comparing entity attributes using Java fuzzing libraries, and pushing the output to a Maker-Checker React UI built with the JPMC Salt Design system.

To build this system, refer strictly to the attached documents in the following order:

### 1. Requirements & Core Logic
Read these to understand the business logic, the $O(N \times M)$ scaling challenge, and the UI metadata-driven approach.
*   **[Product Requirements Document (PRD)](./prd.md)**: Details the user flows, Maker-Checker review UI, and the end goal (prompting users to share forms).

### 2. Technical Architecture & Database
Read these before writing any Java or SQL code to understand the table relations and the Spring Batch optimization strategy.
*   **[Database Schema](./sql_schema.sql)**: Contains the table structures (`matching_rules`, `scan_jobs`, `tax_form_mappings`). *Start your implementation by deploying this schema.*
*   **[Technical Architecture & Scalability](./technical_architecture.md)**: Explains the necessary shift from `@Async` to `Spring Batch` (JdbcPagingItemReader) to prevent memory crashes when scaling to 100k clients. It also covers the caching strategy for the external child-resolution Service.

### 3. Implementation Patterns (Code References)
Read these for specific code logic requirements requested by the business user.
*   **[Implementation Guide: Normalizer & Metadata UI](./implementation_guide.md)**: *Crucial implementation details.* Contains the required `CompanyNameNormalizer` Java code to fix the "LLC vs Limited Liability Corporation" problem, and the JSON format needed for a Metadata-driven React UI.
*   **[Java Backend Plan](./backend_plan.md)**: High-level overview of the Spring Boot configuration, JPA entities, and API endpoint structures (`/v1/rules`, `/v1/scan-jobs`).
*   **[React Frontend Plan](./frontend_plan.md)**: Outlines the 4 primary views for the UI, dictating that the JPMC Salt Design system MUST be used.

## AI Implementation Instructions
1.  **Initialize:** Generate the Spring Boot application and configure the `pom.xml` with `spring-boot-starter-batch`, `fuzzy-matcher` (Intuit), and `java-string-similarity`.
2.  **Database:** Execute the SQL schema.
3.  **Backend Core:** Implement the `CompanyNameNormalizer`, the `MatchingService` (incorporating Token Cosine Similarity algorithms), and the REST Controllers based on the Metadata design.
4.  **Backend Batch:** Implement the Spring Batch jobs with caching for the external Child Resolution API.
5.  **Frontend:** Build the Maker/Checker UI components matching the backend Metadata JSON payloads using Salt design components.
