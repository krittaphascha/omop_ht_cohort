WITH desc_con AS ( -- All descendants of the 320128 Essential Hypertension SNOMED
    SELECT c.descendant_concept_id
    FROM omop.concept_ancestor c
    WHERE c.ancestor_concept_id = 320128 -- base query
),
p_info AS ( -- Get patients info
    SELECT p.person_id, YEAR(m.birth_date) as year_of_birth
    FROM dbo.m_patient_info1 m
    LEFT JOIN omop.map__person p ON m.hn = p.hn
    -- SELECT p.person_id, p.year_of_birth
    -- FROM omop.person p
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
    WHERE d.drug_source_value IN ('RAST3', 'NORTV1', 'NORTV5', 'AMLO3', 'AMLT1', 'AMLT5', 'AMLTD1', 'AMLTD', 'YYAMLT10', 'AMLTP5', 'AMLTD5', 'TENTM1', 'TENTM5', 'ATET1', 'ATET2', 'ATET5', 'CADT5', 'CADT', 'CADT40', 'EDAT4', 'EDAT8', 'EDATC4', 'AMTT510', 'BISTN5', 'CONT2', 'CONTC', 'BIST25', 'BIST5', 'BISTS25', 'BISTH5', 'LODT', 'LODT5', 'BLOTP1', 'BLOTP8', 'CANT8', 'CANT16', 'UNIT8', 'BLOTPH8', 'BLOTPH16', 'CAPTR1', 'CAPTR2', 'CAPO5', 'CAPO1', 'CAPTGZ', 'DILTD12', 'DILTTD', 'DILTTD6', 'CARTV', 'CARTV625', 'CARTV125', 'CHLTL', 'DILTD3', 'DILT18', 'DILTT3', 'DILTT6', 'DILTTS1', 'DILTTS1C', 'DILTTS9', 'DILTP12', 'HERT2', 'HERT3', 'HERT6', 'HERT9', 'HERI50', 'DILTD6', 'HERI', 'HERT1', 'CARTR2', 'CARTR4', 'CARTX4', 'DOXTP2', 'DOXTP4', 'DOXT2C', 'DOXT4C', 'CARTR1', 'DOXTZ1', 'DOXTZ2', 'DOXTZ4', 'YYENAT20', 'ENATL2', 'ENATL5', 'ENAT1', 'ENAT2', 'ENAT5', 'ENATA5', 'RENT2', 'RENT5', 'ESMIE', 'ZZESMI', 'PLET1', 'PLET2', 'PLET5', 'FELTD2', 'FELTD1', 'FELTD5', 'FELTF5', 'FELTS10', 'FURTFR5', 'LAST20', 'FUROD', 'FURID', 'FURTFR4', 'FURI2L', 'LASI1', 'LASI2', 'LAST4', 'LAST5', 'FURT5', 'FURT5F', 'FURORX', 'FUROSU', 'FURI', 'FURI2', 'FURT4', 'FURO', 'FURI2H', 'FURIT', 'FURTF5', 'FURT4GPO', 'FURI20GPO', 'DCTO2', 'DCTT25', 'DCTTG', 'DCTO', 'DCTTTO', 'AMITL', 'POLT', 'MODT', 'TANTT2', 'TANTT1', 'TANTT5', 'INDT15', 'NATTS', 'INDTSR', 'NATTR', 'IRBTB3', 'IRBTB15', 'IRBTT15', 'IRBTT3', 'IRBT15', 'IRBT30', 'APRTV1', 'APRTV3', 'APRTVH1', 'APRTVH3', 'APRTVH325', 'YYCOAT150', 'LABI100', 'LABI', 'TRAI', 'ZANT20', 'LERT10', 'LERT20', 'ZANT10', 'LIST1', 'LIST5', 'ZEST1', 'ZEST5', 'LIST2', 'ZEST2', 'LOSTZ1', 'LOSTZ5', 'LOSTT100', 'LOSTL50', 'LOSTLZ5', 'LOSTLZ1', 'COZT', 'COZT1', 'LOST50', 'LOST100', 'FAVT550', 'FAVT5100', 'FORTZ', 'HYZT1', 'HYZT', 'MANTK2', 'MADTI1', 'MADTI2', 'MANTN1', 'MANTC', 'MANTC1', 'NEWHS', 'ALDTO1', 'ALDTO2', 'METTD1', 'METTD2', 'METTD125', 'BETTZ', 'BETTC', 'METTL', 'METTSF', 'NEBTB', 'NEBTL', 'NEBT', 'CARI1', 'CARI2', 'NICI10', 'NICI2', 'CARTD2', 'DNNICI2', 'DNNICI10', 'NIFTD3', 'ADAT2', 'ADAT5', 'ADAT1', 'ADATC2', 'NIFTA5', 'NIFTA10', 'ADAT3', 'ADAT6', 'NIFTN5', 'NIFTN10', 'NIFTD1', 'NIFTD2', 'NIFTD5', 'BAYTP1', 'BAYTP2', 'NITT1', 'OLMT', 'OLMT2', 'OLMTE2', 'OLMTE4', 'NORT520', 'NORT540', 'OLMTP20', 'OLMTP40', 'COVT5', 'COVT10', 'COVT8', 'COVT4', 'COVT2', 'TRITP', 'COVTR55', 'COVTRA55', 'COVTP', 'COVTP4', 'PERTC4', 'MINT1', 'MINT2', 'PRAT1', 'PRAT2', 'PRAT5', 'PRATLO', 'PROTP2', 'PROTB1', 'PROTB4', 'INDT1', 'INDT4', 'PROTP1', 'PROTP4', 'RAMTR5', 'RAMTR10', 'RAMTC2', 'RAMTC5', 'TRITA10', 'TRITA2', 'TRITA5', 'RAMTC1', 'TRITA1', 'TRITC', 'MICT4', 'MICT8', 'TWYT405', 'TWYT805', 'MICTH4', 'MICTH8', 'HYTT2', 'HYTT5', 'HYTT1', 'DIOT', 'DIOT1', 'DIOT3', 'VALTD16', 'VALTP8', 'VALTP16', 'EXFT5', 'EXFT10', 'CODTV', 'CODTV160', 'DNENTTG', 'ENTT5', 'ENTT1', 'ENTT2', 'YYEXFT10', 'EXFTH5', 'ISOTS', 'VERTA4', 'VERTV40', 'ISOIT', 'VERI2', 'VERTA8', 'VERTS2', 'ISOIP', 'ISOT4', 'ISOT8') -- This can be switched to standard hypertension drug_concept_id
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
diag_list AS (
SELECT 
  MIN(CASE WHEN ca.ancestor_concept_id = 201826 THEN c.condition_start_date END) AS first_dm_date,
  MIN(CASE WHEN ca.ancestor_concept_id = 4227594 THEN c.condition_start_date END) AS first_acne_date,
  MIN(CASE WHEN ca.ancestor_concept_id = 315643 THEN c.condition_start_date END) AS first_arrhythmia_date,
  MIN(CASE WHEN ca.ancestor_concept_id = 315078 THEN c.condition_start_date END) AS first_palpitation_date,
  MIN(CASE WHEN ca.ancestor_concept_id = 313217 THEN c.condition_start_date END) AS first_af_date,
  MIN(CASE WHEN ca.ancestor_concept_id = 198803 THEN c.condition_start_date END) AS first_bph_date,
  MIN(CASE WHEN ca.ancestor_concept_id = 4064161 THEN c.condition_start_date END) AS first_cirrhosis_date,
  MIN(CASE WHEN ca.ancestor_concept_id = 4339092 THEN c.condition_start_date END) AS first_hairloss_date,
  MIN(CASE WHEN ca.ancestor_concept_id = 316139 THEN c.condition_start_date END) AS first_hf_date,
  MIN(CASE WHEN ca.ancestor_concept_id = 4167493 THEN c.condition_start_date END) AS first_pregnancy_hypertension_date,
  MIN(CASE WHEN ca.ancestor_concept_id = 4142479 THEN c.condition_start_date END) AS first_hyperthyroid_date,
  MIN(CASE WHEN ca.ancestor_concept_id = 318736 THEN c.condition_start_date END) AS first_migraine_date,
  MIN(CASE WHEN ca.ancestor_concept_id = 316139 THEN c.condition_start_date END) AS first_ckd_date,
  MIN(CASE WHEN ca.ancestor_concept_id = 43531003 THEN c.condition_start_date END) AS first_tremor_date,
 p.person_id
FROM omop.person p
        INNER JOIN inclusion i ON p.person_id = i.person_id
        LEFT JOIN omop.condition_occurrence c ON p.person_id = c.person_id
        LEFT JOIN omop.concept_ancestor ca ON c.condition_concept_id = ca.descendant_concept_id
        WHERE ca.ancestor_concept_id IN (201826, 4227594, 315643, 315078, 313217, 198803, 4064161, 4339092, 316139, 4167493, 4142479, 318736, 316139, 43531003)
        GROUP BY p.person_id
    ),
drug_list AS (
SELECT 
  MIN(CASE WHEN d.drug_source_value IN ('ZEST2', 'COVTP4', 'ENAT1', 'RAMTC1', 'PERTC4', 'CAPTR1', 'RENT2', 'LIST1', 'COVTP', 'TANTT1', 'COVTR55', 'TANTT2', 'AMTT510', 'ENATA5', 'RENT5', 'RAMTR10', 'TRITA5', 'RAMTC5', 'TRITA1', 'CAPO5', 'ENAT5', 'CAPTGZ', 'LIST5', 'LIST2', 'YYENAT20', 'COVT8', 'ZEST1', 'CAPTR2', 'COVT5', 'COVT2', 'COVT10', 'RAMTC2', 'TRITA10', 'ENAT2', 'ZEST5', 'ENATL2', 'ENATL5', 'TRITA2', 'COVTRA55', 'CAPO1', 'TANTT5', 'COVT4', 'TRITC', 'RAMTR5', 'TRITP') THEN d.drug_exposure_start_date END) AS first_acei_date,
  MIN(CASE WHEN d.drug_source_value IN ('HYTT5', 'CARTX4', 'PRATLO', 'HYTT1', 'DOXTZ2', 'DOXTP2', 'PRAT1', 'DOXTZ4', 'CARTR2', 'PRAT2', 'HYTT2', 'DOXTZ1', 'DOXT4C', 'PRAT5', 'CARTR1', 'DOXTP4', 'CARTR4', 'MINT2', 'MINT1', 'DOXT2C') THEN d.drug_exposure_start_date END) AS first_alpha_date,
  MIN(CASE WHEN d.drug_source_value IN ('ALDTO1', 'METTD2', 'ALDTO2', 'METTD125', 'METTD1') THEN d.drug_exposure_start_date END) AS first_alpha_agonist_date,
  MIN(CASE WHEN d.drug_source_value IN ('CARTV', 'DILTTD', 'DILTTD6', 'CARTV625', 'LABI100', 'CARTV125', 'LABI', 'TRAI', 'DILTD12') THEN d.drug_exposure_start_date END) AS first_alpha_bb_date,
  MIN(CASE WHEN d.drug_source_value IN ('LOSTLZ1', 'BLOTPH16', 'OLMTE2', 'CODTV', 'IRBTB3', 'APRTV3', 'LOSTZ1', 'DNENTTG', 'ENTT1', 'MICTH4', 'COZT', 'ENTT5', 'FAVT550', 'IRBTT15', 'OLMTE4', 'BLOTPH8', 'DIOT1', 'IRBTB15', 'EXFTH5', 'MICTH8', 'IRBT30', 'NORT520', 'EXFT10', 'ENTT2', 'APRTVH1', 'MICT4', 'OLMT2', 'LOSTL50', 'IRBT15', 'LOSTLZ5', 'LOST100', 'FORTZ', 'HYZT1', 'OLMT', 'VALTP8', 'YYEXFT10', 'DIOT', 'CODTV160', 'LOST50', 'FAVT5100', 'IRBTT3', 'EXFT5', 'APRTVH325', 'OLMTP20', 'TWYT405', 'EDAT8', 'EDAT4', 'DIOT3', 'VALTD16', 'CANT16', 'YYCOAT150', 'BLOTP1', 'NORT540', 'OLMTP40', 'EDATC4', 'TWYT805', 'APRTV1', 'LOSTT100', 'UNIT8', 'HYZT', 'LOSTZ5', 'MICT8', 'BLOTP8', 'APRTVH3', 'COZT1', 'CANT8', 'VALTP16') THEN d.drug_exposure_start_date END) AS first_arb_date,
  MIN(CASE WHEN d.drug_source_value IN ('MADTI1', 'ADAT6', 'PLET2', 'NORTV1', 'ADAT5', 'NIFTN10', 'FAVT550', 'ADATC2', 'NIFTD5', 'DNNICI2', 'COVTR55', 'YYAMLT10', 'BAYTP1', 'AMLTP5', 'FELTS10', 'FELTD5', 'EXFTH5', 'NORT520', 'AMTT510', 'EXFT10', 'MANTK2', 'FELTD1', 'MANTC', 'NIFTD3', 'MANTN1', 'NITT1', 'YYEXFT10', 'LERT10', 'ZANT20', 'FELTF5', 'FELTD2', 'NIFTD1', 'AMLTD', 'FAVT5100', 'EXFT5', 'NICI2', 'NIFTA5', 'NIFTN5', 'CADT5', 'LERT20', 'AMLT1', 'BAYTP2', 'TWYT405', 'CARI2', 'ZANT10', 'AMLTD1', 'ADAT3', 'MADTI2', 'NORT540', 'PLET5', 'NEWHS', 'TWYT805', 'NICI10', 'CARTD2', 'AMLTD5', 'UNIT8', 'COVTRA55', 'NIFTA10', 'ADAT1', 'AMLT5', 'NIFTD2', 'CADT', 'NORTV5', 'AMLO3', 'CADT40', 'MANTC1', 'PLET1', 'CARI1', 'DNNICI10', 'ADAT2', 'TRITP') THEN d.drug_exposure_start_date END) AS first_dhpCCB_date,
  MIN(CASE WHEN d.drug_source_value IN ('FURI2L', 'LAST5', 'FURO', 'FURT5', 'FURORX', 'FURT4', 'FURIT', 'FUROD', 'LAST20', 'FURTF5', 'FUROSU', 'LAST4', 'FURID', 'FURI2H', 'LASI2', 'LASI1', 'FURT4GPO', 'FURTFR5', 'FURTFR4', 'FURI2', 'FURI', 'FURT5F', 'FURI20GPO') THEN d.drug_exposure_start_date END) AS first_loop_date,
  MIN(CASE WHEN d.drug_source_value IN ('DILTP12', 'DILTD6', 'DILT18', 'ISOT4', 'HERI50', 'DILTTS1C', 'HERI', 'HERT6', 'HERT1', 'DILTTS9', 'ISOT8', 'DILTT6', 'ISOIT', 'HERT9', 'DILTT3', 'HERT3', 'VERTA4', 'VERI2', 'DILTD3', 'VERTV40', 'ISOTS', 'HERT2', 'VERTA8', 'DILTTS1', 'VERTS2', 'ISOIP') THEN d.drug_exposure_start_date END) AS first_non_dhpCCB_date,
  MIN(CASE WHEN d.drug_source_value IN ('INDT4', 'PROTB4', 'PROTB1', 'PROTP1', 'PROTP4', 'INDT1', 'PROTP2') THEN d.drug_exposure_start_date END) AS first_non_selective_bb_date,
  MIN(CASE WHEN d.drug_source_value IN ('RAST3') THEN d.drug_exposure_start_date END) AS first_renin_inhibitor_date,
  MIN(CASE WHEN d.drug_source_value IN ('BISTS25', 'NEBTB', 'BISTN5', 'BIST5', 'CONT2', 'METTL', 'ESMIE', 'BISTH5', 'TENTM5', 'ZZESMI', 'BIST25', 'LODT5', 'LODT', 'ATET1', 'ATET2', 'BETTC', 'CONTC', 'ATET5', 'TENTM1', 'NEBTL', 'BETTZ', 'METTSF', 'NEBT') THEN d.drug_exposure_start_date END) AS first_selective_bb_date,
  MIN(CASE WHEN d.drug_source_value IN ('BLOTPH16', 'CODTV', 'MICTH4', 'BLOTPH8', 'EXFTH5', 'MODT', 'MICTH8', 'APRTVH1', 'YYEXFT10', 'FORTZ', 'HYZT1', 'DCTT25', 'CODTV160', 'POLT', 'LODT5', 'APRTVH325', 'OLMTP20', 'LODT', 'DCTTG', 'DCTO2', 'YYCOAT150', 'AMITL', 'OLMTP40', 'DCTTTO', 'HYZT', 'TRITC', 'APRTVH3', 'DCTO') THEN d.drug_exposure_start_date END) AS first_thiazides_date,
  MIN(CASE WHEN d.drug_source_value IN ('COVTP4', 'INDT15', 'CHLTL', 'NATTS', 'NATTR', 'INDTSR', 'COVTP', 'EDATC4', 'TRITP') THEN d.drug_exposure_start_date END) AS first_thiazides_like_date,
  MIN(CASE WHEN d.drug_source_value IN ('DNENTTG', 'ENTT5', 'ENTT2', 'ENTT1') THEN d.drug_exposure_start_date END) AS first_arni_date,
  MIN(CASE WHEN d.drug_source_value IN ('MODT', 'POLT', 'AMITL') THEN d.drug_exposure_start_date END) AS first_k_sparing_date,
  MIN(CASE WHEN d.drug_source_value IN ('CADT5', 'CADT', 'CADT40') THEN d.drug_exposure_start_date END) AS first_lipid_lower_date,
 p.person_id
FROM omop.person p
INNER JOIN inclusion i ON i.person_id = p.person_id 
LEFT JOIN omop.drug_exposure d ON p.person_id = d.person_id
WHERE d.drug_source_value IN ('BISTS25', 'FURI2L', 'LAST5', 'IRBTB3', 'APRTV3', 'ENAT1', 'PLET2', 'PERTC4', 'BIST5', 'MICTH4', 'ADAT5', 'CONT2', 'FURIT', 'FURTF5', 'METTL', 'FUROSU', 'TANTT1', 'DIOT1', 'EXFTH5', 'HERT6', 'IRBT30', 'NORT520', 'LAST4', 'ENATA5', 'TRITA5', 'RAMTR10', 'APRTVH1', 'FURID', 'OLMT2', 'LOSTLZ5', 'FORTZ', 'LASI2', 'LIST5', 'CAPTGZ', 'ISOIT', 'DIOT', 'HYTT1', 'AMLTD', 'TENTM5', 'DOXTP2', 'DCTT25', 'EXFT5', 'DOXTZ4', 'CADT5', 'BIST25', 'TWYT405', 'BAYTP2', 'EDAT8', 'VERTA4', 'CARI2', 'ZEST5', 'DOXTZ1', 'YYCOAT150', 'BETTC', 'NORT540', 'OLMTP40', 'DILTD12', 'CARTR4', 'MINT2', 'NICI10', 'ENATL2', 'ATET5', 'LOSTT100', 'VERTS2', 'METTD2', 'FURT5F', 'TANTT5', 'COVT4', 'DNNICI10', 'RAMTR5', 'AMLO3', 'CADT40', 'MANTC1', 'APRTVH3', 'COZT1', 'CARI1', 'FURI20GPO', 'ADAT2', 'CANT8', 'ENTT1', 'VALTP16', 'NEBT', 'LOSTLZ1', 'BLOTPH16', 'CODTV', 'FURO', 'NEBTB', 'NORTV1', 'RAMTC1', 'FURT5', 'BISTN5', 'CAPTR1', 'FURORX', 'NIFTN10', 'DILT18', 'ISOT4', 'FAVT550', 'IRBTT15', 'LAST20', 'OLMTE4', 'MODT', 'TANTT2', 'FELTD5', 'DILTTS9', 'MANTC', 'FELTD1', 'RENT5', 'RAMTC5', 'MANTN1', 'LOSTL50', 'LOST100', 'HYTT5', 'OLMT', 'PROTP1', 'CARTX4', 'NIFTD1', 'YYENAT20', 'LABI', 'METTD1', 'LOST50', 'DOXTZ2', 'NICI2', 'FURTFR5', 'CARTV', 'DILTTD', 'ZZESMI', 'CARTV625', 'LERT20', 'COVT2', 'OLMTP20', 'AMLT1', 'EDAT4', 'FURTFR4', 'ZANT10', 'FURI2', 'LODT', 'PRAT2', 'HYTT2', 'ATET1', 'PRAT5', 'ADAT3', 'DCTO2', 'CONTC', 'AMITL', 'NEWHS', 'FURI', 'APRTV1', 'HERT2', 'AMLTD5', 'TRITA2', 'UNIT8', 'CAPO1', 'MINT1', 'TRITC', 'LOSTZ5', 'AMLT5', 'RAST3', 'INDT4', 'DILTP12', 'ZEST2', 'OLMTE2', 'DNENTTG', 'CARTV125', 'COZT', 'METTD125', 'NIFTD5', 'RENT2', 'BLOTPH8', 'PROTB4', 'COVTR55', 'IRBTB15', 'YYAMLT10', 'HERT1', 'MANTK2', 'ENTT2', 'NITT1', 'YYEXFT10', 'FURI2H', 'IRBT15', 'LERT10', 'DILTT6', 'HYZT1', 'VALTP8', 'FELTD2', 'BISTH5', 'FURT4GPO', 'PRATLO', 'CODTV160', 'TRAI', 'FAVT5100', 'IRBTT3', 'COVT8', 'ZEST1', 'CAPTR2', 'DILTT3', 'PRAT1', 'DILTTD6', 'COVT5', 'PROTB1', 'CARTR2', 'LABI100', 'COVT10', 'VERI2', 'DIOT3', 'ENAT2', 'VALTD16', 'AMLTD1', 'DOXT4C', 'CARTR1', 'DOXTP4', 'VERTV40', 'ISOTS', 'DCTTTO', 'ENATL5', 'VERTA8', 'DILTTS1', 'COVTRA55', 'TENTM1', 'HYZT', 'ADAT1', 'NIFTD2', 'CADT', 'NORTV5', 'CHLTL', 'NATTS', 'BLOTP8', 'NATTR', 'METTSF', 'EXFT10', 'MADTI1', 'ADAT6', 'COVTP4', 'LOSTZ1', 'INDT15', 'DILTD6', 'ENTT5', 'FURT4', 'PROTP4', 'FUROD', 'ADATC2', 'LIST1', 'HERI50', 'COVTP', 'DILTTS1C', 'DNNICI2', 'HERI', 'BAYTP1', 'ESMIE', 'AMLTP5', 'FELTS10', 'MICTH8', 'ISOT8', 'AMTT510', 'TRITA1', 'NIFTD3', 'MICT4', 'CAPO5', 'ZANT20', 'FELTF5', 'ENAT5', 'LIST2', 'LASI1', 'HERT9', 'PROTP2', 'NIFTA5', 'NIFTN5', 'HERT3', 'APRTVH325', 'LODT5', 'POLT', 'RAMTC2', 'TRITA10', 'DILTD3', 'DCTTG', 'CANT16', 'ATET2', 'MADTI2', 'INDTSR', 'BLOTP1', 'PLET5', 'EDATC4', 'TWYT805', 'ALDTO1', 'CARTD2', 'ALDTO2', 'NIFTA10', 'MICT8', 'ISOIP', 'NEBTL', 'BETTZ', 'PLET1', 'DOXT2C', 'INDT1', 'DCTO', 'TRITP')
GROUP BY p.person_id
)
,
exclusion AS (SELECT dl.person_id,
CASE WHEN first_hyperthyroid_date <= first_non_selective_bb_date THEN 1 ELSE 0 END AS hyperthyroid_non_selective_bb,
CASE WHEN first_af_date <= first_non_selective_bb_date THEN 1 ELSE 0 END AS af_non_selective_bb,
CASE WHEN first_af_date <= first_selective_bb_date THEN 1 ELSE 0 END AS af_selective_bb,
CASE WHEN first_af_date <= first_alpha_bb_date THEN 1 ELSE 0 END AS af_alpha_bb,
CASE WHEN first_hf_date <= first_loop_date THEN 1 ELSE 0 END AS hf_loop,
CASE WHEN first_cirrhosis_date <= first_k_sparing_date THEN 1 ELSE 0 END AS cirrhosis_k_sparing,
CASE WHEN first_bph_date <= first_alpha_date THEN 1 ELSE 0 END AS bph_alpha,
CASE WHEN first_pregnancy_hypertension_date <= first_alpha_agonist_date THEN 1 ELSE 0 END AS pregnancy_hypertension_alpha_agonist,
CASE WHEN first_arrhythmia_date <= first_non_dhpCCB_date THEN 1 ELSE 0 END AS arrhythmia_non_dhpCCB
FROM diag_list dl JOIN drug_list dr ON dl.person_id = dr.person_id
),summary AS (SELECT 
        i.person_id,
        i.condition_concept_id,
        i.first_condition_start_date,
        i.drug_source_value,
        i.first_drug_start_date,
        CASE    
            WHEN i.first_condition_start_date < i.first_drug_start_date THEN i.first_condition_start_date
            ELSE i.first_drug_start_date 
        END AS index_date,
        CASE 
            WHEN i.age_at_first_condition IS NOT NULL AND i.age_at_first_drug IS NOT NULL THEN 
                CASE 
                    WHEN i.age_at_first_condition < i.age_at_first_drug THEN i.age_at_first_condition
                    ELSE i.age_at_first_drug
                END
            ELSE 
                COALESCE(i.age_at_first_condition, i.age_at_first_drug)
        END AS age_at_index,
        CASE 
            WHEN i.condition_concept_id IS NOT NULL AND i.drug_source_value IS NOT NULL THEN 'diag+drug'
            WHEN i.condition_concept_id IS NOT NULL THEN 'diag'
            WHEN i.drug_source_value IS NOT NULL THEN 'drug'
            ELSE NULL
        END AS criteria,
        COALESCE(hyperthyroid_non_selective_bb, 0) + 
        COALESCE(af_non_selective_bb, 0) + 
        COALESCE(af_selective_bb, 0) + 
        COALESCE(af_alpha_bb, 0) + 
        COALESCE(hf_loop, 0) + 
        COALESCE(cirrhosis_k_sparing, 0) + 
        COALESCE(bph_alpha, 0) + 
        COALESCE(pregnancy_hypertension_alpha_agonist, 0) + 
        COALESCE(arrhythmia_non_dhpCCB, 0) AS total_exclusion
        FROM inclusion i 
        LEFT JOIN exclusion e ON i.person_id = e.person_id
        )
        SELECT *
        INTO omop_datareq.cohort_ht_v2
        FROM summary
        WHERE NOT (criteria = 'drug' AND total_exclusion > 0)        
        AND age_at_index >= 18



