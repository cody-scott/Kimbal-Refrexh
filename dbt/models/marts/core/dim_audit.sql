{{ config(materialized='incremental', unique_key='audit_key', full_refresh=false) }}
{#
  AUDIT DIMENSION (Kimball): describes the load process that produced a fact row.

  In dbt, one load = one invocation. Each run inserts one row describing
  itself; fact tables stamp `audit_key = invocation_id` on every row they
  write, so any fact row can be traced to the run, code version and target
  that produced it.

  Incremental (append-only): this table IS the run history, so it must never
  be rebuilt from scratch. Treat it like a snapshot.
#}
select
    '{{ invocation_id }}'                                              as audit_key,
    '{{ run_started_at.strftime("%Y-%m-%d %H:%M:%S") }}'::timestamp_ntz as run_started_at_utc,
    '{{ target.name }}'                                                as target_name,
    '{{ dbt_version }}'                                                as dbt_version,
    '{{ env_var("DBT_GIT_SHA", "unknown") }}'                          as git_sha,
    '{{ env_var("DBT_JOB_NAME", "manual") }}'                          as job_name,
    {{ 'true' if flags.FULL_REFRESH else 'false' }}                    as is_full_refresh
