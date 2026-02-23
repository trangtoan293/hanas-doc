select
    explode(
        sequence(
            to_date('2024-01-01'), 
            current_date(), 
            interval 1 day
        )
    ) as snapshot_ts
