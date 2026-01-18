create or replace package util_pkg as

    procedure pr_get_date_range (
      pi_timeframe_item_name             in varchar2
    , pi_timeframe_detail_item_name      in varchar2 
    , pi_request                         in varchar2
    , pio_start_date                     in out varchar2
    , pio_end_date                       in out varchar2
    , pio_timeframe                      in out varchar2
    , pio_timeframe_detail               in out varchar2
);
  
end util_pkg;
/


create or replace package body util_pkg as

PROCEDURE pr_get_date_range (
    pi_timeframe_item_name        IN VARCHAR2
  , pi_timeframe_detail_item_name IN VARCHAR2
  , pi_request                    IN VARCHAR2
  , pio_start_date                IN OUT VARCHAR2
  , pio_end_date                  IN OUT VARCHAR2
  , pio_timeframe                 IN OUT VARCHAR2
  , pio_timeframe_detail          IN OUT VARCHAR2
)
IS
    ------------------------------------------------------------------
    -- Session / Input values
    ------------------------------------------------------------------
    v_timeframe           VARCHAR2(10);    -- D / W / M / Q / Y
    v_detail              VARCHAR2(50);    -- canonical detail (e.g. 01.2026)

    ------------------------------------------------------------------
    -- Derived / working dates
    ------------------------------------------------------------------
    v_anchor_date         DATE;            -- anchor derived from detail
    v_start_date          DATE;
    v_end_date            DATE;

    ------------------------------------------------------------------
    -- Parsed components (used per timeframe)
    ------------------------------------------------------------------
    v_year                NUMBER;
    v_month               NUMBER;
    v_week                NUMBER;
    v_quarter             NUMBER;

    ------------------------------------------------------------------
    -- Navigation helpers (← / →)
    ------------------------------------------------------------------
    v_direction            VARCHAR2(20);   -- PREV / NEXT (optional)
    v_step                 NUMBER;         -- step size (days/months)
    
    ------------------------------------------------------------------
    -- Range helpers
    ------------------------------------------------------------------
    v_days                NUMBER;
