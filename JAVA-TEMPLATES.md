# Java Implementation Templates

> **FOR AI AGENT**: Use these templates as the basis for implementation. Follow patterns exactly.

---

## 1. Entity Classes

### FormTemplate.java
```java
package com.taxforms.model.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "FORM_TEMPLATES")
@Data
public class FormTemplate {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "FORM_ID")
    private Long formId;
    
    @Column(name = "FORM_CODE", nullable = false, unique = true)
    private String formCode;
    
    @Column(name = "FORM_NAME", nullable = false)
    private String formName;
    
    @Column(name = "FORM_DESCRIPTION")
    private String formDescription;
    
    @Column(name = "FORM_VERSION")
    private Double formVersion;
    
    @Column(name = "STATUS")
    private String status;
    
    @Column(name = "CREATED_AT")
    private LocalDateTime createdAt;
    
    @Column(name = "UPDATED_AT")
    private LocalDateTime updatedAt;
    
    @Column(name = "CREATED_BY")
    private String createdBy;
}
```

### FormSection.java
```java
package com.taxforms.model.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "FORM_SECTIONS")
@Data
public class FormSection {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "SECTION_ID")
    private Long sectionId;
    
    @Column(name = "FORM_ID", nullable = false)
    private Long formId;
    
    @Column(name = "SECTION_CODE", nullable = false)
    private String sectionCode;
    
    @Column(name = "SECTION_NAME", nullable = false)
    private String sectionName;
    
    @Column(name = "DISPLAY_ORDER", nullable = false)
    private Integer displayOrder;
    
    @Column(name = "MIN_OCCURRENCES")
    private Integer minOccurrences;
    
    @Column(name = "MAX_OCCURRENCES")
    private Integer maxOccurrences;
    
    @Column(name = "IS_REPEATABLE")
    private String isRepeatable;
    
    @Column(name = "SECTION_DESCRIPTION")
    private String sectionDescription;
    
    @Column(name = "STATUS")
    private String status;
}
```

### FormField.java
```java
package com.taxforms.model.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "FORM_FIELDS")
@Data
public class FormField {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "FIELD_ID")
    private Long fieldId;
    
    @Column(name = "SECTION_ID", nullable = false)
    private Long sectionId;
    
    @Column(name = "FIELD_CODE", nullable = false)
    private String fieldCode;
    
    @Column(name = "FIELD_LABEL", nullable = false)
    private String fieldLabel;
    
    @Column(name = "FIELD_TYPE", nullable = false)
    private String fieldType;
    
    @Column(name = "DISPLAY_ORDER", nullable = false)
    private Integer displayOrder;
    
    @Column(name = "IS_REQUIRED")
    private String isRequired;
    
    @Column(name = "DEFAULT_VALUE")
    private String defaultValue;
    
    @Column(name = "VALIDATION_REGEX")
    private String validationRegex;
    
    @Column(name = "MAX_LENGTH")
    private Integer maxLength;
    
    @Column(name = "MIN_VALUE")
    private Double minValue;
    
    @Column(name = "MAX_VALUE")
    private Double maxValue;
    
    @Column(name = "DROPDOWN_CONFIG_KEY")
    private String dropdownConfigKey;
    
    @Column(name = "PLACEHOLDER_TEXT")
    private String placeholderText;
    
    @Column(name = "HELP_TEXT")
    private String helpText;
    
    @Column(name = "COL_SPAN")
    private Integer colSpan;
    
    @Column(name = "STATUS")
    private String status;
}
```

### DropdownValue.java
```java
package com.taxforms.model.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "DROPDOWN_VALUES")
@Data
public class DropdownValue {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "VALUE_ID")
    private Long valueId;
    
    @Column(name = "CONFIG_KEY", nullable = false)
    private String configKey;
    
    @Column(name = "VALUE_CODE", nullable = false)
    private String valueCode;
    
    @Column(name = "DISPLAY_TEXT", nullable = false)
    private String displayText;
    
    @Column(name = "DISPLAY_ORDER", nullable = false)
    private Integer displayOrder;
    
    @Column(name = "IS_ACTIVE")
    private String isActive;
    
    @Column(name = "PARENT_VALUE_CODE")
    private String parentValueCode;
}
```

---

## 2. Repository Interfaces

### FormTemplateRepository.java
```java
package com.taxforms.repository;

import com.taxforms.model.entity.FormTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface FormTemplateRepository extends JpaRepository<FormTemplate, Long> {
    
    Optional<FormTemplate> findByFormCode(String formCode);
    
    List<FormTemplate> findByStatus(String status);
}
```

