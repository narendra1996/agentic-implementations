# Product Requirements Document: Metadata-Driven Tax Forms System

> **FOR AI AGENT IMPLEMENTATION**: This document contains precise specifications. Follow exactly as written. Do not add features not specified. Do not modify data structures.

---

## 1. PROJECT OVERVIEW

### 1.1 Objective
Build a metadata-driven dynamic form rendering system for US IRS Tax Forms.

### 1.2 Forms in Scope
| Form Code | Form Name |
|-----------|-----------|
| `W9` | Request for Taxpayer Identification Number and Certification |
| `W8-BEN-E` | Certificate of Status of Beneficial Owner (Entities) |
| `W8-ECI` | Certificate of Foreign Person's Claim for Effectively Connected Income |
| `W8-EXP` | Certificate of Foreign Government or Other Foreign Organization |
| `W8-IMY` | Certificate of Foreign Intermediary |

### 1.3 Technology Stack
| Layer | Technology | Version |
|-------|------------|---------|
| Database | Oracle | 19c+ |
| Backend | Java Spring Boot | 3.x |
| Frontend | React + TypeScript | 18.x |
| UI Components | JP Morgan Salt Design System | Latest |

---

## 2. FUNCTIONAL REQUIREMENTS

### 2.1 Core Features

#### FR-001: Dynamic Form Rendering
- System MUST render forms dynamically based on metadata from database
- No form layouts should be hardcoded in frontend code
- Form structure is defined entirely in database tables

#### FR-002: Form Sections
- Each form has multiple sections (e.g., Basic Info, Address, Treaty Claims)
- Sections have a display order
- Sections can be marked as repeatable or non-repeatable

#### FR-003: Repeatable Sections
- A section marked as `IS_REPEATABLE = 'Y'` can have multiple instances
- Each section has `MIN_OCCURRENCES` (default: 1) and `MAX_OCCURRENCES` (null = unlimited)
- UI must provide "Add" and "Remove" buttons for repeatable sections
- Example: Treaty Claims section can be added 0-10 times

#### FR-004: Field Types
System MUST support these field types:
```
TEXT, TEXTAREA, NUMBER, EMAIL, PHONE, DATE,
DROPDOWN, RADIO, CHECKBOX, CHECKBOX_GROUP,
COUNTRY_SELECTOR, SSN, EIN, TIN, SIGNATURE
```

#### FR-005: Dropdown Configuration
- Dropdown values are stored in a separate table (`DROPDOWN_VALUES`)
- Each dropdown field has a `DROPDOWN_CONFIG_KEY` referencing the values
- Dropdowns are loaded in batch when form loads
- Example keys: `FEDERAL_TAX_CLASSIFICATION`, `COUNTRIES`, `CHAPTER3_STATUS`

#### FR-006: External Data Integration
- Form data is NOT stored in this system's database
- Data is submitted to an external service (API endpoint to be configured)
- Existing data is loaded from external service for editing

#### FR-007: Java POJO Binding
- Each form has a corresponding Java POJO class
- Field codes use `@JsonProperty` annotation for mapping
- Repeatable sections use `@JsonAnySetter` and `@JsonAnyGetter`
- Service layer provides type-safe binding: `Map<String, Object>` ↔ `FormDataPOJO`

---

## 3. DATA MODEL

### 3.1 Database Tables

> **AGENT INSTRUCTION**: Create exactly these 5 tables with the exact column names, types, and constraints shown.

#### Table 1: FORM_TEMPLATES
```sql
CREATE TABLE FORM_TEMPLATES (
    FORM_ID           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    FORM_CODE         VARCHAR2(50) NOT NULL UNIQUE,
    FORM_NAME         VARCHAR2(255) NOT NULL,
    FORM_DESCRIPTION  VARCHAR2(1000),
    FORM_VERSION      NUMBER(5,2) DEFAULT 1.0,
    STATUS            VARCHAR2(20) DEFAULT 'DRAFT' CHECK (STATUS IN ('DRAFT', 'ACTIVE', 'ARCHIVED')),
    CREATED_AT        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CREATED_BY        VARCHAR2(100)
);

CREATE INDEX IDX_FORM_TEMPLATES_CODE ON FORM_TEMPLATES(FORM_CODE);
CREATE INDEX IDX_FORM_TEMPLATES_STATUS ON FORM_TEMPLATES(STATUS);
```