BEGIN
             -- RAISE_APPLICATION_ERROR(-20001, 'value: ' || pi_request);

    ------------------------------------------------------------------
    -- 1) Read current session state
    ------------------------------------------------------------------
    v_timeframe := apex_util.get_session_state(pi_timeframe_item_name);
    v_detail    := apex_util.get_session_state(pi_timeframe_detail_item_name);

    ------------------------------------------------------------------
    -- 2) TIMEFRAME clicked (Day / Week / Month / ...)
    ------------------------------------------------------------------
    IF pi_request = pi_timeframe_item_name THEN

        ------------------------------------------------------------------
        -- RULES:
        -- - Never use SYSDATE
        -- - Prefer existing DETAIL if present
        -- - If DETAIL is NULL → build a default detail
        ------------------------------------------------------------------

        CASE v_timeframe

            WHEN 'D' THEN

                ------------------------------------------------------------------
                -- DAY selected via TIMEFRAME click  
                -- - Always reset to TODAY
                -- - Ignore any existing timeframe detail
                ------------------------------------------------------------------

                v_anchor_date := TRUNC(SYSDATE);

                v_start_date := v_anchor_date;
                v_end_date   := v_anchor_date;

                v_detail := TO_CHAR(v_anchor_date, 'DD.MM.YYYY');

                ------------------------------------------------------------------
                -- Output
                ------------------------------------------------------------------
                pio_start_date       := TO_CHAR(v_start_date, 'DD.MM.YYYY');
                pio_end_date         := TO_CHAR(v_end_date,   'DD.MM.YYYY');
                pio_timeframe_detail := v_detail;

                ------------------------------------------------------------------
                -- Persist detail
                ------------------------------------------------------------------
                apex_util.set_session_state(
                    pi_timeframe_detail_item_name
                  , v_detail
                );

            WHEN 'W' THEN

                ------------------------------------------------------------------
                -- WEEK selected via TIMEFRAME click 
                -- - Always reset to CURRENT ISO WEEK
                -- - Ignore any existing timeframe detail
                ------------------------------------------------------------------

                -- Anchor = today
                v_anchor_date := TRUNC(SYSDATE);

                -- Normalize to Monday of ISO week
                v_start_date := TRUNC(v_anchor_date, 'IW');
                v_end_date   := v_start_date + 6;

                -- Build timeframe detail: WW.YYYY
                v_week  := TO_NUMBER(TO_CHAR(v_anchor_date, 'IW'));
                v_year  := TO_NUMBER(TO_CHAR(v_anchor_date, 'YYYY'));

                v_detail := LPAD(v_week, 2, '0') || '.' || v_year;

                ------------------------------------------------------------------
                -- Output
                ------------------------------------------------------------------
                pio_start_date       := TO_CHAR(v_start_date, 'DD.MM.YYYY');
                pio_end_date         := TO_CHAR(v_end_date,   'DD.MM.YYYY');
                pio_timeframe_detail := v_detail;

                ------------------------------------------------------------------
                -- Persist detail
                ------------------------------------------------------------------
                apex_util.set_session_state(
                    pi_timeframe_detail_item_name
                  , v_detail
                );

            WHEN 'M' THEN

                ------------------------------------------------------------------
                -- MONTH selected via TIMEFRAME click 
                -- - Always reset to CURRENT MONTH
                -- - Ignore any existing timeframe detail
                ------------------------------------------------------------------

                -- Anchor = today
                v_anchor_date := TRUNC(SYSDATE);

                -- Month boundaries
                v_start_date := TRUNC(v_anchor_date, 'MM');
                v_end_date   := LAST_DAY(v_anchor_date);

                -- Build timeframe detail: MM.YYYY
                v_month := TO_NUMBER(TO_CHAR(v_anchor_date, 'MM'));
                v_year  := TO_NUMBER(TO_CHAR(v_anchor_date, 'YYYY'));

                v_detail := LPAD(v_month, 2, '0') || '.' || v_year;

                ------------------------------------------------------------------
                -- Output
                ------------------------------------------------------------------
                pio_start_date       := TO_CHAR(v_start_date, 'DD.MM.YYYY');
                pio_end_date         := TO_CHAR(v_end_date,   'DD.MM.YYYY');
                pio_timeframe_detail := v_detail;

                ------------------------------------------------------------------
                -- Persist detail
                ------------------------------------------------------------------
                apex_util.set_session_state(
                    pi_timeframe_detail_item_name
                  , v_detail
                );

            WHEN 'Q' THEN

                ------------------------------------------------------------------
                -- QUARTER selected via TIMEFRAME click 
                -- - Always reset to CURRENT QUARTER
                -- - Ignore any existing timeframe detail
                ------------------------------------------------------------------

                -- Anchor = today
                v_anchor_date := TRUNC(SYSDATE);

                -- Determine current quarter and year
                v_quarter := TO_NUMBER(TO_CHAR(v_anchor_date, 'Q'));
                v_year    := TO_NUMBER(TO_CHAR(v_anchor_date, 'YYYY'));

                -- Quarter boundaries
                CASE v_quarter
                    WHEN 1 THEN
                        v_start_date := TO_DATE('01.01.' || v_year, 'DD.MM.YYYY');
                        v_end_date   := TO_DATE('31.03.' || v_year, 'DD.MM.YYYY');
                    WHEN 2 THEN
                        v_start_date := TO_DATE('01.04.' || v_year, 'DD.MM.YYYY');
                        v_end_date   := TO_DATE('30.06.' || v_year, 'DD.MM.YYYY');
                    WHEN 3 THEN
                        v_start_date := TO_DATE('01.07.' || v_year, 'DD.MM.YYYY');
                        v_end_date   := TO_DATE('30.09.' || v_year, 'DD.MM.YYYY');
                    WHEN 4 THEN
                        v_start_date := TO_DATE('01.10.' || v_year, 'DD.MM.YYYY');
                        v_end_date   := TO_DATE('31.12.' || v_year, 'DD.MM.YYYY');
                END CASE;

                -- Build timeframe detail: Q.YYYY
                v_detail := v_quarter || '.' || v_year;

                ------------------------------------------------------------------
                -- Output
                ------------------------------------------------------------------
                pio_start_date       := TO_CHAR(v_start_date, 'DD.MM.YYYY');
                pio_end_date         := TO_CHAR(v_end_date,   'DD.MM.YYYY');
                pio_timeframe_detail := v_detail;

                ------------------------------------------------------------------
                -- Persist detail
                ------------------------------------------------------------------
                apex_util.set_session_state(
                    pi_timeframe_detail_item_name
                  , v_detail
                );

            WHEN 'Y' THEN
                ------------------------------------------------------------------
                -- YEAR selected via TIMEFRAME click 
                -- - Always reset to CURRENT YEAR
                -- - Ignore any existing timeframe detail
                ------------------------------------------------------------------

                -- Anchor = today
                v_anchor_date := TRUNC(SYSDATE);

                -- Determine current year
                v_year := TO_NUMBER(TO_CHAR(v_anchor_date, 'YYYY'));

                -- Year boundaries
                v_start_date := TO_DATE('01.01.' || v_year, 'DD.MM.YYYY');
                v_end_date   := TO_DATE('31.12.' || v_year, 'DD.MM.YYYY');

                -- Build timeframe detail: YYYY
                v_detail := TO_CHAR(v_year);

                ------------------------------------------------------------------
                -- Output
                ------------------------------------------------------------------
                pio_start_date       := TO_CHAR(v_start_date, 'DD.MM.YYYY');
                pio_end_date         := TO_CHAR(v_end_date,   'DD.MM.YYYY');
                pio_timeframe_detail := v_detail;

                ------------------------------------------------------------------
                -- Persist detail
                ------------------------------------------------------------------
                apex_util.set_session_state(
                    pi_timeframe_detail_item_name
                  , v_detail
                );

            ELSE
                NULL;
        END CASE;

        ------------------------------------------------------------------
        -- Write back session state if needed
        ------------------------------------------------------------------
        -- apex_util.set_session_state(pi_timeframe_detail_item_name, ...);

        RETURN;
    END IF;

    ------------------------------------------------------------------
    -- 3) TIMEFRAME DETAIL clicked (radio below)
    ------------------------------------------------------------------
    IF pi_request = pi_timeframe_detail_item_name THEN

        ------------------------------------------------------------------
        -- RULES:
        -- - v_detail is the single source of truth
        -- - Derive anchor/start/end ONLY from v_detail
        ------------------------------------------------------------------

        CASE v_timeframe

            WHEN 'D' THEN
                ------------------------------------------------------------------
                -- DAY selected via TIMEFRAME DETAIL click 
                -- Detail can be:
                -- - DD.MM.YYYY   (direct day pick)
                -- - PREV_WEEK    (navigate -7 days)
                -- - NEXT_WEEK    (navigate +7 days)
                --
                -- Anchor = current START_DATE
                ------------------------------------------------------------------

                ------------------------------------------------------------------
                -- Navigation: PREV / NEXT
                ------------------------------------------------------------------
                IF v_detail IN ('PREV_WEEK', 'NEXT_WEEK') THEN

                    -- Use current start date as anchor
                    IF pio_start_date IS NULL THEN
                        RETURN;
                    END IF;

                    v_anchor_date := TO_DATE(pio_start_date, 'DD.MM.YYYY');

                    IF v_detail = 'PREV_WEEK' THEN
                        v_anchor_date := v_anchor_date - 7;
                    ELSE
                        v_anchor_date := v_anchor_date + 7;
                    END IF;

                    -- Build new detail
                    v_detail := TO_CHAR(v_anchor_date, 'DD.MM.YYYY');

                ------------------------------------------------------------------
                -- Direct day pick
                ------------------------------------------------------------------
                ELSIF REGEXP_LIKE(v_detail, '^[0-9]{2}\.[0-9]{2}\.[0-9]{4}$') THEN

                    v_anchor_date := TO_DATE(v_detail, 'DD.MM.YYYY');

                ELSE
                    -- Invalid detail value
                    RETURN;
                END IF;

                ------------------------------------------------------------------
                -- Output (DAY = single date)
                ------------------------------------------------------------------
                v_start_date := v_anchor_date;
                v_end_date   := v_anchor_date;

                pio_start_date       := TO_CHAR(v_start_date, 'DD.MM.YYYY');
                pio_end_date         := TO_CHAR(v_end_date,   'DD.MM.YYYY');
                pio_timeframe_detail := v_detail;

            WHEN 'W' THEN

                ------------------------------------------------------------------
                -- WEEK selected via TIMEFRAME DETAIL click 
                -- Detail can be:
                -- - WW.YYYY     (direct week pick)
                -- - PREV_WEEK   (navigate -1 week)
                -- - NEXT_WEEK   (navigate +1 week)
                --
                -- Anchor = current START_DATE (Monday)
                ------------------------------------------------------------------

                ------------------------------------------------------------------
                -- Navigation: PREV / NEXT
                ------------------------------------------------------------------
                IF v_detail IN ('PREV_WEEK', 'NEXT_WEEK') THEN

                    -- Use current start date as anchor (Monday of current week)
                    IF pio_start_date IS NULL THEN
                        RETURN;
                    END IF;

                    v_anchor_date := TO_DATE(pio_start_date, 'DD.MM.YYYY');

                    IF v_detail = 'PREV_WEEK' THEN
                        v_anchor_date := v_anchor_date - 7;
                    ELSE
                        v_anchor_date := v_anchor_date + 7;
                    END IF;

                    -- Normalize to Monday of ISO week
                    v_anchor_date := TRUNC(v_anchor_date, 'IW');

                    -- Build new detail WW.YYYY
                    v_week := TO_NUMBER(TO_CHAR(v_anchor_date, 'IW'));
                    v_year := TO_NUMBER(TO_CHAR(v_anchor_date, 'IYYY'));

                    v_detail := LPAD(v_week, 2, '0') || '.' || v_year;

                ------------------------------------------------------------------
                -- Direct week pick: WW.YYYY
                ------------------------------------------------------------------
                ELSIF REGEXP_LIKE(v_detail, '^[0-9]{2}\.[0-9]{4}$') THEN

                    v_week := TO_NUMBER(SUBSTR(v_detail, 1, 2));
                    v_year := TO_NUMBER(SUBSTR(v_detail, 4, 4));

                    v_anchor_date :=
                        TRUNC(
                            TO_DATE(v_year || '0104', 'YYYYMMDD')
                          , 'IW'
                        ) + (v_week - 1) * 7;

                ELSE
                    -- Invalid detail value
                    RETURN;
                END IF;

                ------------------------------------------------------------------
                -- Output (ISO week = Mon .. Sun)
                ------------------------------------------------------------------
                v_start_date := v_anchor_date;
                v_end_date   := v_anchor_date + 6;

                pio_start_date       := TO_CHAR(v_start_date, 'DD.MM.YYYY');
                pio_end_date         := TO_CHAR(v_end_date,   'DD.MM.YYYY');
                pio_timeframe_detail := v_detail;

            WHEN 'M' THEN
                ------------------------------------------------------------------
                -- MONTH selected via TIMEFRAME DETAIL click
                -- Detail can be:
                -- - MM.YYYY      (direct month pick)
                -- - PREV_MONTH   (navigate -1 month)
                -- - NEXT_MONTH   (navigate +1 month)
                --
                -- Anchor = current START_DATE (first day of month)
                ------------------------------------------------------------------

                ------------------------------------------------------------------
                -- Navigation: PREV / NEXT
                ------------------------------------------------------------------
                IF v_detail IN ('PREV_MONTH', 'NEXT_MONTH') THEN

                    -- Use current start date as anchor
                    IF pio_start_date IS NULL THEN
                        RETURN;
                    END IF;

                    v_anchor_date := TO_DATE(pio_start_date, 'DD.MM.YYYY');

                    IF v_detail = 'PREV_MONTH' THEN
                        v_anchor_date := ADD_MONTHS(v_anchor_date, -1);
                    ELSE
                        v_anchor_date := ADD_MONTHS(v_anchor_date, 1);
                    END IF;

                    -- Normalize to first day of month
                    v_anchor_date := TRUNC(v_anchor_date, 'MM');

                    -- Build new detail MM.YYYY
                    v_month := TO_NUMBER(TO_CHAR(v_anchor_date, 'MM'));
                    v_year  := TO_NUMBER(TO_CHAR(v_anchor_date, 'YYYY'));

                    v_detail := LPAD(v_month, 2, '0') || '.' || v_year;

                ------------------------------------------------------------------
                -- Direct month pick: MM.YYYY
                ------------------------------------------------------------------
                ELSIF REGEXP_LIKE(v_detail, '^[0-9]{2}\.[0-9]{4}$') THEN

                    v_month := TO_NUMBER(SUBSTR(v_detail, 1, 2));
                    v_year  := TO_NUMBER(SUBSTR(v_detail, 4, 4));

                    -- First day of selected month
                    v_anchor_date :=
                        TO_DATE(
                            '01.' || LPAD(v_month, 2, '0') || '.' || v_year
                          , 'DD.MM.YYYY'
                        );

                ELSE
                    -- Invalid detail value
                    RETURN;
                END IF;

                ------------------------------------------------------------------
                -- Output (MONTH = first .. last day)
                ------------------------------------------------------------------
                v_start_date := v_anchor_date;
                v_end_date   := LAST_DAY(v_anchor_date);

                pio_start_date       := TO_CHAR(v_start_date, 'DD.MM.YYYY');
                pio_end_date         := TO_CHAR(v_end_date,   'DD.MM.YYYY');
                pio_timeframe_detail := v_detail;

            WHEN 'Q' THEN

                ------------------------------------------------------------------
                -- QUARTER selected via TIMEFRAME DETAIL click
                -- Detail can be:
                -- - Q.YYYY        (direct quarter pick)
                -- - PREV_QUARTER  (navigate -1 quarter)
                -- - NEXT_QUARTER  (navigate +1 quarter)
                --
                -- Anchor = current START_DATE (first day of quarter)
                ------------------------------------------------------------------

                ------------------------------------------------------------------
                -- Navigation: PREV / NEXT
                ------------------------------------------------------------------
                IF v_detail IN ('PREV_QUARTER', 'NEXT_QUARTER') THEN

                    -- Use current start date as anchor
                    IF pio_start_date IS NULL THEN
                        RETURN;
                    END IF;

                    v_anchor_date := TO_DATE(pio_start_date, 'DD.MM.YYYY');

                    IF v_detail = 'PREV_QUARTER' THEN
                        v_anchor_date := ADD_MONTHS(v_anchor_date, -3);
                    ELSE
                        v_anchor_date := ADD_MONTHS(v_anchor_date, 3);
                    END IF;

                    -- Normalize to first day of quarter
                    v_anchor_date :=
                        TRUNC(
                            ADD_MONTHS(
                                TRUNC(v_anchor_date, 'YYYY')
                              , (TO_NUMBER(TO_CHAR(v_anchor_date, 'Q')) - 1) * 3
                            )
                          , 'MM'
                        );

                    -- Build new detail Q.YYYY
                    v_quarter := TO_NUMBER(TO_CHAR(v_anchor_date, 'Q'));
                    v_year    := TO_NUMBER(TO_CHAR(v_anchor_date, 'YYYY'));

                    v_detail := v_quarter || '.' || v_year;

                ------------------------------------------------------------------
                -- Direct quarter pick: Q.YYYY
                ------------------------------------------------------------------
                ELSIF REGEXP_LIKE(v_detail, '^[1-4]\.[0-9]{4}$') THEN

                    v_quarter := TO_NUMBER(SUBSTR(v_detail, 1, 1));
                    v_year    := TO_NUMBER(SUBSTR(v_detail, 3, 4));

                    -- First day of selected quarter
                    v_anchor_date :=
                        ADD_MONTHS(
                            TO_DATE('01.01.' || v_year, 'DD.MM.YYYY')
                          , (v_quarter - 1) * 3
                        );

                ELSE
                    -- Invalid detail value
                    RETURN;
                END IF;

                ------------------------------------------------------------------
                -- Output (QUARTER = first .. last day)
                ------------------------------------------------------------------
                v_start_date := v_anchor_date;
                v_end_date   := ADD_MONTHS(v_anchor_date, 3) - 1;

                pio_start_date       := TO_CHAR(v_start_date, 'DD.MM.YYYY');
                pio_end_date         := TO_CHAR(v_end_date,   'DD.MM.YYYY');
                pio_timeframe_detail := v_detail;

            WHEN 'Y' THEN

                ------------------------------------------------------------------
                -- YEAR selected via TIMEFRAME DETAIL click
                -- Detail can be:
                -- - YYYY        (direct year pick)
                -- - PREV_YEAR   (navigate -1 year)
                -- - NEXT_YEAR   (navigate +1 year)
                --
                -- Anchor = current START_DATE (01.01.YYYY)
                ------------------------------------------------------------------

                ------------------------------------------------------------------
                -- Navigation: PREV / NEXT
                ------------------------------------------------------------------
                IF v_detail IN ('PREV_YEAR', 'NEXT_YEAR') THEN

                    -- Use current start date as anchor
                    IF pio_start_date IS NULL THEN
                        RETURN;
                    END IF;

                    v_anchor_date := TO_DATE(pio_start_date, 'DD.MM.YYYY');

                    IF v_detail = 'PREV_YEAR' THEN
                        v_anchor_date := ADD_MONTHS(v_anchor_date, -12);
                    ELSE
                        v_anchor_date := ADD_MONTHS(v_anchor_date, 12);
                    END IF;

                    -- Normalize to first day of year
                    v_year := TO_NUMBER(TO_CHAR(v_anchor_date, 'YYYY'));
                    v_anchor_date := TO_DATE('01.01.' || v_year, 'DD.MM.YYYY');

                    -- Build new detail YYYY
                    v_detail := TO_CHAR(v_year);

                ------------------------------------------------------------------
                -- Direct year pick: YYYY
                ------------------------------------------------------------------
                ELSIF REGEXP_LIKE(v_detail, '^[0-9]{4}$') THEN

                    v_year := TO_NUMBER(v_detail);

                    -- First day of selected year
                    v_anchor_date := TO_DATE('01.01.' || v_year, 'DD.MM.YYYY');

                ELSE
                    -- Invalid detail value
                    RETURN;
                END IF;

                ------------------------------------------------------------------
                -- Output (YEAR = full year)
                ------------------------------------------------------------------
                v_start_date := v_anchor_date;
                v_end_date   := TO_DATE('31.12.' || TO_CHAR(v_year), 'DD.MM.YYYY');

                pio_start_date       := TO_CHAR(v_start_date, 'DD.MM.YYYY');
                pio_end_date         := TO_CHAR(v_end_date,   'DD.MM.YYYY');
                pio_timeframe_detail := v_detail;

            ELSE
                NULL;
        END CASE;

        ------------------------------------------------------------------
        -- Output handling (common)
        ------------------------------------------------------------------
        -- pio_start_date := TO_CHAR(v_start_date,'DD.MM.YYYY');
        -- pio_end_date   := TO_CHAR(v_end_date,'DD.MM.YYYY');

        RETURN;
    END IF;



