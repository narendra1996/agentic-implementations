# React Implementation Templates

> **FOR AI AGENT**: Use these templates as the basis for implementation. Use JP Morgan Salt Design System components.

---

## 1. Project Setup

### Create Project
```bash
npm create vite@latest tax-forms-ui -- --template react-ts
cd tax-forms-ui
npm install @salt-ds/core @salt-ds/theme @salt-ds/icons @salt-ds/lab
npm install @fontsource/open-sans @fontsource/pt-mono
npm install axios react-router-dom
npm install --save-dev @types/react-router-dom
```

---

## 2. Entry Point

### src/main.tsx
```tsx
import React from "react";
import ReactDOM from "react-dom/client";
import "@fontsource/open-sans/300.css";
import "@fontsource/open-sans/400.css";
import "@fontsource/open-sans/600.css";
import "@fontsource/open-sans/700.css";
import "@fontsource/pt-mono";
import "@salt-ds/theme/index.css";
import "./index.css";

import { SaltProvider } from "@salt-ds/core";
import { BrowserRouter } from "react-router-dom";
import App from "./App";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <SaltProvider>
      <BrowserRouter>
        <App />
      </BrowserRouter>
    </SaltProvider>
  </React.StrictMode>
);
```

### src/App.tsx
```tsx
import { Routes, Route } from "react-router-dom";
import { FormListPage } from "./pages/FormListPage";
import { FormNewPage } from "./pages/FormNewPage";
import { FormEditPage } from "./pages/FormEditPage";

function App() {
  return (
    <div className="app-container">
      <Routes>
        <Route path="/" element={<FormListPage />} />
        <Route path="/forms/:formCode/new" element={<FormNewPage />} />
        <Route path="/forms/:formCode/edit/:submissionId" element={<FormEditPage />} />
      </Routes>
    </div>
  );
}

export default App;
```

### src/index.css
```css
:root {
  font-family: "Open Sans", sans-serif;
}

.app-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px;
}

.form-container {
  background: var(--salt-container-primary-background);
  border-radius: 8px;
  padding: 24px;
}

.form-header {
  margin-bottom: 24px;
}

.form-title {
  font-size: 24px;
  font-weight: 600;
  margin-bottom: 8px;
}

.section {
  margin-bottom: 32px;
  padding: 20px;
  background: var(--salt-container-secondary-background);
  border-radius: 8px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.section-title {
  font-size: 18px;
  font-weight: 600;
}

.fields-grid {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  gap: 16px;
}

.col-span-1 { grid-column: span 1; }
.col-span-2 { grid-column: span 2; }
.col-span-3 { grid-column: span 3; }
.col-span-4 { grid-column: span 4; }
.col-span-5 { grid-column: span 5; }
.col-span-6 { grid-column: span 6; }
.col-span-7 { grid-column: span 7; }
.col-span-8 { grid-column: span 8; }
.col-span-9 { grid-column: span 9; }
.col-span-10 { grid-column: span 10; }
.col-span-11 { grid-column: span 11; }
.col-span-12 { grid-column: span 12; }

.repeatable-section {
  border: 1px solid var(--salt-container-borderColor);
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 16px;
}

.occurrence-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid var(--salt-container-borderColor);
}

.form-actions {
  margin-top: 24px;
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}
```

---

## 3. TypeScript Types