### FormSectionRepository.java
```java
package com.taxforms.repository;

import com.taxforms.model.entity.FormSection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface FormSectionRepository extends JpaRepository<FormSection, Long> {
    
    List<FormSection> findByFormIdOrderByDisplayOrder(Long formId);
}
```

### FormFieldRepository.java
```java
package com.taxforms.repository;

import com.taxforms.model.entity.FormField;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface FormFieldRepository extends JpaRepository<FormField, Long> {
    
    List<FormField> findBySectionIdOrderByDisplayOrder(Long sectionId);
}
```

### DropdownRepository.java
```java
package com.taxforms.repository;

import com.taxforms.model.entity.DropdownValue;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface DropdownRepository extends JpaRepository<DropdownValue, Long> {
    
    List<DropdownValue> findByConfigKeyAndIsActiveOrderByDisplayOrder(String configKey, String isActive);
    
    List<DropdownValue> findByConfigKeyInAndIsActiveOrderByDisplayOrder(List<String> configKeys, String isActive);
}
```

---

## 3. DTO Classes

### FormMetadataDTO.java
```java
package com.taxforms.model.dto;

import lombok.Builder;
import lombok.Data;
import java.util.List;
import java.util.Map;

@Data
@Builder
public class FormMetadataDTO {
    private String formCode;
    private String formName;
    private String formDescription;
    private Double version;
    private List<SectionDTO> sections;
    private Map<String, List<DropdownValueDTO>> dropdowns;
}
```

### SectionDTO.java
```java
package com.taxforms.model.dto;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
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

### FieldDTO.java
```java
package com.taxforms.model.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class FieldDTO {
    private String fieldCode;
    private String fieldLabel;
    private String fieldType;
    private Integer displayOrder;
    private boolean isRequired;
    private String defaultValue;
    private String validationRegex;
    private Integer maxLength;
    private Double minValue;
    private Double maxValue;
    private String dropdownConfigKey;
    private String placeholderText;
    private String helpText;
    private Integer colSpan;
}
```

### DropdownValueDTO.java
```java
package com.taxforms.model.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class DropdownValueDTO {
    private String valueCode;
    private String displayText;
    private Integer displayOrder;
}
```

---

## 4. Service Classes

### MetadataService.java
```java
package com.taxforms.service;

import com.taxforms.model.dto.*;
import com.taxforms.model.entity.*;
import com.taxforms.repository.*;
import com.taxforms.exception.FormNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheConfig;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@CacheConfig(cacheNames = "formMetadata")
public class MetadataService {

    private final FormTemplateRepository formTemplateRepository;
    private final FormSectionRepository sectionRepository;
    private final FormFieldRepository fieldRepository;
    private final DropdownService dropdownService;

    @Cacheable(key = "#formCode")
    public FormMetadataDTO getFormMetadata(String formCode) {
        FormTemplate template = formTemplateRepository.findByFormCode(formCode)
            .orElseThrow(() -> new FormNotFoundException("Form not found: " + formCode));
        
        List<FormSection> sections = sectionRepository
            .findByFormIdOrderByDisplayOrder(template.getFormId());
        
        List<SectionDTO> sectionDTOs = sections.stream()
            .map(this::mapSectionWithFields)
            .collect(Collectors.toList());
        
        // Pre-fetch all dropdown values needed
        Set<String> dropdownKeys = extractDropdownKeys(sectionDTOs);
        Map<String, List<DropdownValueDTO>> dropdowns = 
            dropdownService.getDropdownsBatch(dropdownKeys);
        
        return FormMetadataDTO.builder()
            .formCode(template.getFormCode())
            .formName(template.getFormName())
            .formDescription(template.getFormDescription())
            .version(template.getFormVersion())
            .sections(sectionDTOs)
            .dropdowns(dropdowns)
            .build();
    }

    public List<FormTemplateDTO> getAllForms() {
        return formTemplateRepository.findByStatus("ACTIVE").stream()
            .map(t -> FormTemplateDTO.builder()
                .formCode(t.getFormCode())
                .formName(t.getFormName())
                .build())
            .collect(Collectors.toList());
    }

    private SectionDTO mapSectionWithFields(FormSection section) {
        List<FormField> fields = fieldRepository
            .findBySectionIdOrderByDisplayOrder(section.getSectionId());
        
        return SectionDTO.builder()
            .sectionCode(section.getSectionCode())
            .sectionName(section.getSectionName())
            .description(section.getSectionDescription())
            .displayOrder(section.getDisplayOrder())
            .isRepeatable("Y".equals(section.getIsRepeatable()))
            .minOccurrences(section.getMinOccurrences())
            .maxOccurrences(section.getMaxOccurrences())
            .fields(fields.stream()
                .map(this::mapField)
                .collect(Collectors.toList()))
            .build();
    }

