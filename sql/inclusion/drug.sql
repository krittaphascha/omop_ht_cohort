WITH drug_order AS (
    SELECT  d.person_id,
            d.drug_source_value,
            MIN(d.drug_exposure_start_date) as first_drug_start_date,
            ROW_NUMBER() OVER(PARTITION BY d.person_id ORDER BY d.drug_exposure_start_date) as rn
    FROM [cdm].[drug_exposure] d
    WHERE d.drug_source_value IN ('BAYTP1', 'BAYTP2', 'BETTC', 'BLOTP1', 'BLOTP8', 'BLOTPH8', 'CAPTR1', 'CAPTR2', 
                'CARI1', 'CARI2', 'DILTT3', 'DILTT6', 'DILTTD', 'DILTTD6', 'DILTTS1', 'DILTTS1C',
                'DILTTS9', 'DIOT', 'DIOT1', 'ENAT1', 'ENAT2', 'ENAT5', 'ISOTS', 'LASI1',
                'LASI2', 'LAST4', 'LAST5', 'NORTV1', 'NORTV5', 'TANTT1',  'TANTT5',
                'TENTM1', 'TENTM5', 'ZANT10', 'MICTH4', 'MICTH8', 'HERI50', 'DCTO',
                'DIOT3', 'LOST50', 'LODT5', 'FURO', 'LOST100', 'RAST3', 'APRTVH325',
                'NORT520', 'NORT540', 'TWYT405', 'TWYT805', 'ESMIE', 'MANTK2', 'AMTT510',
                'FAVT550', 'FAVT5100', 'CANT8', 'CARTV125', 'ENTT5', 'ENTT1', 'ENTT2',
                'BIST5', 'FURTF5', 'FELTF5', 'CHLTL', 'TRITP', 'DILTD3', 'AMLTD5',
                'ENATL2', 'ENATL5', 'LOSTZ1', 'AMLTD1', 'LOSTZ5', 'IRBTT15', 'IRBTT3',
                'FURTFR5', 'VALTP8', 'VALTP16', 'NEBTL', 'CARTD2', 'COVT2', 'DILT18',
                'DILTD12', 'PROTP2', 'RAMTC1', 'TANTT2', 'ADAT3', 'ADAT6', 'CODTV', 'CODTV160',
                'FORTZ', 'FURI', 'FURI2', 'FURT4', 'FURT5', 'LIST1', 'LIST5',
                'MADTI1', 'MADTI2', 'METTL', 'MICT4', 'MICT8', 'PLET1', 'PLET2',
                'PLET5', 'PROTP1', 'PROTP4', 'RAMTC2', 'RAMTC5', 'RENT2', 'RENT5',
                'TRITA10', 'TRITA2', 'TRITA5', 'VERTA4', 'OLMT', 'ADATC2', 'NEBT',
                'CADT5', 'CARTV', 'CAPO1', 'CAPO5', 'AMLO3', 'CARTV625', 'INDT15',
                'COVTP4', 'BISTN5', 'DCTT25', 'COVT5', 'COVT10', 'COVTP', 'RAMTR5', 'RAMTR10',
                'COVTR55', 'BETTZ', 'FURI2H', 'COVTRA55', 'FURT4GPO', 'FURI20GPO', 'FURT5F', 'ZZESMI',
                'ENATA5', 'EXFTH5', 'IRBT15', 'IRBT30', 'EDAT4', 'EDAT8', 'DCTTTO', 'FURORX',
                'EDATC4', 'LERT10', 'LERT20', 'ISOIT', 'LOSTLZ5', 'LOSTLZ1', 'POLT', 'NIFTA5',
                'NIFTA10', 'NICI10', 'NICI2', 'FURTFR4', 'DCTO2', 'BISTH5', 'DNENTTG', 'FELTS10',
                'INDT1', 'INDT4', 'ISOIP', 'ISOT4', 'ISOT8', 'TRITA1', 'VERI2', 'VERTA8',
                'VERTS2', 'ZEST2', 'FUROD', 'AMLT1', 'AMLT5', 'LODT', 'APRTV1',
                'APRTV3', 'APRTVH1', 'APRTVH3', 'ATET1', 'ATET2', 'ATET5', 'CONT2', 'CONTC',
                'COVT4', 'COZT', 'COZT1', 'DCTTG', 'HERI', 'HERT1', 'HERT2', 'HERT3',
                'HERT6', 'HERT9', 'HYZT', 'MODT', 'NATTS', 'NIFTD1', 'NIFTD2', 'NIFTD5', 'NITT1',
                'ZEST1', 'ZEST5', 'FELTD2', 'FELTD1', 'FELTD5', 'NIFTD3', 'CADT', 'CADT40',
                'TRITC', 'COVT8', 'HYZT1', 'OLMT2', 'EXFT5', 'EXFT10', 'BLOTPH16', 'LOSTT100',
                'OLMTP20', 'OLMTP40', 'PERTC4', 'ZANT20', 'VERTV40', 'LOSTL50', 'NIFTN5', 'NIFTN10', 'DILTP12',
                'CANT16', 'BIST25', 'UNIT8', 'VALTD16', 'FURIT', 'FUROSU', 'DILTD6', 'DNNICI2', 'DNNICI10',
                'CAPTGZ', 'PROTB1', 'PROTB4', 'MANTN1', 'NEBTB', 'IRBTB3', 'IRBTB15', 'AMLTP5', 'BISTS25',
                'OLMTE2', 'OLMTE4', 'NEWHS', 'ADAT1', 'ADAT2', 'ADAT5', 'AMLTD', 'LAST20', 'LIST2',
                'NATTR', 'YYAMLT10', 'YYCOAT150', 'YYENAT20')
    AND d.drug_exposure_start_date BETWEEN '2013-06-01' AND '2023-12-31'
    GROUP BY d.person_id, d.drug_exposure_start_date, d.drug_source_value
), -- Full generic names drug list is available in doc/steps.md

p_info AS ( -- Get patients info
    SELECT p.person_id, p.year_of_birth
    FROM cdm.person p
)

SELECT d.person_id,
       d.drug_source_value,
         d.first_drug_start_date,
       (YEAR(d.first_drug_start_date) - p.year_of_birth) AS age_at_first_drug
FROM drug_order d
JOIN p_info p ON d.person_id = p.person_id
WHERE d.rn = 1

    