### src/types/FormMetadata.ts
```typescript
export interface FormTemplate {
  formCode: string;
  formName: string;
}

export interface FormMetadata {
  formCode: string;
  formName: string;
  formDescription?: string;
  version: number;
  sections: Section[];
  dropdowns: Record<string, DropdownOption[]>;
}

export interface Section {
  sectionCode: string;
  sectionName: string;
  description?: string;
  displayOrder: number;
  isRepeatable: boolean;
  minOccurrences: number;
  maxOccurrences?: number | null;
  fields: Field[];
}

export interface Field {
  fieldCode: string;
  fieldLabel: string;
  fieldType: FieldType;
  displayOrder: number;
  isRequired: boolean;
  defaultValue?: string;
  validationRegex?: string;
  maxLength?: number;
  minValue?: number;
  maxValue?: number;
  dropdownConfigKey?: string;
  placeholderText?: string;
  helpText?: string;
  colSpan: number;
}

export type FieldType =
  | "TEXT"
  | "TEXTAREA"
  | "NUMBER"
  | "EMAIL"
  | "PHONE"
  | "DATE"
  | "DROPDOWN"
  | "RADIO"
  | "CHECKBOX"
  | "CHECKBOX_GROUP"
  | "COUNTRY_SELECTOR"
  | "SSN"
  | "EIN"
  | "TIN"
  | "SIGNATURE";

export interface DropdownOption {
  valueCode: string;
  displayText: string;
  displayOrder: number;
}
```

### src/types/FormData.ts
```typescript
export type FormData = Record<string, any>;

export interface FormSubmission {
  formCode: string;
  submissionId?: string;
  data: FormData;
}
```

---

## 4. Context

### src/context/FormContext.tsx
```tsx
import { createContext, useContext } from "react";
import { FormData, DropdownOption } from "../types/FormMetadata";

interface FormContextType {
  formData: FormData;
  dropdowns: Record<string, DropdownOption[]>;
  errors: Record<string, string>;
  handleFieldChange: (
    sectionCode: string,
    fieldCode: string,
    value: any,
    occurrenceIndex?: number
  ) => void;
}

export const FormContext = createContext<FormContextType | null>(null);

export const useFormContext = () => {
  const context = useContext(FormContext);
  if (!context) {
    throw new Error("useFormContext must be used within FormContext.Provider");
  }
  return context;
};
```

---

## 5. API Services

### src/services/metadataService.ts
```typescript
import axios from "axios";
import { FormMetadata, FormTemplate } from "../types/FormMetadata";

const API_BASE = import.meta.env.VITE_API_URL || "http://localhost:8080/api";

export const metadataService = {
  async getAllForms(): Promise<FormTemplate[]> {
    const response = await axios.get<FormTemplate[]>(`${API_BASE}/forms`);
    return response.data;
  },

  async getFormMetadata(formCode: string): Promise<FormMetadata> {
    const response = await axios.get<FormMetadata>(`${API_BASE}/forms/${formCode}`);
    return response.data;
  },
};
```

### src/services/externalDataService.ts
```typescript
import axios from "axios";
import { FormSubmission, FormData } from "../types/FormData";

// Configure this to your external service URL
const EXTERNAL_API_BASE = import.meta.env.VITE_EXTERNAL_API_URL || "http://localhost:8081/api";

export const externalDataService = {
  async getSubmission(submissionId: string): Promise<FormSubmission> {
    const response = await axios.get<FormSubmission>(
      `${EXTERNAL_API_BASE}/submissions/${submissionId}`
    );
    return response.data;
  },

  async createSubmission(data: FormSubmission): Promise<{ submissionId: string }> {
    const response = await axios.post(`${EXTERNAL_API_BASE}/submissions`, data);
    return response.data;
  },

  async updateSubmission(submissionId: string, data: FormSubmission): Promise<void> {
    await axios.put(`${EXTERNAL_API_BASE}/submissions/${submissionId}`, data);
  },
};
```

---

## 6. Hooks

### src/hooks/useFormMetadata.ts
```typescript
import { useState, useEffect } from "react";
import { FormMetadata, DropdownOption } from "../types/FormMetadata";
import { metadataService } from "../services/metadataService";

interface UseFormMetadataResult {
  metadata: FormMetadata | null;
  dropdowns: Record<string, DropdownOption[]>;
  loading: boolean;
  error: string | null;
}

export const useFormMetadata = (formCode: string): UseFormMetadataResult => {
  const [metadata, setMetadata] = useState<FormMetadata | null>(null);
  const [dropdowns, setDropdowns] = useState<Record<string, DropdownOption[]>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchMetadata = async () => {
      try {
        setLoading(true);
        const data = await metadataService.getFormMetadata(formCode);
        setMetadata(data);
        setDropdowns(data.dropdowns || {});
        setError(null);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Failed to load form");
      } finally {
        setLoading(false);
      }
    };

    if (formCode) {
      fetchMetadata();
    }
  }, [formCode]);

  return { metadata, dropdowns, loading, error };
};
```