------------------------------------------------------------------
-- CUSTOM SEARCH (manual date range → auto-detect best timeframe)
------------------------------------------------------------------
IF pi_request LIKE '%CUSTOM_SEARCH%' THEN

    ------------------------------------------------------------------
    -- Validate input
    ------------------------------------------------------------------
    IF pio_start_date IS NULL
       OR pio_end_date IS NULL
    THEN
        RETURN;
    END IF;

    v_start_date := TO_DATE(pio_start_date, 'DD.MM.YYYY');
    v_end_date   := TO_DATE(pio_end_date,   'DD.MM.YYYY');

    -- ensure correct order
    IF v_end_date < v_start_date THEN
        RETURN;
    END IF;

    v_days := v_end_date - v_start_date + 1;

    ------------------------------------------------------------------
    -- 1) EXACT MATCHES (highest priority)
    ------------------------------------------------------------------

    -- Single day
    IF v_days = 1 THEN

        pio_timeframe        := 'D';
        pio_timeframe_detail := TO_CHAR(v_start_date, 'DD.MM.YYYY');

    -- Exact ISO week (Mon–Sun)
    ELSIF v_start_date = TRUNC(v_start_date, 'IW')
      AND v_end_date   = TRUNC(v_start_date, 'IW') + 6
    THEN
        pio_timeframe := 'W';

        pio_timeframe_detail :=
            LPAD(TO_CHAR(v_start_date,'IW'),2,'0') || '.' ||
            TO_CHAR(v_start_date,'IYYY');

    -- Exact month
    ELSIF v_start_date = TRUNC(v_start_date, 'MM')
      AND v_end_date   = LAST_DAY(v_start_date)
    THEN
        pio_timeframe := 'M';
        pio_timeframe_detail := TO_CHAR(v_start_date,'MM.YYYY');

    -- Exact quarter
    ELSIF v_start_date =
            ADD_MONTHS(
                TRUNC(v_start_date,'YYYY')
              , (TO_NUMBER(TO_CHAR(v_start_date,'Q')) - 1) * 3
            )
      AND v_end_date =
            ADD_MONTHS(
                ADD_MONTHS(
                    TRUNC(v_start_date,'YYYY')
                  , (TO_NUMBER(TO_CHAR(v_start_date,'Q')) - 1) * 3
                )
              , 3
            ) - 1
    THEN
        pio_timeframe := 'Q';
        pio_timeframe_detail :=
            TO_CHAR(v_start_date,'Q') || '.' ||
            TO_CHAR(v_start_date,'YYYY');

    -- Exact year
    ELSIF v_start_date = TO_DATE('01.01.' || TO_CHAR(v_start_date,'YYYY'),'DD.MM.YYYY')
      AND v_end_date   = TO_DATE('31.12.' || TO_CHAR(v_start_date,'YYYY'),'DD.MM.YYYY')
    THEN
        pio_timeframe := 'Y';
        pio_timeframe_detail := TO_CHAR(v_start_date,'YYYY');

    ------------------------------------------------------------------
    -- 2) BEST-FIT HEURISTIC (UX-friendly)
    ------------------------------------------------------------------
    ELSE

        ------------------------------------------------------------------
        -- Inside a single ISO week → WEEK
        ------------------------------------------------------------------
        IF TRUNC(v_start_date,'IW') = TRUNC(v_end_date,'IW') THEN

            pio_timeframe := 'W';
            pio_timeframe_detail :=
                LPAD(TO_CHAR(v_start_date,'IW'),2,'0') || '.' ||
                TO_CHAR(v_start_date,'IYYY');

        ------------------------------------------------------------------
        -- Inside a single month → MONTH
        ------------------------------------------------------------------
        ELSIF TRUNC(v_start_date,'MM') = TRUNC(v_end_date,'MM') THEN

            pio_timeframe := 'M';
            pio_timeframe_detail := TO_CHAR(v_start_date,'MM.YYYY');

        ------------------------------------------------------------------
        -- Inside a single quarter → QUARTER
        ------------------------------------------------------------------
        ELSIF TO_CHAR(v_start_date,'YYYYQ') = TO_CHAR(v_end_date,'YYYYQ') THEN

            pio_timeframe := 'Q';
            pio_timeframe_detail :=
                TO_CHAR(v_start_date,'Q') || '.' ||
                TO_CHAR(v_start_date,'YYYY');

        ------------------------------------------------------------------
        -- Spans multiple quarters but within one year → YEAR
        ------------------------------------------------------------------
        ELSIF TO_CHAR(v_start_date,'YYYY') = TO_CHAR(v_end_date,'YYYY') THEN

            pio_timeframe := 'Y';
            pio_timeframe_detail := TO_CHAR(v_start_date,'YYYY');

        ------------------------------------------------------------------
        -- Spans multiple years → YEAR (use start year as anchor)
        ------------------------------------------------------------------
        ELSE
            pio_timeframe := 'Y';
            pio_timeframe_detail := TO_CHAR(v_start_date,'YYYY');
        END IF;

    END IF;

    ------------------------------------------------------------------
    -- Persist session state
    ------------------------------------------------------------------
    apex_util.set_session_state(pi_timeframe_item_name,        pio_timeframe);
    apex_util.set_session_state(pi_timeframe_detail_item_name, pio_timeframe_detail);

    RETURN;
END IF;





END pr_get_date_range;



end UTIL_PKG;
/