#### Table 2: FORM_SECTIONS
```sql
CREATE TABLE FORM_SECTIONS (
    SECTION_ID          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    FORM_ID             NUMBER NOT NULL REFERENCES FORM_TEMPLATES(FORM_ID),
    SECTION_CODE        VARCHAR2(100) NOT NULL,
    SECTION_NAME        VARCHAR2(255) NOT NULL,
    DISPLAY_ORDER       NUMBER(5) NOT NULL,
    MIN_OCCURRENCES     NUMBER(3) DEFAULT 1,
    MAX_OCCURRENCES     NUMBER(3),
    IS_REPEATABLE       CHAR(1) DEFAULT 'N' CHECK (IS_REPEATABLE IN ('Y', 'N')),
    SECTION_DESCRIPTION VARCHAR2(1000),
    STATUS              VARCHAR2(20) DEFAULT 'ACTIVE',
    CONSTRAINT UK_SECTION_CODE UNIQUE (FORM_ID, SECTION_CODE)
);

CREATE INDEX IDX_SECTIONS_FORM_ID ON FORM_SECTIONS(FORM_ID);
CREATE INDEX IDX_SECTIONS_ORDER ON FORM_SECTIONS(FORM_ID, DISPLAY_ORDER);
```

#### Table 3: FORM_FIELDS
```sql
CREATE TABLE FORM_FIELDS (
    FIELD_ID            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    SECTION_ID          NUMBER NOT NULL REFERENCES FORM_SECTIONS(SECTION_ID),
    FIELD_CODE          VARCHAR2(100) NOT NULL,
    FIELD_LABEL         VARCHAR2(255) NOT NULL,
    FIELD_TYPE          VARCHAR2(50) NOT NULL CHECK (FIELD_TYPE IN (
        'TEXT', 'TEXTAREA', 'NUMBER', 'EMAIL', 'PHONE', 'DATE',
        'DROPDOWN', 'RADIO', 'CHECKBOX', 'CHECKBOX_GROUP',
        'COUNTRY_SELECTOR', 'SSN', 'EIN', 'TIN', 'SIGNATURE'
    )),
    DISPLAY_ORDER       NUMBER(5) NOT NULL,
    IS_REQUIRED         CHAR(1) DEFAULT 'N' CHECK (IS_REQUIRED IN ('Y', 'N')),
    DEFAULT_VALUE       VARCHAR2(500),
    VALIDATION_REGEX    VARCHAR2(500),
    MAX_LENGTH          NUMBER(5),
    MIN_VALUE           NUMBER,
    MAX_VALUE           NUMBER,
    DROPDOWN_CONFIG_KEY VARCHAR2(100),
    PLACEHOLDER_TEXT    VARCHAR2(255),
    HELP_TEXT           VARCHAR2(1000),
    COL_SPAN            NUMBER(2) DEFAULT 6 CHECK (COL_SPAN BETWEEN 1 AND 12),
    STATUS              VARCHAR2(20) DEFAULT 'ACTIVE',
    CONSTRAINT UK_FIELD_CODE UNIQUE (SECTION_ID, FIELD_CODE)
);

CREATE INDEX IDX_FIELDS_SECTION_ID ON FORM_FIELDS(SECTION_ID);
CREATE INDEX IDX_FIELDS_ORDER ON FORM_FIELDS(SECTION_ID, DISPLAY_ORDER);
CREATE INDEX IDX_FIELDS_DROPDOWN ON FORM_FIELDS(DROPDOWN_CONFIG_KEY);
```

