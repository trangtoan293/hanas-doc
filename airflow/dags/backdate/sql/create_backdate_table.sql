DROP TABLE IF EXISTS LakeHouse.landing.gl_poc_backdate;

CREATE TABLE LakeHouse.landing.gl_poc_backdate USING iceberg AS 
SELECT 
    EOD_DATE, 
    CAST(EOD_DATE - INTERVAL 5 DAYS AS TIMESTAMP) as value_date,
    POS_CD, 
    AC_NO, 
    case when DR_CR_FLG = 'D' then 'C' else 'D' end as DR_CR_FLG, 
    LCY_AMT * NUM_DUPLICATES as LCY_AMT, 
    FCY_AMT * NUM_DUPLICATES as FCY_AMT
FROM LakeHouse.landing.gl_poc_streaming
WHERE EOD_DATE BETWEEN date'{{ params.start_date }}' AND date'{{ params.end_date }}';
