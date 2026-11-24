{#
  The date dimension. Kimball: every fact table has at least one date
  foreign key, and every date attribute an analyst might filter or group by
  (fiscal periods, holidays, day-of-week names) belongs HERE, computed once,
  not recomputed with SQL date functions in every query.

  Cascade Outfitters' fiscal year starts on February 1 (common in retail).
#}

{%- set start_date = modules.datetime.date.fromisoformat(var('date_dim_start')) -%}
{%- set end_date = modules.datetime.date.fromisoformat(var('date_dim_end')) -%}
{%- set day_count = (end_date - start_date).days + 1 %}

-- Snowflake's generator() produces N rows; row_number() makes the sequence
-- gap-free (seq4() alone is not guaranteed to be contiguous).
with days as (
    select
        dateadd(day, row_number() over (order by seq4()) - 1, '{{ start_date }}'::date) as date_day
    from table(generator(rowcount => {{ day_count }}))
),

holidays as (
    -- A real implementation would source this from a maintained calendar table.
    select column1::date as holiday_date, column2 as holiday_name
    from values
        ('2025-01-01', 'New Year''s Day'),
        ('2025-05-26', 'Memorial Day'),
        ('2025-07-04', 'Independence Day'),
        ('2025-09-01', 'Labor Day'),
        ('2025-11-27', 'Thanksgiving'),
        ('2025-12-25', 'Christmas Day')
),

enriched as (
    select
        {{ date_key('d.date_day') }}                      as date_key,
        d.date_day                                         as full_date,
        dayname(d.date_day)                                as day_of_week_abbr,
        decode(dayofweekiso(d.date_day),
            1, 'Monday', 2, 'Tuesday', 3, 'Wednesday', 4, 'Thursday',
            5, 'Friday', 6, 'Saturday', 7, 'Sunday')       as day_of_week_name,
        dayofweekiso(d.date_day)                           as day_number_in_week,
        day(d.date_day)                                    as day_number_in_month,
        dayofyear(d.date_day)                              as day_number_in_year,
        weekiso(d.date_day)                                as iso_week_number,
        date_trunc('week', d.date_day)                     as week_start_date,
        month(d.date_day)                                  as month_number,
        monthname(d.date_day)                              as month_abbr,
        to_char(d.date_day, 'YYYY-MM')                     as year_month,
        date_trunc('month', d.date_day)                    as month_start_date,
        last_day(d.date_day)                               as month_end_date,
        quarter(d.date_day)                                as calendar_quarter,
        year(d.date_day) || '-Q' || quarter(d.date_day)    as calendar_year_quarter,
        year(d.date_day)                                   as calendar_year,

        -- Fiscal calendar (FY starts Feb 1; FY2025 = Feb 2025 .. Jan 2026)
        year(dateadd(month, -1, d.date_day))               as fiscal_year,
        month(dateadd(month, -1, d.date_day))              as fiscal_month_number,
        ceil(month(dateadd(month, -1, d.date_day)) / 3)    as fiscal_quarter,
        'FY' || year(dateadd(month, -1, d.date_day))
            || '-Q' || ceil(month(dateadd(month, -1, d.date_day)) / 3) as fiscal_year_quarter,

        -- Indicators: spell them out. 'Weekend' reads better on a report than TRUE.
        iff(dayofweekiso(d.date_day) in (6, 7), 'Weekend', 'Weekday') as weekday_indicator,
        iff(h.holiday_date is not null, 'Holiday', 'Non-Holiday')    as holiday_indicator,
        coalesce(h.holiday_name, 'None')                              as holiday_name,
        iff(d.date_day = last_day(d.date_day), 'Month End', 'Not Month End') as month_end_indicator
    from days as d
    left join holidays as h on h.holiday_date = d.date_day
)

select * from enriched

union all

-- Special rows. Facts with an unknown or not-yet-happened date point here
-- (e.g. ship_date_key on an order that has not shipped).
select
    -1, null, 'N/A', 'Unknown', null, null, null, null, null, null, null, 'Unknown',
    null, null, null, 'Unknown', null, null, null, null, 'Unknown',
    'Unknown', 'Unknown', 'None', 'Unknown'
union all
select
    -2, null, 'N/A', 'Not Yet Happened', null, null, null, null, null, null, null, 'Not Yet',
    null, null, null, 'Not Yet', null, null, null, null, 'Not Yet',
    'Not Yet', 'Not Yet', 'None', 'Not Yet'