---

## 7. Form Components

### src/components/form/FormRenderer.tsx
```tsx
import React, { useState, useEffect } from "react";
import { Button, StackLayout, Text } from "@salt-ds/core";
import { FormMetadata, DropdownOption } from "../../types/FormMetadata";
import { FormData } from "../../types/FormData";
import { FormContext } from "../../context/FormContext";
import { SectionRenderer } from "./SectionRenderer";
import { RepeatableSectionRenderer } from "./RepeatableSectionRenderer";
import { useFormMetadata } from "../../hooks/useFormMetadata";

interface FormRendererProps {
  formCode: string;
  initialData?: FormData;
  onSubmit: (data: FormData) => void;
}

export const FormRenderer: React.FC<FormRendererProps> = ({
  formCode,
  initialData = {},
  onSubmit,
}) => {
  const { metadata, dropdowns, loading, error } = useFormMetadata(formCode);
  const [formData, setFormData] = useState<FormData>(initialData);
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    if (initialData && Object.keys(initialData).length > 0) {
      setFormData(initialData);
    }
  }, [initialData]);

  const handleFieldChange = (
    sectionCode: string,
    fieldCode: string,
    value: any,
    occurrenceIndex?: number
  ) => {
    const key =
      occurrenceIndex !== undefined
        ? `${sectionCode}[${occurrenceIndex}].${fieldCode}`
        : `${sectionCode}.${fieldCode}`;

    setFormData((prev) => ({ ...prev, [key]: value }));
    
    // Clear error when field is modified
    if (errors[key]) {
      setErrors((prev) => {
        const newErrors = { ...prev };
        delete newErrors[key];
        return newErrors;
      });
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Add validation here if needed
    onSubmit(formData);
  };

  if (loading) {
    return <Text>Loading form...</Text>;
  }

  if (error) {
    return <Text color="error">Error: {error}</Text>;
  }

  if (!metadata) {
    return null;
  }

  return (
    <FormContext.Provider value={{ formData, dropdowns, errors, handleFieldChange }}>
      <form onSubmit={handleSubmit} className="form-container">
        <div className="form-header">
          <h1 className="form-title">{metadata.formName}</h1>
          {metadata.formDescription && (
            <Text color="secondary">{metadata.formDescription}</Text>
          )}
        </div>

        <StackLayout gap={3}>
          {metadata.sections.map((section) =>
            section.isRepeatable ? (
              <RepeatableSectionRenderer
                key={section.sectionCode}
                section={section}
              />
            ) : (
              <SectionRenderer key={section.sectionCode} section={section} />
            )
          )}
        </StackLayout>

        <div className="form-actions">
          <Button type="button" appearance="bordered">
            Cancel
          </Button>
          <Button type="submit" appearance="solid">
            Submit Form
          </Button>
        </div>
      </form>
    </FormContext.Provider>
  );
};
```

### src/components/form/SectionRenderer.tsx
```tsx
import React from "react";
import { Text } from "@salt-ds/core";
import { Section } from "../../types/FormMetadata";
import { FieldRenderer } from "./FieldRenderer";

interface SectionRendererProps {
  section: Section;
  occurrenceIndex?: number;
}

export const SectionRenderer: React.FC<SectionRendererProps> = ({
  section,
  occurrenceIndex,
}) => {
  return (
    <div className="section">
      {occurrenceIndex === undefined && (
        <div className="section-header">
          <Text styleAs="h3" className="section-title">
            {section.sectionName}
          </Text>
        </div>
      )}
      {section.description && (
        <Text color="secondary" style={{ marginBottom: 16 }}>
          {section.description}
        </Text>
      )}
      <div className="fields-grid">
        {section.fields.map((field) => (
          <FieldRenderer
            key={field.fieldCode}
            field={field}
            sectionCode={section.sectionCode}
            occurrenceIndex={occurrenceIndex}
          />
        ))}
      </div>
    </div>
  );
};
```

