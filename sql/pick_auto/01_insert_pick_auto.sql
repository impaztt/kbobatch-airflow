b_pick 
		SELECT
    X.PICK_SEQ,
    X.PAY_ID,
    X.USER_ID,
    X.PROD_ID,
    1,
    1,
    'PAID',
    '2026',
    X.ROUND,
    X.GAME_NUMBER,
    X.LEAGUE,
    X.SPORT_TYPE,
    X.BET_OPTION,
    X.ALLOCATION_WIN,
    X.ALLOCATION_DRAW,
    X.ALLOCATION_LOSE,
    X.HOME_TEAM,
    X.AWAY_TEAM,
    X.KBO_PICK,
    '경기 전',
    'N',
    NOW(),
    NOW(),
    null,
    NULL
FROM (
    /* =========================================================
       1) PICK_MP < 2.00 : 기존 1픽 로직 그대로
       ========================================================= */
    SELECT
        S.PICK_SEQ AS PICK_SEQ,
        S.PAY_ID,
        S.USER_ID,
        S.PROD_ID,
        S.GAME_NUMBER,
        S.LEAGUE,
        S.ROUND,
        S.KBO_PICK,
        S.SPORT_TYPE,
        S.BET_OPTION,
        S.ALLOCATION_WIN,
        S.ALLOCATION_DRAW,
        S.ALLOCATION_LOSE,
        S.HOME_TEAM,
        S.AWAY_TEAM
    FROM (
        SELECT
            A.PICK_SEQ,
            A.PAY_ID,
            A.USER_ID,
            A.PROD_ID,
            KBO_PICK,
            B.GAME_NUMBER,
            B.LEAGUE,
            B.ROUND,
            B.SPORT_TYPE,
            B.BET_OPTION,
            B.ALLOCATION_WIN,
            B.ALLOCATION_DRAW,
            B.ALLOCATION_LOSE,
            B.HOME_TEAM,
            B.AWAY_TEAM
        FROM (
            /* ===== 원본 A 그대로 ===== */
            SELECT PAY_ID,USER_ID,PROD_ID,PROD_NM,PRICE,PICK_MP,PICK_CNT,잔여픽개수,PAY_DT,PICK_SEQ 
            FROM (
                SELECT
                    A.PAY_ID,
                    A.USER_ID,
                    A.PROD_ID,
                    B.PROD_NM,
                    B.PRICE,
                    B.PICK_MP,
                    A.PICK_CNT,
                    IFNULL(B.PICK_CNT - IFNULL(C.CNT,0),0) AS 잔여픽개수,
                    A.PAY_DT, 
                    MAX(PICK_SEQ) OVER  () + ROW_NUMBER() OVER (ORDER BY PICK_SEQ)   AS PICK_SEQ
                   
                FROM kbo_stat.tb_pay_hist A
                LEFT OUTER JOIN kbo_stat.tb_prod_list B
                    ON A.PROD_ID = B.PROD_ID
                LEFT OUTER JOIN (
                    SELECT
                        USER_ID,
                        PROD_ID,
                        PAY_ID,
                        CNT,
                        MAX(PICK_SEQ) OVER () AS PICK_SEQ
                    FROM (
                        SELECT
                            USER_ID,
                            PROD_ID,
                            PAY_ID,
                            COUNT(1) AS CNT,
                            MAX(PICK_ID) AS PICK_SEQ
                        FROM kbo_stat.tb_pick
                        WHERE KBO_PICK IS NOT NULL
                        GROUP BY
                            USER_ID,
                            PROD_ID,
                            PAY_ID
                    ) A
                ) C
                    ON ( A.PROD_ID = C.PROD_ID
                   AND A.USER_ID = C.USER_ID
                   AND A.PAY_ID = C.PAY_ID)
                   WHERE A.STATUS = 'PAID'            
                   ) A
            WHERE ( 잔여픽개수 <> 0 or 잔여픽개수 > 0 )
              AND PAY_ID > 53
              
              
                        
        ) A,
        (
            /* ===== 원본 B 그대로 ===== */
            SELECT
                GAME_NUMBER,
                SPORT_TYPE,
                LEAGUE,
                ROUND,
                BET_OPTION,
                CASE WHEN A.WINLEAGUEHITRATE BETWEEN 0.60 AND 0.99 THEN '승'
                     WHEN A.LOSELEAGUEHITRATE BETWEEN 0.60 AND 0.99 THEN '패' ELSE NULL END  AS KBO_PICK,
                     
                HOME_TEAM,
                AWAY_TEAM,
                ALLOCATION_WIN,
                ALLOCATION_DRAW,
                ALLOCATION_LOSE,
                WINLEAGUEHITRATE,
                DRAWLEAGUEHITRATE,
                LOSELEAGUEHITRATE
            FROM kbo_stat.tb_betman_sd_game_anal_allocation A
            WHERE ( A.WINLEAGUEHITRATE BETWEEN 0.60 AND 0.99 
                 or A.LOSELEAGUEHITRATE BETWEEN 0.60 AND 0.99)
              AND A.BET_OPTION IN ('핸디캡', '일반')
            ORDER BY A.WINLEAGUEHITRATE DESC
        ) B
        WHERE A.PICK_MP < 3.5
           AND ( A.PICK_MP <= B.ALLOCATION_WIN
         or   A.PICK_MP <= B.ALLOCATION_LOSE )   
         ORDER BY RAND()
        LIMIT 1
     ) S
) X;
