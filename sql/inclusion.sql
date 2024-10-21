WITH desc_con AS ( -- All descendants of the 320128 Essential Hypertension SNOMED
    SELECT c.descendant_concept_id
    FROM omop.concept_ancestor c
    WHERE c.ancestor_concept_id = 320128 -- base query
),
p_info AS ( -- Get patients info
    SELECT p.person_id, p.year_of_birth
    FROM omop.person p
),
opd_visit AS (
    SELECT  v.person_id,
            v.visit_start_date
    FROM [omop].[visit_occurrence] v
    WHERE v.visit_start_date BETWEEN '2013-06-01' AND '2023-09-30'
   AND v.visit_concept_id = 9202
),
diag_info AS ( -- get the first diagnosis of HT for each patients
    SELECT  co.person_id,
            co.condition_concept_id,
            MIN(co.condition_start_datetime) AS first_diag,
            ROW_NUMBER() OVER(PARTITION BY co.person_id ORDER BY co.condition_start_datetime) as rn
    FROM omop.condition_occurrence co
    JOIN desc_con d ON co.condition_concept_id = d.descendant_concept_id
    INNER JOIN opd_visit v ON co.person_id = v.person_id AND co.condition_start_datetime BETWEEN v.visit_start_date AND DATEADD(DAY, 1, v.visit_start_date)
    WHERE co.condition_start_datetime BETWEEN '2013-06-01' AND '2023-12-31'
    GROUP BY co.person_id, co.condition_concept_id, co.condition_start_datetime
),
diag_criteria AS (
    SELECT *
    FROM diag_info
    WHERE rn = 1
),
drug_order AS ( -- Get the first antihypertensive drug start date for each patients
    SELECT  d.person_id,
            d.drug_source_value,
            MIN(d.drug_exposure_start_date) as first_drug_start_date,
            ROW_NUMBER() OVER(PARTITION BY d.person_id ORDER BY d.drug_exposure_start_date) as rn
    FROM [omop].[drug_exposure] d
    WHERE d.drug_source_value IN INSERT_DRUG_TUPLE -- This can be switched to standard hypertension drug_concept_id
    AND d.drug_exposure_start_date BETWEEN '2013-06-01' AND '2023-12-31'
    GROUP BY d.person_id, d.drug_exposure_start_date, d.drug_source_value
),
drug_criteria AS (
    SELECT *
    FROM drug_order
    WHERE rn = 1
),
inclusion AS (
SELECT COALESCE(d.person_id, diag.person_id) AS person_id,
       diag.condition_concept_id,
       diag.first_diag AS first_condition_start_date,
       d.drug_source_value,
       d.first_drug_start_date,
       (YEAR(diag.first_diag) - p.year_of_birth) AS age_at_first_condition,
       (YEAR(d.first_drug_start_date) - p.year_of_birth) AS age_at_first_drug
FROM diag_criteria diag
FULL JOIN drug_criteria d ON diag.person_id = d.person_id
LEFT JOIN p_info p ON COALESCE(d.person_id, diag.person_id) = p.person_id
),