#### Table 4: DROPDOWN_CONFIGS
```sql
CREATE TABLE DROPDOWN_CONFIGS (
    CONFIG_KEY    VARCHAR2(100) PRIMARY KEY,
    CONFIG_NAME   VARCHAR2(255) NOT NULL,
    DESCRIPTION   VARCHAR2(1000),
    STATUS        VARCHAR2(20) DEFAULT 'ACTIVE'
);
```

#### Table 5: DROPDOWN_VALUES
```sql
CREATE TABLE DROPDOWN_VALUES (
    VALUE_ID          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    CONFIG_KEY        VARCHAR2(100) NOT NULL REFERENCES DROPDOWN_CONFIGS(CONFIG_KEY),
    VALUE_CODE        VARCHAR2(100) NOT NULL,
    DISPLAY_TEXT      VARCHAR2(255) NOT NULL,
    DISPLAY_ORDER     NUMBER(5) NOT NULL,
    IS_ACTIVE         CHAR(1) DEFAULT 'Y' CHECK (IS_ACTIVE IN ('Y', 'N')),
    PARENT_VALUE_CODE VARCHAR2(100),
    CONSTRAINT UK_DROPDOWN_VALUE UNIQUE (CONFIG_KEY, VALUE_CODE)
);

CREATE INDEX IDX_DROPDOWN_VALUES_KEY ON DROPDOWN_VALUES(CONFIG_KEY);
```

---

## 4. API SPECIFICATIONS

### 4.1 REST Endpoints

> **AGENT INSTRUCTION**: Implement exactly these endpoints. Do not add more endpoints.

| Method | Path | Description | Response |
|--------|------|-------------|----------|
| `GET` | `/api/forms` | List all active form templates | `List<FormTemplateDTO>` |
| `GET` | `/api/forms/{formCode}` | Get complete form metadata | `FormMetadataDTO` |
| `GET` | `/api/dropdowns/{configKey}` | Get dropdown values | `List<DropdownValueDTO>` |
| `GET` | `/api/dropdowns/batch?keys=KEY1,KEY2` | Get multiple dropdowns | `Map<String, List<DropdownValueDTO>>` |

### 4.2 Response DTOs

#### FormMetadataDTO
```java
public class FormMetadataDTO {
    private String formCode;
    private String formName;
    private String formDescription;
    private Double version;
    private List<SectionDTO> sections;
    private Map<String, List<DropdownValueDTO>> dropdowns;
}
```

#### SectionDTO
```java
public class SectionDTO {
    private String sectionCode;
    private String sectionName;
    private String description;
    private Integer displayOrder;
    private boolean isRepeatable;
    private Integer minOccurrences;
    private Integer maxOccurrences;
    private List<FieldDTO> fields;
}
```

#### FieldDTO
```java
public class FieldDTO {
    private String fieldCode;
    private String fieldLabel;
    private String fieldType;
    private Integer displayOrder;
    private boolean isRequired;
    private String defaultValue;
    private String validationRegex;
    private Integer maxLength;
    private Number minValue;
    private Number maxValue;
    private String dropdownConfigKey;
    private String placeholderText;
    private String helpText;
    private Integer colSpan;
}
```

#### DropdownValueDTO
```java
public class DropdownValueDTO {
    private String valueCode;
    private String displayText;
    private Integer displayOrder;
}
```

---

## 5. JAVA BACKEND STRUCTURE

### 5.1 Package Structure

> **AGENT INSTRUCTION**: Create this exact package structure.

```
src/main/java/com/taxforms/
├── TaxFormsApplication.java
├── config/
│   ├── CacheConfig.java
│   └── CorsConfig.java
├── controller/
│   ├── FormController.java
│   └── DropdownController.java
├── service/
│   ├── MetadataService.java
│   ├── DropdownService.java
│   └── FormDataBindingService.java
├── repository/
│   ├── FormTemplateRepository.java
│   ├── FormSectionRepository.java
│   ├── FormFieldRepository.java
│   └── DropdownRepository.java
├── model/
│   ├── entity/
│   │   ├── FormTemplate.java
│   │   ├── FormSection.java
│   │   ├── FormField.java
│   │   ├── DropdownConfig.java
│   │   └── DropdownValue.java
│   ├── dto/
│   │   ├── FormMetadataDTO.java
│   │   ├── SectionDTO.java
│   │   ├── FieldDTO.java
│   │   └── DropdownValueDTO.java
│   └── formdata/
│       ├── BaseFormData.java
│       ├── W9FormData.java
│       ├── W8BenEFormData.java
│       ├── W8EciFormData.java
│       ├── W8ExpFormData.java
│       ├── W8ImyFormData.java
│       └── TreatyClaim.java
├── mapper/
│   └── FormMetadataMapper.java
└── exception/
    ├── FormNotFoundException.java
    └── GlobalExceptionHandler.java
```

