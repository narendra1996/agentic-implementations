-- =========================================================================
-- Tax Form Mapper - Database Schema
-- =========================================================================

-- 1. Matching Configuration Rules
-- Stores the user-defined rules, weights, and algorithms
CREATE TABLE matching_rules (
    rule_id BIGSERIAL PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL,
    form_type VARCHAR(50) NOT NULL, -- e.g., 'W9', 'W8_BENE'
    confidence_threshold DECIMAL(5,2) NOT NULL, -- e.g., 85.00
    is_active BOOLEAN DEFAULT TRUE,
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Rule Attributes
-- Stores the specific attributes (Name, SSN) and their weights for a given rule
CREATE TABLE rule_attributes (
    attribute_id BIGSERIAL PRIMARY KEY,
    rule_id BIGINT REFERENCES matching_rules(rule_id),
    attribute_name VARCHAR(50) NOT NULL, -- 'NAME', 'SSN', 'ADDRESS'
    algorithm VARCHAR(50) NOT NULL, -- 'EXACT', 'JARO_WINKLER', 'COSINE'
    weight_percentage INTEGER NOT NULL, -- e.g., 60
    CONSTRAINT chk_weight CHECK (weight_percentage > 0 AND weight_percentage <= 100)
);

-- 3. Scan Job Tracking
-- Tracks the asynchronous matching jobs triggered by users
CREATE TABLE scan_jobs (
    job_id BIGSERIAL PRIMARY KEY,
    rule_id BIGINT REFERENCES matching_rules(rule_id),
    status VARCHAR(20) NOT NULL, -- 'PENDING', 'RUNNING', 'COMPLETED', 'FAILED'
    total_records_scanned INTEGER DEFAULT 0,
    matches_found INTEGER DEFAULT 0,
    started_at TIMESTAMP,
    completed_at TIMESTAMP
);

-- 4. Suggested Matches (Pending Review)
-- The output of the scan job, waiting for Maker-Checker approval
CREATE TABLE match_suggestions (
    suggestion_id BIGSERIAL PRIMARY KEY,
    job_id BIGINT REFERENCES scan_jobs(job_id),
    entity_a_id VARCHAR(100) NOT NULL, -- Could be Manager ID or Client ID
    entity_a_type VARCHAR(20) NOT NULL, -- 'MANAGER', 'CLIENT'
    entity_b_id VARCHAR(100) NOT NULL,
    entity_b_type VARCHAR(20) NOT NULL,
    confidence_score DECIMAL(5,2) NOT NULL,
    match_details JSONB, -- Stores the breakdown of which attributes matched
    status VARCHAR(20) DEFAULT 'PENDING', -- 'PENDING', 'APPROVED', 'REJECTED'
    reviewed_by VARCHAR(100),
    reviewed_at TIMESTAMP
);

-- 5. Approved Mappings
-- Source of truth for shared tax forms
CREATE TABLE tax_form_mappings (
    mapping_id BIGSERIAL PRIMARY KEY,
    source_entity_id VARCHAR(100) NOT NULL,
    source_entity_type VARCHAR(20) NOT NULL,
    target_entity_id VARCHAR(100) NOT NULL,
    target_entity_type VARCHAR(20) NOT NULL,
    form_type VARCHAR(50) NOT NULL,
    approved_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(source_entity_id, target_entity_id, form_type)
);
