BEGIN
    ------------------------------------------------------------------
    -- Central submit handler for timeframe and date range logic
    --
    -- This process delegates all calculations to the
    -- ADMI_UTIL_PKG.pr_get_DATE_RANGE procedure.
    --
    -- It handles:
    -- - Timeframe clicks (Day / Week / Month / Quarter / Year)
    -- - Timeframe detail navigation (including PREV / NEXT)
    -- - Manual date range input via CUSTOM_SEARCH
    ------------------------------------------------------------------

    ADMI_UTIL_PKG.pr_get_DATE_RANGE(
          pi_timeframe_item_name        => 'P1410_TIMEFRAME'
        , pi_timeframe_detail_item_name => 'P1410_TIMEFRAME_DETAIL'
        , pi_request                    => :REQUEST
        , pio_start_date                => :P1410_START_DATE
        , pio_end_date                  => :P1410_END_DATE
        , pio_timeframe                 => :P1410_TIMEFRAME
        , pio_timeframe_detail          => :P1410_TIMEFRAME_DETAIL
    );

END;