    private FieldDTO mapField(FormField field) {
        return FieldDTO.builder()
            .fieldCode(field.getFieldCode())
            .fieldLabel(field.getFieldLabel())
            .fieldType(field.getFieldType())
            .displayOrder(field.getDisplayOrder())
            .isRequired("Y".equals(field.getIsRequired()))
            .defaultValue(field.getDefaultValue())
            .validationRegex(field.getValidationRegex())
            .maxLength(field.getMaxLength())
            .minValue(field.getMinValue())
            .maxValue(field.getMaxValue())
            .dropdownConfigKey(field.getDropdownConfigKey())
            .placeholderText(field.getPlaceholderText())
            .helpText(field.getHelpText())
            .colSpan(field.getColSpan())
            .build();
    }

    private Set<String> extractDropdownKeys(List<SectionDTO> sections) {
        return sections.stream()
            .flatMap(s -> s.getFields().stream())
            .map(FieldDTO::getDropdownConfigKey)
            .filter(Objects::nonNull)
            .collect(Collectors.toSet());
    }
}
```

### DropdownService.java
```java
package com.taxforms.service;

import com.taxforms.model.dto.DropdownValueDTO;
import com.taxforms.model.entity.DropdownValue;
import com.taxforms.repository.DropdownRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DropdownService {

    private final DropdownRepository dropdownRepository;

    @Cacheable(value = "dropdowns", key = "#configKey")
    public List<DropdownValueDTO> getDropdownValues(String configKey) {
        return dropdownRepository
            .findByConfigKeyAndIsActiveOrderByDisplayOrder(configKey, "Y")
            .stream()
            .map(this::mapToDTO)
            .collect(Collectors.toList());
    }

    public Map<String, List<DropdownValueDTO>> getDropdownsBatch(Set<String> configKeys) {
        if (configKeys.isEmpty()) {
            return Collections.emptyMap();
        }
        
        List<DropdownValue> values = dropdownRepository
            .findByConfigKeyInAndIsActiveOrderByDisplayOrder(new ArrayList<>(configKeys), "Y");
        
        return values.stream()
            .collect(Collectors.groupingBy(
                DropdownValue::getConfigKey,
                Collectors.mapping(this::mapToDTO, Collectors.toList())
            ));
    }

    private DropdownValueDTO mapToDTO(DropdownValue value) {
        return DropdownValueDTO.builder()
            .valueCode(value.getValueCode())
            .displayText(value.getDisplayText())
            .displayOrder(value.getDisplayOrder())
            .build();
    }
}
```

---

## 5. Controller Classes

### FormController.java
```java
package com.taxforms.controller;

import com.taxforms.model.dto.FormMetadataDTO;
import com.taxforms.model.dto.FormTemplateDTO;
import com.taxforms.service.MetadataService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/forms")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class FormController {

    private final MetadataService metadataService;

    @GetMapping
    public ResponseEntity<List<FormTemplateDTO>> getAllForms() {
        return ResponseEntity.ok(metadataService.getAllForms());
    }

    @GetMapping("/{formCode}")
    public ResponseEntity<FormMetadataDTO> getFormMetadata(@PathVariable String formCode) {
        return ResponseEntity.ok(metadataService.getFormMetadata(formCode));
    }
}
```

### DropdownController.java
```java
package com.taxforms.controller;

import com.taxforms.model.dto.DropdownValueDTO;
import com.taxforms.service.DropdownService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/dropdowns")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class DropdownController {

    private final DropdownService dropdownService;

    @GetMapping("/{configKey}")
    public ResponseEntity<List<DropdownValueDTO>> getDropdownValues(@PathVariable String configKey) {
        return ResponseEntity.ok(dropdownService.getDropdownValues(configKey));
    }

    @GetMapping("/batch")
    public ResponseEntity<Map<String, List<DropdownValueDTO>>> getDropdownsBatch(
            @RequestParam("keys") List<String> keys) {
        return ResponseEntity.ok(dropdownService.getDropdownsBatch(new HashSet<>(keys)));
    }
}
```

---

## 6. Form Data POJO Classes

### BaseFormData.java
```java
package com.taxforms.model.formdata;

import lombok.Data;

@Data
public abstract class BaseFormData {
    private String formCode;
    private String submissionId;
}
```

### W9FormData.java
```java
package com.taxforms.model.formdata;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.time.LocalDate;