### src/components/form/RepeatableSectionRenderer.tsx
```tsx
import React, { useState, useEffect } from "react";
import { Button, Text } from "@salt-ds/core";
import { AddIcon, DeleteIcon } from "@salt-ds/icons";
import { Section } from "../../types/FormMetadata";
import { SectionRenderer } from "./SectionRenderer";
import { useFormContext } from "../../context/FormContext";

interface RepeatableSectionRendererProps {
  section: Section;
}

export const RepeatableSectionRenderer: React.FC<RepeatableSectionRendererProps> = ({
  section,
}) => {
  const { formData } = useFormContext();
  
  // Calculate initial occurrences from existing data
  const getInitialOccurrences = (): number[] => {
    const pattern = new RegExp(`^${section.sectionCode}\\[(\\d+)\\]\\.`);
    const indices = new Set<number>();
    
    Object.keys(formData).forEach((key) => {
      const match = key.match(pattern);
      if (match) {
        indices.add(parseInt(match[1], 10));
      }
    });
    
    const maxIndex = indices.size > 0 ? Math.max(...indices) + 1 : section.minOccurrences;
    const count = Math.max(maxIndex, section.minOccurrences);
    return Array.from({ length: count }, (_, i) => i);
  };

  const [occurrences, setOccurrences] = useState<number[]>(getInitialOccurrences);
  const [nextId, setNextId] = useState(occurrences.length);

  const canAddMore =
    section.maxOccurrences === null ||
    section.maxOccurrences === undefined ||
    occurrences.length < section.maxOccurrences;
    
  const canRemove = occurrences.length > section.minOccurrences;

  const addOccurrence = () => {
    if (canAddMore) {
      setOccurrences((prev) => [...prev, nextId]);
      setNextId((prev) => prev + 1);
    }
  };

  const removeOccurrence = (indexToRemove: number) => {
    if (canRemove) {
      setOccurrences((prev) => prev.filter((_, i) => i !== indexToRemove));
    }
  };

  return (
    <div className="section">
      <div className="section-header">
        <Text styleAs="h3" className="section-title">
          {section.sectionName}
        </Text>
        {canAddMore && (
          <Button appearance="bordered" onClick={addOccurrence}>
            <AddIcon /> Add {section.sectionName}
          </Button>
        )}
      </div>
      
      {section.description && (
        <Text color="secondary" style={{ marginBottom: 16 }}>
          {section.description}
        </Text>
      )}

      {occurrences.length === 0 && (
        <Text color="secondary">
          No items added. Click "Add" to add a new entry.
        </Text>
      )}

      {occurrences.map((id, index) => (
        <div key={id} className="repeatable-section">
          <div className="occurrence-header">
            <Text styleAs="h4">#{index + 1}</Text>
            {canRemove && (
              <Button
                appearance="bordered"
                sentiment="negative"
                onClick={() => removeOccurrence(index)}
              >
                <DeleteIcon /> Remove
              </Button>
            )}
          </div>
          <SectionRenderer section={section} occurrenceIndex={index} />
        </div>
      ))}
    </div>
  );
};
```

