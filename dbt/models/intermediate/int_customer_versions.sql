-- Type 2 history for customers, built with the reusable macro.
-- Tracked as Type 2: city, state, loyalty_tier. Everything else is Type 1.
{{ scd2_from_change_log(
    current_relation=ref('stg_cascade__customers'),
    changes_relation=ref('stg_cascade__customer_changes'),
    natural_key='customer_id',
    tracked_columns=['city', 'state', 'loyalty_tier'],
    passthrough_columns=['first_name', 'last_name', 'full_name', 'email', 'birth_date', 'annual_income']
) }}