@Data
@EqualsAndHashCode(callSuper = true)
public class W9FormData extends BaseFormData {
    
    // Basic Info Section
    @JsonProperty("BASIC_INFO.NAME")
    private String name;
    
    @JsonProperty("BASIC_INFO.BUSINESS_NAME")
    private String businessName;
    
    @JsonProperty("BASIC_INFO.FEDERAL_TAX_CLASSIFICATION")
    private String federalTaxClassification;
    
    @JsonProperty("BASIC_INFO.LLC_CLASSIFICATION")
    private String llcClassification;
    
    // Address Section
    @JsonProperty("ADDRESS.STREET_ADDRESS")
    private String streetAddress;
    
    @JsonProperty("ADDRESS.CITY")
    private String city;
    
    @JsonProperty("ADDRESS.STATE")
    private String state;
    
    @JsonProperty("ADDRESS.ZIP_CODE")
    private String zipCode;
    
    // Taxpayer ID Section
    @JsonProperty("TAXPAYER_ID.TIN_TYPE")
    private String tinType;
    
    @JsonProperty("TAXPAYER_ID.SSN")
    private String ssn;
    
    @JsonProperty("TAXPAYER_ID.EIN")
    private String ein;
    
    // Certification Section
    @JsonProperty("CERTIFICATION.CERTIFICATION_AGREE")
    private Boolean certificationAgree;
    
    @JsonProperty("CERTIFICATION.SIGNATURE")
    private String signature;
    
    @JsonProperty("CERTIFICATION.SIGNATURE_DATE")
    private LocalDate signatureDate;
}
```

### TreatyClaim.java
```java
package com.taxforms.model.formdata;

import lombok.Data;

@Data
public class TreatyClaim {
    private String treatyCountry;
    private String incomeType;
    private String treatyArticle;
    private Integer withholdingRate;
    private String treatyJustification;
    
    public void setField(String fieldName, Object value) {
        switch (fieldName) {
            case "TREATY_COUNTRY" -> this.treatyCountry = (String) value;
            case "INCOME_TYPE" -> this.incomeType = (String) value;
            case "TREATY_ARTICLE" -> this.treatyArticle = (String) value;
            case "WITHHOLDING_RATE" -> this.withholdingRate = value != null ? ((Number) value).intValue() : null;
            case "TREATY_JUSTIFICATION" -> this.treatyJustification = (String) value;
        }
    }
}
```

### W8BenEFormData.java
```java
package com.taxforms.model.formdata;

import com.fasterxml.jackson.annotation.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.time.LocalDate;
import java.util.*;
import java.util.regex.*;

@Data
@EqualsAndHashCode(callSuper = true)
public class W8BenEFormData extends BaseFormData {
    
    // Beneficial Owner Section
    @JsonProperty("BENEFICIAL_OWNER.ORG_NAME")
    private String orgName;
    
    @JsonProperty("BENEFICIAL_OWNER.COUNTRY_OF_INCORPORATION")
    private String countryOfIncorporation;
    
    @JsonProperty("BENEFICIAL_OWNER.CHAPTER3_STATUS")
    private String chapter3Status;
    
    @JsonProperty("BENEFICIAL_OWNER.CHAPTER4_STATUS")
    private String chapter4Status;
    
    // Permanent Address Section
    @JsonProperty("PERMANENT_ADDRESS.STREET_ADDRESS")
    private String permanentStreetAddress;
    
    @JsonProperty("PERMANENT_ADDRESS.CITY")
    private String permanentCity;
    
    @JsonProperty("PERMANENT_ADDRESS.STATE_PROVINCE")
    private String permanentStateProvince;
    
    @JsonProperty("PERMANENT_ADDRESS.COUNTRY")
    private String permanentCountry;
    
    // Repeatable Treaty Claims
    private List<TreatyClaim> treatyClaims = new ArrayList<>();
    
    // Certification Section
    @JsonProperty("CERTIFICATION.CERTIFICATION_AGREE")
    private Boolean certificationAgree;
    
    @JsonProperty("CERTIFICATION.SIGNATURE")
    private String signature;
    
    @JsonProperty("CERTIFICATION.SIGNER_NAME")
    private String signerName;
    
    @JsonProperty("CERTIFICATION.SIGNATURE_DATE")
    private LocalDate signatureDate;
    
    // Pattern for repeatable sections: TREATY_CLAIMS[0].TREATY_COUNTRY
    private static final Pattern REPEATABLE_PATTERN = Pattern.compile("TREATY_CLAIMS\\[(\\d+)\\]\\.(.+)");
    