### src/components/form/FieldRenderer.tsx
```tsx
import React from "react";
import { Field } from "../../types/FormMetadata";
import { useFormContext } from "../../context/FormContext";
import { TextField } from "../fields/TextField";
import { TextAreaField } from "../fields/TextAreaField";
import { NumberField } from "../fields/NumberField";
import { DateField } from "../fields/DateField";
import { DropdownField } from "../fields/DropdownField";
import { RadioField } from "../fields/RadioField";
import { CheckboxField } from "../fields/CheckboxField";
import { MaskedTextField } from "../fields/MaskedTextField";

// Field Type Registry
const FIELD_TYPE_REGISTRY: Record<string, React.ComponentType<any>> = {
  TEXT: TextField,
  TEXTAREA: TextAreaField,
  NUMBER: NumberField,
  EMAIL: TextField,
  PHONE: TextField,
  DATE: DateField,
  DROPDOWN: DropdownField,
  COUNTRY_SELECTOR: DropdownField,
  RADIO: RadioField,
  CHECKBOX: CheckboxField,
  SSN: MaskedTextField,
  EIN: MaskedTextField,
  TIN: MaskedTextField,
  SIGNATURE: TextField, // Replace with actual SignatureField component
};

interface FieldRendererProps {
  field: Field;
  sectionCode: string;
  occurrenceIndex?: number;
}

export const FieldRenderer: React.FC<FieldRendererProps> = ({
  field,
  sectionCode,
  occurrenceIndex,
}) => {
  const { formData, dropdowns, errors, handleFieldChange } = useFormContext();

  const FieldComponent = FIELD_TYPE_REGISTRY[field.fieldType];

  if (!FieldComponent) {
    console.warn(`Unknown field type: ${field.fieldType}`);
    return null;
  }

  const fieldKey =
    occurrenceIndex !== undefined
      ? `${sectionCode}[${occurrenceIndex}].${field.fieldCode}`
      : `${sectionCode}.${field.fieldCode}`;

  const dropdownOptions = field.dropdownConfigKey
    ? dropdowns[field.dropdownConfigKey] || []
    : undefined;

  const value = formData[fieldKey] ?? field.defaultValue ?? "";

  return (
    <div className={`col-span-${field.colSpan}`}>
      <FieldComponent
        field={field}
        value={value}
        onChange={(newValue: any) =>
          handleFieldChange(sectionCode, field.fieldCode, newValue, occurrenceIndex)
        }
        error={errors[fieldKey]}
        options={dropdownOptions}
      />
    </div>
  );
};
```

---

## 8. Field Components (Salt Design)

### src/components/fields/TextField.tsx
```tsx
import React from "react";
import { FormField, FormFieldLabel, FormFieldHelperText, Input } from "@salt-ds/core";
import { Field } from "../../types/FormMetadata";

interface TextFieldProps {
  field: Field;
  value: string;
  onChange: (value: string) => void;
  error?: string;
}

export const TextField: React.FC<TextFieldProps> = ({
  field,
  value,
  onChange,
  error,
}) => {
  return (
    <FormField necessity={field.isRequired ? "required" : "optional"}>
      <FormFieldLabel>{field.fieldLabel}</FormFieldLabel>
      <Input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={field.placeholderText}
        validationStatus={error ? "error" : undefined}
        inputProps={{ maxLength: field.maxLength }}
      />
      {field.helpText && !error && (
        <FormFieldHelperText>{field.helpText}</FormFieldHelperText>
      )}
      {error && (
        <FormFieldHelperText validationStatus="error">{error}</FormFieldHelperText>
      )}
    </FormField>
  );
};
```

### src/components/fields/TextAreaField.tsx
```tsx
import React from "react";
import { FormField, FormFieldLabel, FormFieldHelperText, MultilineInput } from "@salt-ds/core";
import { Field } from "../../types/FormMetadata";

interface TextAreaFieldProps {
  field: Field;
  value: string;
  onChange: (value: string) => void;
  error?: string;
}

export const TextAreaField: React.FC<TextAreaFieldProps> = ({
  field,
  value,
  onChange,
  error,
}) => {
  return (
    <FormField necessity={field.isRequired ? "required" : "optional"}>
      <FormFieldLabel>{field.fieldLabel}</FormFieldLabel>
      <MultilineInput
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={field.placeholderText}
        validationStatus={error ? "error" : undefined}
        rows={4}
      />
      {field.helpText && !error && (
        <FormFieldHelperText>{field.helpText}</FormFieldHelperText>
      )}
      {error && (
        <FormFieldHelperText validationStatus="error">{error}</FormFieldHelperText>
      )}
    </FormField>
  );
};
```

