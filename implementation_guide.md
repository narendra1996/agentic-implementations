# Implementation Guide: Normalizer & Metadata UI

Based on our brainstorming, here is the concrete implementation guide for the `CompanyNameNormalizer` and the Metadata-Driven UI to ensure the Tax Form Mapper is robust and future-proof.

## 1. The `CompanyNameNormalizer` Utility (Java)
Instead of importing a heavy Entity Resolution library, this lightweight singleton service will cleanly standardize company names before they are scored by `java-string-similarity` or `fuzzy-matcher`.

### Core Logic Structure
```java
import org.springframework.stereotype.Service;
import javax.annotation.PostConstruct;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;

@Service
public class CompanyNameNormalizer {

    private final Map<String, String> suffixDictionary = new HashMap<>();
    
    // Pattern to aggressively strip all non-alphanumeric characters (keeps spaces)
    private static final Pattern CLEAN_PATTERN = Pattern.compile("[^a-zA-Z0-9 ]");

    @PostConstruct
    public void init() {
        // In a real app, load this from the database or a configuration file
        // so business users can add new abbreviations without a code release.
        suffixDictionary.put("LIMITED LIABILITY CORPORATION", "LLC");
        suffixDictionary.put("LIMITED LIABILITY CO", "LLC");
        suffixDictionary.put("INCORPORATED", "INC");
        suffixDictionary.put("COMPANY", "CO");
        suffixDictionary.put("CORPORATION", "CORP");
        suffixDictionary.put("LIMITED", "LTD");
    }

    /**
     * Normalizes a raw company name string for fuzzy matching.
     * Example input: "Narendra  Limited Liability Corporation."
     * Example output: "NARENDRA LLC"
     */
    public String normalize(String rawName) {
        if (rawName == null || rawName.trim().isEmpty()) {
            return "";
        }

        // 1. Basic cleaning: Upper case and remove punctuation
        String cleaned = CLEAN_PATTERN.matcher(rawName.toUpperCase()).replaceAll("");

        // 2. Extra spaces removal (collapses multiple spaces into one)
        cleaned = cleaned.replaceAll("\\s+", " ").trim();

        // 3. Dictionary Replacement (Tokenization approach for safety)
        // We replace suffixes, ensuring we don't accidentally replace text inside a word.
        // E.g., we replace " CORPORATION " but not "INCORPORATION"
        for (Map.Entry<String, String> entry : suffixDictionary.entrySet()) {
            // Use word boundary regex (\b) to ensure exact word matches
            String regex = "\\b" + entry.getKey() + "\\b";
            cleaned = cleaned.replaceAll(regex, entry.getValue());
        }

        return cleaned.trim();
    }
}
```

**How the Matching Engine uses this:**
```java
String normalizedEntityA = normalizer.normalize("Narendra LLC");
String normalizedEntityB = normalizer.normalize("Narendra Limited Liability Corporation"); 

// Both strings are now exactly "NARENDRA LLC".
// The algorithm (Cosine or Jaro-Winkler) will yield a 100% (1.0) match score.
double score = stringSimilarityEngine.calculate(normalizedEntityA, normalizedEntityB);
```

---

## 2. Metadata-Driven UI Architecture
To allow the system to scale to *any* tax form (W8, IMY) and *any* attribute (Foreign Tax ID) without pushing React code changes, both the frontend and backend must rely on a metadata schema.

### Backend: Metadata Endpoint (`GET /api/v1/metadata/forms`)
This endpoint dictates to the React UI exactly what forms exist, what attributes they contain, and what algorithms are permitted for those attributes.

```json
[
  {
    "formId": "W9",
    "formName": "W-9 (US Person)",
    "attributes": [
      {
        "id": "legalName",
        "label": "Full Legal Name",
        "dataType": "STRING",
        "isPII": false,
        "allowedAlgorithms": ["COSINE", "JARO_WINKLER", "EXACT"]
      },
      {
        "id": "ssnOrEin",
        "label": "SSN or EIN",
        "dataType": "STRING",
        "isPII": true,
        "allowedAlgorithms": ["EXACT", "LEVENSHTEIN"]
      }
    ]
  },
  {
    "formId": "W8_BENE",
    "formName": "W-8BEN-E (Foreign Entity)",
    "attributes": [
        // ... different attributes specific to W8-BENE
    ]
  }
]
```

### React Frontend: Dynamic Rule Builder behavior
1.  **Form Selection:** The UI renders a Dropdown using `formName`.
2.  **Attribute Rows:** When the user clicks "Add Match Condition", the UI renders a dropdown populated by the `attributes` array for the selected `formId`.
3.  **Algorithm Selection:** If the user selects "Full Legal Name", the Algorithm dropdown strictly limits their choices to `COSINE, JARO_WINKLER, EXACT`.

### Backend Parsing: Dynamic Extraction (`Map<String, String>`)
Because the attributes are dynamic, your Java JPA Entity for the Tax Form payload cannot have hardcoded fields (like `private String formName;`).
Instead, store the target data as a `JSONB` column or pass it through the engine as a `Map`.

```java
// Inside the MatchingEngine Service
public double calculateMatch(Map<String, String> managerData, Map<String, String> clientData, Rule rule) {
    double totalScore = 0.0;
    
    for (RuleAttribute attr : rule.getAttributes()) {
        // DYNAMIC EXTRACTION: Uses the dictionary 'id' (e.g., "legalName")
        String rawManagerVal = managerData.get(attr.getAttributeId());
        String rawClientVal = clientData.get(attr.getAttributeId());
        
        // 1. Normalize
        String normalizedManager = normalizer.normalize(rawManagerVal);
        String normalizedClient = normalizer.normalize(rawClientVal);
        
        // 2. Score via selected algorithm
        double score = stringSimilarityEngine.calculateScore(
            normalizedManager, 
            normalizedClient, 
            attr.getAlgorithm()
        );
        
        // 3. Weight
        totalScore += (score * (attr.getWeight() / 100.0));
    }
    return totalScore;
}
```

By removing the "Blocking" strategy for now, you simplify the initial database queries significantly. You can always add JDBC pagination if the $10,000 \times 20,000$ (200 Million) comparison matrix starts to take longer than a few hours to run on the production server.