    @JsonAnySetter
    public void setAdditionalProperty(String key, Object value) {
        Matcher matcher = REPEATABLE_PATTERN.matcher(key);
        if (matcher.matches()) {
            int index = Integer.parseInt(matcher.group(1));
            String fieldName = matcher.group(2);
            
            while (treatyClaims.size() <= index) {
                treatyClaims.add(new TreatyClaim());
            }
            
            treatyClaims.get(index).setField(fieldName, value);
        }
    }
    
    @JsonAnyGetter
    public Map<String, Object> getTreatyClaimsAsMap() {
        Map<String, Object> result = new HashMap<>();
        for (int i = 0; i < treatyClaims.size(); i++) {
            TreatyClaim claim = treatyClaims.get(i);
            String prefix = "TREATY_CLAIMS[" + i + "].";
            result.put(prefix + "TREATY_COUNTRY", claim.getTreatyCountry());
            result.put(prefix + "INCOME_TYPE", claim.getIncomeType());
            result.put(prefix + "TREATY_ARTICLE", claim.getTreatyArticle());
            result.put(prefix + "WITHHOLDING_RATE", claim.getWithholdingRate());
            result.put(prefix + "TREATY_JUSTIFICATION", claim.getTreatyJustification());
        }
        return result;
    }
}
```

### FormDataBindingService.java
```java
package com.taxforms.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.taxforms.model.formdata.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class FormDataBindingService {

    private final ObjectMapper objectMapper;

    private static final Map<String, Class<? extends BaseFormData>> FORM_POJO_MAP = Map.of(
        "W9", W9FormData.class,
        "W8-BEN-E", W8BenEFormData.class
        // Add other form mappings here
    );

    @SuppressWarnings("unchecked")
    public <T extends BaseFormData> T bindFormData(String formCode, Map<String, Object> flatData) {
        Class<? extends BaseFormData> pojoClass = FORM_POJO_MAP.get(formCode);
        if (pojoClass == null) {
            throw new IllegalArgumentException("Unsupported form code: " + formCode);
        }
        T result = (T) objectMapper.convertValue(flatData, pojoClass);
        result.setFormCode(formCode);
        return result;
    }

    public Map<String, Object> flattenFormData(BaseFormData formData) {
        return objectMapper.convertValue(formData, new TypeReference<>() {});
    }
}
```

---

## 7. Configuration Classes

### CacheConfig.java
```java
package com.taxforms.config;

import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.concurrent.ConcurrentMapCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        return new ConcurrentMapCacheManager("formMetadata", "dropdowns");
    }
}
```

### CorsConfig.java
```java
package com.taxforms.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import java.util.List;

@Configuration
public class CorsConfig {

    @Bean
    public CorsFilter corsFilter() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(List.of("http://localhost:5173", "http://localhost:3000"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", config);
        return new CorsFilter(source);
    }
}
```

---

## 8. Exception Handling

### FormNotFoundException.java
```java
package com.taxforms.exception;

public class FormNotFoundException extends RuntimeException {
    public FormNotFoundException(String message) {
        super(message);
    }
}
```

### GlobalExceptionHandler.java
```java
package com.taxforms.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(FormNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleFormNotFound(FormNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
            "error", "Form Not Found",
            "message", ex.getMessage(),
            "timestamp", LocalDateTime.now()
        ));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGenericException(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
            "error", "Internal Server Error",
            "message", ex.getMessage(),
            "timestamp", LocalDateTime.now()
        ));
    }
}
```

---

## 9. Application Properties

### application.yml
```yaml
spring:
  application:
    name: tax-forms-api
  
  datasource:
    url: jdbc:oracle:thin:@${DB_HOST:localhost}:${DB_PORT:1521}:${DB_SID:ORCL}
    username: ${DB_USERNAME:taxforms}
    password: ${DB_PASSWORD:password}
    driver-class-name: oracle.jdbc.OracleDriver
  
  jpa:
    hibernate:
      ddl-auto: none
    show-sql: false
    properties:
      hibernate:
        format_sql: true
        dialect: org.hibernate.dialect.OracleDialect

server:
  port: 8080

logging:
  level:
    com.taxforms: DEBUG
```

---

## 10. pom.xml Dependencies

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-cache</artifactId>
    </dependency>
    <dependency>
        <groupId>com.oracle.database.jdbc</groupId>
        <artifactId>ojdbc11</artifactId>
        <version>23.3.0.23.09</version>
    </dependency>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>com.fasterxml.jackson.datatype</groupId>
        <artifactId>jackson-datatype-jsr310</artifactId>
    </dependency>
</dependencies>
```