### src/components/fields/NumberField.tsx
```tsx
import React from "react";
import { FormField, FormFieldLabel, FormFieldHelperText, Input } from "@salt-ds/core";
import { Field } from "../../types/FormMetadata";

interface NumberFieldProps {
  field: Field;
  value: number | string;
  onChange: (value: number | null) => void;
  error?: string;
}

export const NumberField: React.FC<NumberFieldProps> = ({
  field,
  value,
  onChange,
  error,
}) => {
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value;
    if (val === "") {
      onChange(null);
    } else {
      const num = parseFloat(val);
      if (!isNaN(num)) {
        onChange(num);
      }
    }
  };

  return (
    <FormField necessity={field.isRequired ? "required" : "optional"}>
      <FormFieldLabel>{field.fieldLabel}</FormFieldLabel>
      <Input
        type="number"
        value={value?.toString() ?? ""}
        onChange={handleChange}
        placeholder={field.placeholderText}
        validationStatus={error ? "error" : undefined}
        inputProps={{
          min: field.minValue,
          max: field.maxValue,
        }}
      />
      {field.helpText && !error && (
        <FormFieldHelperText>{field.helpText}</FormFieldHelperText>
      )}
      {error && (
        <FormFieldHelperText validationStatus="error">{error}</FormFieldHelperText>
      )}
    </FormField>
  );
};
```

### src/components/fields/DropdownField.tsx
```tsx
import React from "react";
import {
  FormField,
  FormFieldLabel,
  FormFieldHelperText,
  Dropdown,
  Option,
} from "@salt-ds/core";
import { Field, DropdownOption } from "../../types/FormMetadata";

interface DropdownFieldProps {
  field: Field;
  value: string;
  onChange: (value: string) => void;
  options?: DropdownOption[];
  error?: string;
}

export const DropdownField: React.FC<DropdownFieldProps> = ({
  field,
  value,
  onChange,
  options = [],
  error,
}) => {
  return (
    <FormField necessity={field.isRequired ? "required" : "optional"}>
      <FormFieldLabel>{field.fieldLabel}</FormFieldLabel>
      <Dropdown
        selected={value ? [value] : []}
        onSelectionChange={(_, selectedItems) => {
          onChange(selectedItems[0] || "");
        }}
        placeholder={field.placeholderText || `Select ${field.fieldLabel}`}
        validationStatus={error ? "error" : undefined}
      >
        {options.map((option) => (
          <Option key={option.valueCode} value={option.valueCode}>
            {option.displayText}
          </Option>
        ))}
      </Dropdown>
      {field.helpText && !error && (
        <FormFieldHelperText>{field.helpText}</FormFieldHelperText>
      )}
      {error && (
        <FormFieldHelperText validationStatus="error">{error}</FormFieldHelperText>
      )}
    </FormField>
  );
};
```

### src/components/fields/RadioField.tsx
```tsx
import React from "react";
import {
  FormField,
  FormFieldLabel,
  FormFieldHelperText,
  RadioButton,
  RadioButtonGroup,
} from "@salt-ds/core";
import { Field, DropdownOption } from "../../types/FormMetadata";

interface RadioFieldProps {
  field: Field;
  value: string;
  onChange: (value: string) => void;
  options?: DropdownOption[];
  error?: string;
}

export const RadioField: React.FC<RadioFieldProps> = ({
  field,
  value,
  onChange,
  options = [],
  error,
}) => {
  return (
    <FormField necessity={field.isRequired ? "required" : "optional"}>
      <FormFieldLabel>{field.fieldLabel}</FormFieldLabel>
      <RadioButtonGroup
        value={value}
        onChange={(e) => onChange(e.target.value)}
        direction="horizontal"
      >
        {options.map((option) => (
          <RadioButton
            key={option.valueCode}
            label={option.displayText}
            value={option.valueCode}
          />
        ))}
      </RadioButtonGroup>
      {field.helpText && !error && (
        <FormFieldHelperText>{field.helpText}</FormFieldHelperText>
      )}
      {error && (
        <FormFieldHelperText validationStatus="error">{error}</FormFieldHelperText>
      )}
    </FormField>
  );
};
```

