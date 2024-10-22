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
  MIN(CASE WHEN d.drug_source_value IN ('CAPO5', 'TRITA1', 'CAPO1', 'LIST5', 'TANTT2', 'TRITA2', 'RAMTR10', 'ENATA5', 'RAMTR5', 'LIST2', 'RAMTC1', 'RENT5', 'COVTP4', 'COVT2', 'RENT2', 'COVT8', 'TANTT1', 'CAPTR1', 'ZEST5', 'COVTRA55', 'RAMTC2', 'TRITA5', 'COVT5', 'ENATL2', 'ENATL5', 'TRITP', 'ZEST2', 'TRITA10', 'COVTP', 'AMTT510', 'ENAT2', 'ZEST1', 'PERTC4', 'ENAT1', 'RAMTC5', 'TRITC', 'CAPTGZ', 'COVT10', 'YYENAT20', 'CAPTR2', 'ENAT5', 'LIST1', 'COVT4', 'TANTT5', 'COVTR55') THEN d.drug_exposure_start_date END) AS first_acei_date,
  MIN(CASE WHEN d.drug_source_value IN ('DOXT4C', 'HYTT1', 'DOXT2C', 'DOXTP2', 'CARTR2', 'HYTT5', 'CARTR1', 'DOXTZ1', 'CARTX4', 'PRAT5', 'MINT2', 'HYTT2', 'DOXTZ2', 'PRATLO', 'MINT1', 'DOXTZ4', 'CARTR4', 'PRAT1', 'DOXTP4', 'PRAT2') THEN d.drug_exposure_start_date END) AS first_alpha_date,
  MIN(CASE WHEN d.drug_source_value IN ('METTD1', 'ALDTO1', 'ALDTO2', 'METTD2', 'METTD125') THEN d.drug_exposure_start_date END) AS first_alpha_agonist_date,
  MIN(CASE WHEN d.drug_source_value IN ('DILTTD6', 'CARTV625', 'CARTV125', 'DILTTD', 'TRAI', 'LABI', 'LABI100', 'CARTV', 'DILTD12') THEN d.drug_exposure_start_date END) AS first_alpha_bb_date,
  MIN(CASE WHEN d.drug_source_value IN ('LOSTT100', 'LOST50', 'BLOTP8', 'LOST100', 'FAVT550', 'ENTT5', 'ENTT1', 'LOSTL50', 'NORT540', 'EXFTH5', 'OLMTP40', 'EXFT10', 'APRTVH3', 'COZT1', 'TWYT805', 'IRBT15', 'UNIT8', 'DIOT1', 'LOSTLZ5', 'CODTV', 'DIOT', 'YYCOAT150', 'EDATC4', 'BLOTPH8', 'MICTH8', 'CANT16', 'EDAT4', 'IRBTB3', 'HYZT', 'OLMTE4', 'VALTD16', 'IRBT30', 'NORT520', 'HYZT1', 'LOSTLZ1', 'LOSTZ1', 'OLMTP20', 'CODTV160', 'OLMTE2', 'IRBTT15', 'VALTP16', 'APRTVH1', 'EDAT8', 'IRBTB15', 'APRTVH325', 'OLMT', 'VALTP8', 'APRTV3', 'LOSTZ5', 'DIOT3', 'FORTZ', 'DNENTTG', 'EXFT5', 'CANT8', 'MICTH4', 'ENTT2', 'BLOTP1', 'YYEXFT10', 'OLMT2', 'MICT8', 'FAVT5100', 'MICT4', 'IRBTT3', 'APRTV1', 'TWYT405', 'COZT', 'BLOTPH16') THEN d.drug_exposure_start_date END) AS first_arb_date,
  MIN(CASE WHEN d.drug_source_value IN ('PLET5', 'FELTD2', 'NIFTN5', 'MADTI2', 'AMLO3', 'ADATC2', 'PLET1', 'ZANT20', 'NIFTD2', 'FAVT550', 'MADTI1', 'FELTF5', 'CADT5', 'CADT', 'CARI2', 'DNNICI2', 'NORT540', 'EXFTH5', 'EXFT10', 'BAYTP2', 'CARTD2', 'TWYT805', 'MANTC1', 'AMLTD', 'UNIT8', 'MANTN1', 'AMLT5', 'CADT40', 'FELTD5', 'AMLTD1', 'NIFTD5', 'COVTRA55', 'NEWHS', 'FELTD1', 'NORTV5', 'NORT520', 'NORTV1', 'BAYTP1', 'TRITP', 'NIFTA5', 'DNNICI10', 'AMTT510', 'NICI10', 'NIFTD3', 'PLET2', 'MANTK2', 'ADAT3', 'YYAMLT10', 'CARI1', 'NICI2', 'LERT10', 'NIFTA10', 'NIFTN10', 'ZANT10', 'NITT1', 'EXFT5', 'YYEXFT10', 'LERT20', 'AMLTD5', 'ADAT6', 'NIFTD1', 'MANTC', 'AMLTP5', 'AMLT1', 'ADAT5', 'ADAT2', 'FAVT5100', 'TWYT405', 'ADAT1', 'COVTR55', 'FELTS10') THEN d.drug_exposure_start_date END) AS first_dhpCCB_date,
  MIN(CASE WHEN d.drug_source_value IN ('FURT5F', 'FURTF5', 'FURI20GPO', 'LAST4', 'FURI2H', 'FUROSU', 'LAST20', 'FURO', 'FURIT', 'LAST5', 'FURORX', 'LASI2', 'FURT4', 'FURT4GPO', 'FURI2L', 'FURI2', 'FURTFR5', 'FURT5', 'FURTFR4', 'FURID', 'FUROD', 'LASI1', 'FURI') THEN d.drug_exposure_start_date END) AS first_loop_date,
  MIN(CASE WHEN d.drug_source_value IN ('ISOTS', 'VERTS2', 'VERTV40', 'ISOIT', 'DILTT6', 'HERT2', 'HERI', 'HERT1', 'HERT3', 'ISOIP', 'ISOT4', 'DILTTS1C', 'DILTD3', 'DILTD6', 'VERTA8', 'DILTT3', 'HERT6', 'VERI2', 'HERT9', 'DILTTS1', 'ISOT8', 'DILTP12', 'DILT18', 'VERTA4', 'DILTTS9', 'HERI50') THEN d.drug_exposure_start_date END) AS first_non_dhpCCB_date,
  MIN(CASE WHEN d.drug_source_value IN ('PROTB4', 'INDT4', 'PROTP2', 'PROTP4', 'PROTB1', 'INDT1', 'PROTP1') THEN d.drug_exposure_start_date END) AS first_non_selective_bb_date,
  MIN(CASE WHEN d.drug_source_value IN ('RAST3') THEN d.drug_exposure_start_date END) AS first_renin_inhibitor_date,
  MIN(CASE WHEN d.drug_source_value IN ('LODT5', 'NEBTL', 'BISTN5', 'BETTZ', 'ATET5', 'METTSF', 'CONT2', 'NEBT', 'TENTM1', 'BISTH5', 'ATET1', 'LODT', 'METTL', 'BIST25', 'NEBTB', 'BIST5', 'TENTM5', 'ZZESMI', 'BETTC', 'BISTS25', 'CONTC', 'ATET2', 'ESMIE') THEN d.drug_exposure_start_date END) AS first_selective_bb_date,
  MIN(CASE WHEN d.drug_source_value IN ('LODT5', 'MODT', 'EXFTH5', 'DCTO', 'OLMTP40', 'APRTVH3', 'AMITL', 'DCTTTO', 'CODTV', 'YYCOAT150', 'BLOTPH8', 'MICTH8', 'HYZT', 'HYZT1', 'OLMTP20', 'CODTV160', 'DCTTG', 'LODT', 'APRTVH1', 'APRTVH325', 'DCTT25', 'FORTZ', 'TRITC', 'DCTO2', 'MICTH4', 'YYEXFT10', 'BLOTPH16', 'POLT') THEN d.drug_exposure_start_date END) AS first_thiazides_date,
  MIN(CASE WHEN d.drug_source_value IN ('CHLTL', 'INDT15', 'INDTSR', 'COVTP4', 'TRITP', 'NATTS', 'COVTP', 'NATTR', 'EDATC4') THEN d.drug_exposure_start_date END) AS first_thiazides_like_date,
  MIN(CASE WHEN d.drug_source_value IN ('ENTT2', 'DNENTTG', 'ENTT1', 'ENTT5') THEN d.drug_exposure_start_date END) AS first_arni_date,
  MIN(CASE WHEN d.drug_source_value IN ('AMITL', 'MODT', 'POLT') THEN d.drug_exposure_start_date END) AS first_k_sparing_date,
  MIN(CASE WHEN d.drug_source_value IN ('CADT', 'CADT40', 'CADT5') THEN d.drug_exposure_start_date END) AS first_lipid_lower_date,
 p.person_id