### 5.2 Key Implementation Details

#### MetadataService
- Use `@Cacheable("formMetadata")` on `getFormMetadata(String formCode)`
- Pre-fetch all dropdowns needed for the form in single method call
- Return complete metadata with sections ordered by `displayOrder`

#### FormDataBindingService
- Maintain map of form codes to POJO classes
- Use Jackson ObjectMapper for conversion
- Methods: `bindFormData(formCode, flatData)` and `flattenFormData(pojoData)`

---

## 6. REACT FRONTEND STRUCTURE

### 6.1 Project Setup

> **AGENT INSTRUCTION**: Use Vite with React and TypeScript.

```bash
npm create vite@latest tax-forms-ui -- --template react-ts
cd tax-forms-ui
npm install @salt-ds/core @salt-ds/theme @salt-ds/icons @salt-ds/lab
npm install @fontsource/open-sans @fontsource/pt-mono
npm install axios react-router-dom
```

### 6.2 Directory Structure

> **AGENT INSTRUCTION**: Create this exact folder structure.

```
src/
├── main.tsx
├── App.tsx
├── index.css
├── components/
│   ├── form/
│   │   ├── FormRenderer.tsx
│   │   ├── SectionRenderer.tsx
│   │   ├── RepeatableSectionRenderer.tsx
│   │   └── FieldRenderer.tsx
│   └── fields/
│       ├── TextField.tsx
│       ├── TextAreaField.tsx
│       ├── NumberField.tsx
│       ├── DateField.tsx
│       ├── DropdownField.tsx
│       ├── RadioField.tsx
│       ├── CheckboxField.tsx
│       ├── CountrySelector.tsx
│       ├── MaskedTextField.tsx
│       └── SignatureField.tsx
├── hooks/
│   ├── useFormMetadata.ts
│   └── useFormData.ts
├── services/
│   ├── metadataService.ts
│   └── externalDataService.ts
├── types/
│   ├── FormMetadata.ts
│   └── FormData.ts
├── context/
│   └── FormContext.tsx
├── pages/
│   ├── FormListPage.tsx
│   ├── FormNewPage.tsx
│   └── FormEditPage.tsx
└── utils/
    └── fieldTypeRegistry.ts
```

### 6.3 Salt Design System Setup

```tsx
// src/main.tsx
import "@fontsource/open-sans/300.css";
import "@fontsource/open-sans/400.css";
import "@fontsource/open-sans/600.css";
import "@fontsource/open-sans/700.css";
import "@fontsource/pt-mono";
import "@salt-ds/theme/index.css";

import { SaltProvider } from "@salt-ds/core";
import App from "./App";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <SaltProvider>
    <App />
  </SaltProvider>
);
```

### 6.4 Field Type to Salt Component Mapping

| Field Type | Salt Component | Import From |
|------------|----------------|-------------|
| `TEXT` | `Input` | `@salt-ds/core` |
| `TEXTAREA` | `MultilineInput` | `@salt-ds/core` |
| `NUMBER` | `Input` (type="number") | `@salt-ds/core` |
| `EMAIL` | `Input` (type="email") | `@salt-ds/core` |
| `DATE` | `DatePicker` | `@salt-ds/lab` |
| `DROPDOWN` | `Dropdown` + `Option` | `@salt-ds/core` |
| `RADIO` | `RadioButton` + `RadioButtonGroup` | `@salt-ds/core` |
| `CHECKBOX` | `Checkbox` | `@salt-ds/core` |
| `CHECKBOX_GROUP` | `CheckboxGroup` | `@salt-ds/core` |
| `COUNTRY_SELECTOR` | `ComboBox` | `@salt-ds/core` |
| `SSN` / `EIN` / `TIN` | Custom masked `Input` | `@salt-ds/core` |
| `SIGNATURE` | Custom canvas component | Custom |