### src/components/fields/CheckboxField.tsx
```tsx
import React from "react";
import { FormField, FormFieldHelperText, Checkbox } from "@salt-ds/core";
import { Field } from "../../types/FormMetadata";

interface CheckboxFieldProps {
  field: Field;
  value: boolean;
  onChange: (value: boolean) => void;
  error?: string;
}

export const CheckboxField: React.FC<CheckboxFieldProps> = ({
  field,
  value,
  onChange,
  error,
}) => {
  return (
    <FormField>
      <Checkbox
        checked={value === true}
        onChange={(e) => onChange(e.target.checked)}
        label={field.fieldLabel}
      />
      {field.helpText && !error && (
        <FormFieldHelperText>{field.helpText}</FormFieldHelperText>
      )}
      {error && (
        <FormFieldHelperText validationStatus="error">{error}</FormFieldHelperText>
      )}
    </FormField>
  );
};
```

### src/components/fields/DateField.tsx
```tsx
import React from "react";
import { FormField, FormFieldLabel, FormFieldHelperText, Input } from "@salt-ds/core";
import { Field } from "../../types/FormMetadata";

// Note: For production, use @salt-ds/lab DatePicker component
interface DateFieldProps {
  field: Field;
  value: string;
  onChange: (value: string) => void;
  error?: string;
}

export const DateField: React.FC<DateFieldProps> = ({
  field,
  value,
  onChange,
  error,
}) => {
  return (
    <FormField necessity={field.isRequired ? "required" : "optional"}>
      <FormFieldLabel>{field.fieldLabel}</FormFieldLabel>
      <Input
        type="date"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        validationStatus={error ? "error" : undefined}
      />
      {field.helpText && !error && (
        <FormFieldHelperText>{field.helpText}</FormFieldHelperText>
      )}
      {error && (
        <FormFieldHelperText validationStatus="error">{error}</FormFieldHelperText>
      )}
    </FormField>
  );
};
```

### src/components/fields/MaskedTextField.tsx
```tsx
import React from "react";
import { FormField, FormFieldLabel, FormFieldHelperText, Input } from "@salt-ds/core";
import { Field } from "../../types/FormMetadata";

interface MaskedTextFieldProps {
  field: Field;
  value: string;
  onChange: (value: string) => void;
  error?: string;
}

// Formatting functions for different field types
const formatters: Record<string, (val: string) => string> = {
  SSN: (val) => {
    const digits = val.replace(/\D/g, "").substring(0, 9);
    if (digits.length <= 3) return digits;
    if (digits.length <= 5) return `${digits.slice(0, 3)}-${digits.slice(3)}`;
    return `${digits.slice(0, 3)}-${digits.slice(3, 5)}-${digits.slice(5)}`;
  },
  EIN: (val) => {
    const digits = val.replace(/\D/g, "").substring(0, 9);
    if (digits.length <= 2) return digits;
    return `${digits.slice(0, 2)}-${digits.slice(2)}`;
  },
  TIN: (val) => {
    const digits = val.replace(/\D/g, "").substring(0, 9);
    if (digits.length <= 2) return digits;
    return `${digits.slice(0, 2)}-${digits.slice(2)}`;
  },
};

export const MaskedTextField: React.FC<MaskedTextFieldProps> = ({
  field,
  value,
  onChange,
  error,
}) => {
  const formatter = formatters[field.fieldType] || ((v: string) => v);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const formatted = formatter(e.target.value);
    onChange(formatted);
  };

  return (
    <FormField necessity={field.isRequired ? "required" : "optional"}>
      <FormFieldLabel>{field.fieldLabel}</FormFieldLabel>
      <Input
        value={value}
        onChange={handleChange}
        placeholder={field.placeholderText}
        validationStatus={error ? "error" : undefined}
      />
      {field.helpText && !error && (
        <FormFieldHelperText>{field.helpText}</FormFieldHelperText>
      )}
      {error && (
        <FormFieldHelperText validationStatus="error">{error}</FormFieldHelperText>
      )}
    </FormField>
  );
};
```

