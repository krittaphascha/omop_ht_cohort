import json
import pandas as pd

'''
# Python code to generate SQL query
output
- patient_id with their corresponding first_date of diagnosis or drug

use create_combined_conditions_query or create_combined_drugs_query to generate a SQL code
arguments:
1. dictionary of diagnosis {'diag_name': condition_concept_id} or of drug {'drug_name': [list of codes]}
2. list of person_id in this cohort

(dictionary will be obtain from .json file in the same folder)

'''

def create_inclusion_query(drug_list):
    drug_list = tuple(drug_list)
    with open('./sql/inclusion.sql', 'r') as f:
        inclusion_query = f.read()
    inclusion_query = inclusion_query.replace('INSERT_DRUG_TUPLE', str(drug_list))
    return inclusion_query

def create_combined_conditions_query(conditions, inclusion_cte_name='inclusion'):
    select_query = """SELECT """

    for condition, code in conditions.items():
        condition_query = f"\n  MIN(CASE WHEN ca.ancestor_concept_id = {code} THEN c.condition_start_date END) AS first_{condition}_date,"
        select_query += condition_query
    select_query += '\n p.person_id\n'
    
    from_query = f"""FROM omop.person p
        INNER JOIN {inclusion_cte_name} i ON p.person_id = i.person_id
        LEFT JOIN omop.condition_occurrence c ON p.person_id = c.person_id
        LEFT JOIN omop.concept_ancestor ca ON c.condition_concept_id = ca.descendant_concept_id
        WHERE ca.ancestor_concept_id IN {tuple(conditions.values())}
        GROUP BY p.person_id
    """

    query = select_query + from_query
    
    return query

def get_drug_group(df):
    drug_class_dict = {}

    # List of columns to consider for drug classes
    drug_class_columns = ['drug_class_main', 'drug_class_secondary', 'drug_class_secondary_2']

    for column in drug_class_columns:
        for drug_class, group in df.groupby(column):
            if drug_class not in drug_class_dict:
                drug_class_dict[drug_class] = []
            drug_class_dict[drug_class].extend(group['DRUG_CODE'].tolist())

    # Remove duplicates from each list in the dictionary
    for drug_class in drug_class_dict:
        drug_class_dict[drug_class] = list(set(drug_class_dict[drug_class]))

    return drug_class_dict

def create_combined_drugs_query(drug_dict, inclusion_cte_name='inclusion'):
    select_query = "SELECT "
    
    # Creating SELECT part of query with conditionally aggregated first dates for various drugs.
    for drug_category, drug_codes in drug_dict.items():
        drug_codes_tuple = tuple(drug_codes) if len(drug_codes) > 1 else f"('{drug_codes[0]}')"
        condition_query = f"\n  MIN(CASE WHEN d.drug_source_value IN {drug_codes_tuple} THEN d.drug_exposure_start_date END) AS first_{drug_category}_date,"
        select_query += condition_query
    select_query += '\n p.person_id\n'
    
    # FROM and JOIN part of the query.
    from_query = f"FROM omop.person p\nINNER JOIN {inclusion_cte_name} i ON i.person_id = p.person_id \nLEFT JOIN omop.drug_exposure d ON p.person_id = d.person_id"
    # Constructing WHERE clause with dynamic IN conditions for all drug codes.
    all_drug_codes = []
    for codes in drug_dict.values():
        all_drug_codes.extend(codes)
    all_drug_codes = tuple(set(all_drug_codes))  # Ensuring unique values for IN clause.
    
    where_query = f"\nWHERE d.drug_source_value IN {all_drug_codes}\n"
    
    # GROUP BY part of the query to summarize data per person.
    group_by_query = "GROUP BY p.person_id\n"
    
    # Combining parts of the query.
    query = select_query + from_query + where_query + group_by_query
    
    return query

def create_exclusion_query(exclusion_pair):
    exclusion_query = ",\nexclusion AS (SELECT dl.person_id,\n"
    
    # if diagnosis before drug given, this should be mark as 1
    for exclusion in exclusion_pair.items():
        for drug in exclusion[1]:
            exclusion_query += f"""CASE WHEN first_{str(exclusion[0])}_date <= first_{drug}_date THEN 1 ELSE 0 END AS {str(exclusion[0])}_{drug},\n"""
    exclusion_query = exclusion_query[:-2] # remove the last comma
    exclusion_query += '\nFROM diag_list dl JOIN drug_list dr ON dl.person_id = dr.person_id\n)'
    return exclusion_query

if __name__ == "__main__":

    
    with open("data/diagnosis_dict.json", 'r') as f:
        diagnosis_dict = json.load(f)
    with open('data/exclusion_pair.json', 'r') as f:
        exclusion_pair = json.load(f)

    drug_tables = pd.read_csv("data/antiht_master.csv")

    drug_list = drug_tables['DRUG_CODE'].unique()
    drug_dict = get_drug_group(drug_tables)

    inclusion_query = create_inclusion_query(drug_list)
    full_query = inclusion_query+'\n'
    full_query += 'diag_list AS (\n'
    full_query += create_combined_conditions_query(diagnosis_dict)
    full_query += '),\n'
    full_query += 'drug_list AS (\n'
    full_query += create_combined_drugs_query(drug_dict)
    full_query += ')\n'
    full_query += create_exclusion_query(exclusion_pair)
    full_query += """,summary AS (SELECT 
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
        AND NOT (criteria = 'drug' AND total_exclusion > 0);"""

    with open("sql/cohort_construction.sql", 'w') as f:
        f.write(full_query)