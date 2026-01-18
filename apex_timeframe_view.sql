  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_P1410_TIMEFRAME_DETAIL" ("DISPLAY_VALUE", "RETURN_VALUE") AS 
  WITH params AS (
    SELECT
        v('P1410_TIMEFRAME') AS tf
      , TRUNC(
            TO_DATE(
                v('P1410_START_DATE')
              , 'DD.MM.YYYY'
            )
        ) AS v_start_date
      , ( SELECT value
            FROM nls_session_parameters
           WHERE parameter = 'NLS_DATE_LANGUAGE'
        ) AS nls_lang
    FROM dual
),
days AS (
    SELECT
        TRUNC(p.v_start_date, 'IW') + (LEVEL - 1) AS day_ref
      , LEVEL AS sort_order
    FROM params p
    CONNECT BY LEVEL <= 7
),
week_base AS (
    SELECT TRUNC(v_start_date, 'IW') AS base_week
    FROM params
),
month_base AS (
    SELECT TRUNC(v_start_date, 'MM') AS base_month
    FROM params
),
levels7 AS (
    SELECT LEVEL AS lvl
    FROM dual
    CONNECT BY LEVEL <= 7
)
SELECT
    display_value
  , return_value
FROM (

    ------------------------------------------------------------------
    -- DAY (DD.MM.YYYY)
    ------------------------------------------------------------------
    SELECT
        '⮜'                                   AS display_value
      , 'PREV_WEEK'                           AS return_value
      , 0                                     AS sort_order
    FROM params
    WHERE tf = 'D'

    UNION ALL

    SELECT
        INITCAP(
            TO_CHAR(day_ref,'Day','NLS_DATE_LANGUAGE='||p.nls_lang)
        ) || ' (' || TO_CHAR(day_ref,'DD.MM.YYYY') || ')'
      , TO_CHAR(day_ref,'DD.MM.YYYY')
      , d.sort_order
    FROM days d
    CROSS JOIN params p
    WHERE p.tf = 'D'

    UNION ALL

    SELECT
        '⮞'
      , 'NEXT_WEEK'
      , 8
    FROM params
    WHERE tf = 'D'


    ------------------------------------------------------------------
    -- WEEK (WW.YYYY)
    ------------------------------------------------------------------
    UNION ALL

    SELECT
        '⮜'
      , 'PREV_WEEK'
      , 0
    FROM params
    WHERE tf = 'W'

    UNION ALL

    SELECT
        'Week ' ||
        TO_CHAR(base_week + ((lvl - 4) * 7),'IW') ||
        ' (' || TO_CHAR(base_week + ((lvl - 4) * 7),'IYYY') || ')'
      , TO_CHAR(base_week + ((lvl - 4) * 7),'IW') || '.' ||
        TO_CHAR(base_week + ((lvl - 4) * 7),'IYYY')
      , lvl
    FROM week_base
       , levels7
       , params
    WHERE tf = 'W'

    UNION ALL

    SELECT
        '⮞'
      , 'NEXT_WEEK'
      , 8
    FROM params
    WHERE tf = 'W'


    ------------------------------------------------------------------
    -- MONTH (MM.YYYY)
    ------------------------------------------------------------------
    UNION ALL

    SELECT
        '⮜'
      , 'PREV_MONTH'
      , 0
    FROM params
    WHERE tf = 'M'

    UNION ALL

    SELECT
        TO_CHAR(
            ADD_MONTHS(base_month, lvl - 4)
          , 'Mon'
          , 'NLS_DATE_LANGUAGE='||p.nls_lang
        ) || ' ' ||
        TO_CHAR(ADD_MONTHS(base_month, lvl - 4),'YYYY')
      , TO_CHAR(ADD_MONTHS(base_month, lvl - 4),'MM.YYYY')
      , lvl
    FROM month_base
       , levels7
       , params p
    WHERE tf = 'M'

    UNION ALL

    SELECT
        '⮞'
      , 'NEXT_MONTH'
      , 8
    FROM params
    WHERE tf = 'M'


    ------------------------------------------------------------------
    -- QUARTER (Q.YYYY)
    ------------------------------------------------------------------
    UNION ALL

    SELECT
        '⮜'
      , 'PREV_QUARTER'
      , 0
    FROM params
    WHERE tf = 'Q'

    UNION ALL

    SELECT
        'Q' || q.lvl || ' / ' || y.base_year
      , q.lvl || '.' || y.base_year
      , q.lvl
    FROM (
        SELECT TO_NUMBER(TO_CHAR(v_start_date,'YYYY')) AS base_year
        FROM params
    ) y
       , (
        SELECT LEVEL AS lvl FROM dual CONNECT BY LEVEL <= 4
    ) q
       , params
    WHERE tf = 'Q'

    UNION ALL

    SELECT
        '⮞'
      , 'NEXT_QUARTER'
      , 5
    FROM params
    WHERE tf = 'Q'


    ------------------------------------------------------------------
    -- YEAR (YYYY)
    ------------------------------------------------------------------
    UNION ALL

    SELECT
        '⮜'
      , 'PREV_YEAR'
      , 0
    FROM params
    WHERE tf = 'Y'

    UNION ALL

    SELECT
        TO_CHAR(base_year + (lvl - 4))
      , TO_CHAR(base_year + (lvl - 4))
      , lvl
    FROM (
        SELECT TO_NUMBER(TO_CHAR(v_start_date,'YYYY')) AS base_year
        FROM params
    )
       , (
        SELECT LEVEL AS lvl FROM dual CONNECT BY LEVEL <= 7
    )
       , params
    WHERE tf = 'Y'

    UNION ALL

    SELECT
        '⮞'
      , 'NEXT_YEAR'
      , 8
    FROM params
    WHERE tf = 'Y'

)
ORDER BY
    sort_order;