---

## 9. Page Components

### src/pages/FormListPage.tsx
```tsx
import React, { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Button, Card, Text, StackLayout } from "@salt-ds/core";
import { FormTemplate } from "../types/FormMetadata";
import { metadataService } from "../services/metadataService";

export const FormListPage: React.FC = () => {
  const [forms, setForms] = useState<FormTemplate[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    metadataService.getAllForms().then((data) => {
      setForms(data);
      setLoading(false);
    });
  }, []);

  if (loading) {
    return <Text>Loading forms...</Text>;
  }

  return (
    <div>
      <Text styleAs="h1" style={{ marginBottom: 24 }}>
        Tax Forms
      </Text>
      <StackLayout gap={2}>
        {forms.map((form) => (
          <Card key={form.formCode} style={{ padding: 16 }}>
            <Text styleAs="h3">{form.formCode}</Text>
            <Text>{form.formName}</Text>
            <div style={{ marginTop: 12 }}>
              <Link to={`/forms/${form.formCode}/new`}>
                <Button appearance="solid">Start New Form</Button>
              </Link>
            </div>
          </Card>
        ))}
      </StackLayout>
    </div>
  );
};
```

### src/pages/FormNewPage.tsx
```tsx
import React from "react";
import { useParams, useNavigate } from "react-router-dom";
import { FormRenderer } from "../components/form/FormRenderer";
import { externalDataService } from "../services/externalDataService";
import { FormData } from "../types/FormData";

export const FormNewPage: React.FC = () => {
  const { formCode } = useParams<{ formCode: string }>();
  const navigate = useNavigate();

  const handleSubmit = async (data: FormData) => {
    try {
      await externalDataService.createSubmission({
        formCode: formCode!,
        data,
      });
      alert("Form submitted successfully!");
      navigate("/");
    } catch (error) {
      alert("Failed to submit form. Please try again.");
    }
  };

  if (!formCode) {
    return <div>Invalid form code</div>;
  }

  return <FormRenderer formCode={formCode} onSubmit={handleSubmit} />;
};
```

### src/pages/FormEditPage.tsx
```tsx
import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Text } from "@salt-ds/core";
import { FormRenderer } from "../components/form/FormRenderer";
import { externalDataService } from "../services/externalDataService";
import { FormData } from "../types/FormData";

export const FormEditPage: React.FC = () => {
  const { formCode, submissionId } = useParams<{
    formCode: string;
    submissionId: string;
  }>();
  const navigate = useNavigate();
  const [initialData, setInitialData] = useState<FormData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (submissionId) {
      externalDataService
        .getSubmission(submissionId)
        .then((submission) => {
          setInitialData(submission.data);
          setLoading(false);
        })
        .catch(() => {
          setLoading(false);
        });
    }
  }, [submissionId]);

  const handleSubmit = async (data: FormData) => {
    try {
      await externalDataService.updateSubmission(submissionId!, {
        formCode: formCode!,
        submissionId: submissionId!,
        data,
      });
      alert("Form updated successfully!");
      navigate("/");
    } catch (error) {
      alert("Failed to update form. Please try again.");
    }
  };

  if (!formCode || !submissionId) {
    return <div>Invalid parameters</div>;
  }

  if (loading) {
    return <Text>Loading form data...</Text>;
  }

  return (
    <FormRenderer
      formCode={formCode}
      initialData={initialData || {}}
      onSubmit={handleSubmit}
    />
  );
};
```

---

## 10. Environment Configuration

### .env
```env
VITE_API_URL=http://localhost:8080/api
VITE_EXTERNAL_API_URL=http://localhost:8081/api
```

### .env.production
```env
VITE_API_URL=https://your-api-domain.com/api
VITE_EXTERNAL_API_URL=https://your-external-service.com/api
```
