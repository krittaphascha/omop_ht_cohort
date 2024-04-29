
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

def create_combined_conditions_query(conditions, person_id_list):
    select_query = """SELECT """

    for condition, code in conditions.items():
        condition_query = f"\n  MIN(CASE WHEN ca.ancestor_concept_id = {code} THEN c.condition_start_date END) AS first_{condition}_date,"
        select_query += condition_query
    select_query += '\n p.person_id\n'
    
    from_query = f"""FROM cdm.person p
LEFT JOIN cdm.condition_occurrence c ON p.person_id = c.person_id
LEFT JOIN vocab.concept_ancestor ca ON c.condition_concept_id = ca.descendant_concept_id
WHERE ca.ancestor_concept_id IN {tuple(conditions.values())}
AND p.person_id in {tuple(person_id_list)}
GROUP BY p.person_id
    """

    query = select_query + from_query
    
    return query


def create_combined_drugs_query(drug_exposures, person_id_list):
    select_query = "SELECT "
    
    # Creating SELECT part of query with conditionally aggregated first dates for various drugs.
    for drug_category, drug_codes in drug_exposures.items():
        drug_codes_tuple = tuple(drug_codes)
        condition_query = f"\n  MIN(CASE WHEN d.drug_source_value IN {drug_codes_tuple} THEN d.drug_exposure_start_date END) AS first_{drug_category}_date,"
        select_query += condition_query
    select_query += '\n p.person_id\n'
    
    # FROM and JOIN part of the query.
    from_query = """FROM cdm.person p\nLEFT JOIN cdm.drug_exposure d ON p.person_id = d.person_id"""
    # Constructing WHERE clause with dynamic IN conditions for all drug codes.
    all_drug_codes = []
    for codes in drug_exposures.values():
        all_drug_codes.extend(codes)
    all_drug_codes = tuple(set(all_drug_codes))  # Ensuring unique values for IN clause.
    
    where_query = f"\nWHERE d.drug_source_value IN {all_drug_codes}\n"
    

    where_query += f"AND p.person_id IN {tuple(person_id_list)}\n"
    
    # GROUP BY part of the query to summarize data per person.
    group_by_query = "GROUP BY p.person_id\n"
    
    # Combining parts of the query.
    query = select_query + from_query + where_query + group_by_query
    
    return query