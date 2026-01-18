DECLARE
    -- Anchor date used for timeframe detail (current system date)
    v_s DATE := SYSDATE;
BEGIN
    ------------------------------------------------------------------
    -- Initial start filter handling (Rendering / Before Header)
    --
    -- This block initializes the date range when a predefined
    -- start option is selected (e.g. "Start with current month").
    ------------------------------------------------------------------

    IF :P1410_FILTER_START_OPTION = 'START_CURRENT_MONTH' THEN

        ------------------------------------------------------------------
        -- Set start date to first day of the current month
        ------------------------------------------------------------------
        :P1410_START_DATE :=
            TO_CHAR(
                TRUNC(SYSDATE, 'MM')
              , 'DD.MM.YYYY'
            );

        ------------------------------------------------------------------
        -- Set end date to last day of the current month
        ------------------------------------------------------------------
        :P1410_END_DATE :=
            TO_CHAR(
                LAST_DAY(SYSDATE)
              , 'DD.MM.YYYY'
            );

        ------------------------------------------------------------------
        -- Initialize timeframe context
        ------------------------------------------------------------------
        :P1410_TIMEFRAME        := 'M';          -- Month
        :P1410_TIMEFRAME_DETAIL := TO_CHAR(v_s, 'MM.YYYY');

        ------------------------------------------------------------------
        -- Reset start option to avoid re-triggering
        ------------------------------------------------------------------
        :P1410_FILTER_START_OPTION := NULL;

    END IF;
END;
