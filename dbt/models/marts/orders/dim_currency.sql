select
    {{ dbt_utils.generate_surrogate_key(['column1']) }} as currency_key,
    column1 as currency_code,
    column2 as currency_name
from values ('USD', 'US Dollar'), ('CAD', 'Canadian Dollar'), ('EUR', 'Euro')