---

## 7. DATA CONTRACTS

### 7.1 Form Data Key Convention

| Section Type | Key Format | Example |
|--------------|-----------|---------|
| Non-repeatable | `{SECTION_CODE}.{FIELD_CODE}` | `BASIC_INFO.NAME` |
| Repeatable | `{SECTION_CODE}[{index}].{FIELD_CODE}` | `TREATY_CLAIMS[0].TREATY_COUNTRY` |

### 7.2 Submit Payload Structure
```json
{
  "formCode": "W9",
  "submissionId": null,
  "data": {
    "BASIC_INFO.NAME": "John Smith",
    "BASIC_INFO.FEDERAL_TAX_CLASSIFICATION": "LLC",
    "ADDRESS.STREET_ADDRESS": "123 Main St",
    "ADDRESS.CITY": "New York",
    "ADDRESS.STATE": "NY",
    "ADDRESS.ZIP_CODE": "10001"
  }
}
```

### 7.3 Repeatable Section Payload
```json
{
  "formCode": "W8-BEN-E",
  "submissionId": "SUB-123",
  "data": {
    "BENEFICIAL_OWNER.ORG_NAME": "Global Corp",
    "TREATY_CLAIMS[0].TREATY_COUNTRY": "UK",
    "TREATY_CLAIMS[0].WITHHOLDING_RATE": 15,
    "TREATY_CLAIMS[1].TREATY_COUNTRY": "Germany",
    "TREATY_CLAIMS[1].WITHHOLDING_RATE": 10
  }
}
```

---

## 8. SAMPLE DATA

### 8.1 Insert W9 Form Metadata

> **AGENT INSTRUCTION**: Create this sample data after creating tables.

See file: `SAMPLE-DATA.sql` (attached)

---

## 9. IMPLEMENTATION ORDER

> **AGENT INSTRUCTION**: Follow this exact sequence.

### Phase 1: Backend Setup
1. Create Spring Boot project with dependencies
2. Create database tables (use attached DDL scripts)
3. Create entity classes
4. Create repositories (Spring Data JPA)
5. Create DTOs
6. Create MetadataService with caching
7. Create DropdownService
8. Create REST controllers
9. Add CORS configuration
10. Test API endpoints

### Phase 2: Frontend Setup
1. Create Vite React TypeScript project
2. Install Salt Design System packages
3. Setup SaltProvider in main.tsx
4. Create TypeScript types
5. Create API service classes
6. Create FormContext
7. Create FieldRenderer with registry pattern
8. Create all field components using Salt
9. Create SectionRenderer
10. Create RepeatableSectionRenderer
11. Create FormRenderer
12. Create pages (List, New, Edit)
13. Setup React Router

### Phase 3: Integration
1. Create FormDataBindingService for POJO mapping
2. Create form-specific POJO classes
3. Test full flow: metadata → render → submit

---

## 10. ACCEPTANCE CRITERIA

- [ ] All 5 database tables created with correct constraints
- [ ] API returns form metadata with sections and fields
- [ ] Dropdowns loaded in batch with form metadata
- [ ] Form renders dynamically based on metadata
- [ ] Repeatable sections can be added/removed
- [ ] All field types render with Salt components
- [ ] Form data submitted in correct JSON format
- [ ] Existing data pre-populates form fields
- [ ] Java POJOs correctly bind form data

---

## ATTACHED FILES

1. `SAMPLE-DATA.sql` - Database seed data for W9 form
2. `JAVA-TEMPLATES.md` - Key Java class implementations
3. `REACT-TEMPLATES.md` - Key React component implementations