FROM omop.person p
INNER JOIN inclusion i ON i.person_id = p.person_id 
LEFT JOIN omop.drug_exposure d ON p.person_id = d.person_id
WHERE d.drug_source_value IN ('DOXT4C', 'ISOTS', 'CAPO1', 'BLOTP8', 'ISOIT', 'CARTV625', 'ZANT20', 'ENTT5', 'CARTR2', 'BETTZ', 'ENATA5', 'RAMTR5', 'LAST4', 'FURI2H', 'HERT1', 'ATET5', 'DCTO', 'CONT2', 'PROTB4', 'IRBT15', 'ZEST5', 'TRITA5', 'ENTT1', 'METTD2', 'CANT16', 'OLMTE4', 'NEWHS', 'FURT4GPO', 'NORTV5', 'VERTA8', 'HYZT1', 'LOSTLZ1', 'BISTH5', 'TRITA10', 'COVTP', 'APRTVH1', 'HERT9', 'OLMT', 'PLET2', 'FURTFR5', 'APRTV3', 'LABI100', 'NIFTN10', 'DCTT25', 'TRITC', 'INDT4', 'DCTO2', 'BIST5', 'YYEXFT10', 'BLOTP1', 'TENTM5', 'DOXTZ4', 'MANTC', 'CAPTR2', 'DILTP12', 'DOXTP4', 'COVT4', 'TANTT5', 'INDT1', 'COVTR55', 'POLT', 'NIFTN5', 'VERTS2', 'HYTT1', 'LOST50', 'TRITA2', 'LOST100', 'PLET1', 'HERI50', 'LODT5', 'RAMTR10', 'NIFTD2', 'DILTTD', 'CARI2', 'CADT', 'LOSTL50', 'NORT540', 'BISTN5', 'RAMTC1', 'LABI', 'HERT3', 'EXFT10', 'APRTVH3', 'RENT5', 'AMLTD', 'COVTP4', 'MANTN1', 'LOSTLZ5', 'FURIT', 'CODTV', 'CARTX4', 'DIOT', 'FURORX', 'CAPTR1', 'TENTM1', 'EDATC4', 'RAMTC2', 'MICTH8', 'ESMIE', 'LASI2', 'IRBTB3', 'COVT5', 'DILTD6', 'NORT520', 'NORTV1', 'DILTT3', 'INDT15', 'LOSTZ1', 'LODT', 'ENATL5', 'CARTV125', 'TRITP', 'OLMTE2', 'ZEST2', 'IRBTT15', 'BAYTP1', 'NIFTA5', 'NIFTD3', 'ENAT2', 'IRBTB15', 'FURI2', 'ZEST1', 'PERTC4', 'YYAMLT10', 'DOXTZ2', 'FURT5', 'FURTFR4', 'FORTZ', 'DNENTTG', 'RAMTC5', 'NITT1', 'FUROD', 'DILTTS1', 'ISOT8', 'NIFTD1', 'YYENAT20', 'FAVT5100', 'MICT4', 'AMLTP5', 'DILTTS1C', 'METTD125', 'PROTP1', 'APRTV1', 'ATET2', 'DIOT1', 'COZT', 'OLMT2', 'FURI', 'LOSTT100', 'TRITA1', 'PLET5', 'ADAT2', 'MADTI2', 'AMLO3', 'FURI20GPO', 'TANTT2', 'DILTT6', 'ALDTO2', 'NEBTL', 'DILT18', 'HYTT5', 'DNNICI2', 'HERI', 'EXFTH5', 'METTSF', 'FUROSU', 'CARTR1', 'OLMTP40', 'LAST20', 'BAYTP2', 'COZT1', 'CARTD2', 'MANTC1', 'FELTD5', 'NEBT', 'AMLTD1', 'COVT8', 'DILTD3', 'COVTRA55', 'VALTD16', 'EDAT4', 'FELTD1', 'IRBT30', 'ATET1', 'VERI2', 'MINT2', 'VALTP16', 'NICI10', 'DILTTS9', 'ADAT3', 'VALTP8', 'CARI1', 'NICI2', 'LOSTZ5', 'LERT10', 'DIOT3', 'BIST25', 'ZANT10', 'PRATLO', 'NEBTB', 'ENAT1', 'MINT1', 'EXFT5', 'CANT8', 'CAPTGZ', 'COVT10', 'AMLTD5', 'ZZESMI', 'LASI1', 'BETTC', 'CARTR4', 'ENAT5', 'LIST1', 'CONTC', 'TWYT405', 'DILTD12', 'BLOTPH16', 'CAPO5', 'FELTD2', 'FELTS10', 'FURT5F', 'FURTF5', 'ADATC2', 'LIST5', 'METTD1', 'DILTTD6', 'DOXT2C', 'VERTV40', 'HERT2', 'FAVT550', 'MADTI1', 'DOXTP2', 'FELTF5', 'CADT5', 'MODT', 'PROTB1', 'LIST2', 'CARTV', 'TRAI', 'ISOT4', 'TWYT805', 'INDTSR', 'UNIT8', 'ALDTO1', 'AMITL', 'DCTTTO', 'AMLT5', 'COVT2', 'RENT2', 'DOXTZ1', 'CADT40', 'FURO', 'TANTT1', 'LAST5', 'YYCOAT150', 'BLOTPH8', 'NIFTD5', 'NATTS', 'HYZT', 'NATTR', 'FURT4', 'ENATL2', 'PRAT5', 'HERT6', 'CHLTL', 'OLMTP20', 'CODTV160', 'FURI2L', 'DCTTG', 'PROTP2', 'DNNICI10', 'AMTT510', 'METTL', 'HYTT2', 'EDAT8', 'MANTK2', 'APRTVH325', 'NIFTA10', 'FURID', 'MICTH4', 'ENTT2', 'LERT20', 'ADAT6', 'PROTP4', 'BISTS25', 'MICT8', 'PRAT1', 'IRBTT3', 'PRAT2', 'AMLT1', 'ADAT5', 'RAST3', 'ADAT1', 'VERTA4', 'ISOIP')
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
        FROM summary
        WHERE age_at_index >= 18
        AND NOT (criteria = 'drug' AND total_exclusion > 0);