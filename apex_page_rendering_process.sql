DECLARE
    -- Anchor dates for initial rendering
    v_start_date VARCHAR2(10);
    v_end_date   VARCHAR2(10);
BEGIN
    ------------------------------------------------------------------
    -- Initial start filter handling (Rendering / Before Header)
    --
    -- Delegates the initial date setup to the central
    -- timeframe engine using a custom search request.
    ------------------------------------------------------------------

    IF :P1410_FILTER_START_OPTION = 'START_CURRENT_MONTH' THEN

        ------------------------------------------------------------------
        -- Prepare initial date range (current month)
        ------------------------------------------------------------------
        v_start_date := TO_CHAR(TRUNC(SYSDATE, 'MM'), 'DD.MM.YYYY');
        v_end_date   := TO_CHAR(LAST_DAY(SYSDATE), 'DD.MM.YYYY');

        ------------------------------------------------------------------
        -- Delegate logic to central timeframe engine
        ------------------------------------------------------------------
        ADMI_UTIL_PKG.pr_get_DATE_RANGE(
              pi_timeframe_item_name        => 'P1410_TIMEFRAME'
            , pi_timeframe_detail_item_name => 'P1410_TIMEFRAME_DETAIL'
            , pi_request                    => 'CUSTOM_SEARCH'
            , pio_start_date                => v_start_date
            , pio_end_date                  => v_end_date
            , pio_timeframe                 => :P1410_TIMEFRAME
            , pio_timeframe_detail          => :P1410_TIMEFRAME_DETAIL
        );

        ------------------------------------------------------------------
        -- Write back calculated dates
        ------------------------------------------------------------------
        :P1410_START_DATE := v_start_date;
        :P1410_END_DATE   := v_end_date;

        ------------------------------------------------------------------
        -- Reset start option to avoid re-triggering
        ------------------------------------------------------------------
        :P1410_FILTER_START_OPTION := NULL;

    END IF;
END;
