

INSERT INTO kbo_stat.tb_pick
SELECT
    (SELECT IFNULL(MAX(PICK_ID), 0) + 1 FROM kbo_stat.tb_pick) AS PICK_SEQ,
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
    NULL,
    NULL
FROM (
    SELECT
        A.PAY_ID,
        A.USER_ID,
        A.PROD_ID,
        B.GAME_NUMBER,
        B.LEAGUE,
        B.ROUND,
        B.KBO_PICK,
        B.SPORT_TYPE,
        B.BET_OPTION,
        B.ALLOCATION_WIN,
        B.ALLOCATION_DRAW,
        B.ALLOCATION_LOSE,
        B.HOME_TEAM,
        B.AWAY_TEAM
    FROM (
        SELECT
            PAY_ID,
            USER_ID,
            PROD_ID,
            PROD_NM,
            PRICE,
            PICK_MP,
            PICK_CNT,
            REMAIN_PICK_CNT,
            PAY_DT
        FROM (
            SELECT
                A.PAY_ID,
                A.USER_ID,
                A.PROD_ID,
                B.PROD_NM,
                B.PRICE,
                B.PICK_MP,
                A.PICK_CNT,
                IFNULL(B.PICK_CNT - IFNULL(C.CNT, 0), 0) AS REMAIN_PICK_CNT,
                A.PAY_DT
            FROM kbo_stat.tb_pay_hist A
            LEFT JOIN kbo_stat.tb_prod_list B
                ON A.PROD_ID = B.PROD_ID
            LEFT JOIN (
                SELECT
                    USER_ID,
                    PROD_ID,
                    PAY_ID,
                    COUNT(1) AS CNT
                FROM kbo_stat.tb_pick
                WHERE KBO_PICK IS NOT NULL
AND GAME_RESULT <> '취소'                
GROUP BY
                    USER_ID,
                    PROD_ID,
                    PAY_ID
            ) C
                ON A.PROD_ID = C.PROD_ID
               AND A.USER_ID = C.USER_ID
               AND A.PAY_ID = C.PAY_ID
            WHERE A.STATUS = 'PAID'
        ) PAY_TARGET
        WHERE REMAIN_PICK_CNT > 0
          AND PAY_ID > 53
    ) A
    JOIN (
        SELECT
            GAME_NUMBER,
            SPORT_TYPE,
            LEAGUE,
            ROUND,
            BET_OPTION,
            CASE
                WHEN WINLEAGUEHITRATE BETWEEN 0.60 AND 0.99 THEN '승'
                WHEN LOSELEAGUEHITRATE BETWEEN 0.60 AND 0.99 THEN '패'
                ELSE NULL
            END AS KBO_PICK,
            HOME_TEAM,
            AWAY_TEAM,
            ALLOCATION_WIN,
            ALLOCATION_DRAW,
            ALLOCATION_LOSE,
            WINLEAGUEHITRATE,
            DRAWLEAGUEHITRATE,
            LOSELEAGUEHITRATE
        FROM kbo_stat.tb_betman_sd_game_anal_allocation
        WHERE (
                WINLEAGUEHITRATE BETWEEN 0.60 AND 0.99
             OR LOSELEAGUEHITRATE BETWEEN 0.60 AND 0.99
        )
          AND BET_OPTION IN ('핸디캡', '일반')
    ) B
        ON 1 = 1
    WHERE A.PICK_MP < 3.5

      /* 픽 방향과 배당 조건을 맞춤 */
      AND (
            (B.KBO_PICK = '승' AND A.PICK_MP <= B.ALLOCATION_WIN)
         OR (B.KBO_PICK = '패' AND A.PICK_MP <= B.ALLOCATION_LOSE)
      )

      /* 핵심: 같은 유저에게 이미 지급된 동일 픽은 제외 */
      AND NOT EXISTS (
          SELECT 1
          FROM kbo_stat.tb_pick P
          WHERE P.USER_ID = A.USER_ID
            AND P.YEAR = '2026'

            AND P.ROUND COLLATE utf8mb4_unicode_ci
                = B.ROUND COLLATE utf8mb4_unicode_ci

            AND P.GAME_NUMBER COLLATE utf8mb4_unicode_ci
                = B.GAME_NUMBER COLLATE utf8mb4_unicode_ci

            AND P.LEAGUE COLLATE utf8mb4_unicode_ci
                = B.LEAGUE COLLATE utf8mb4_unicode_ci

            AND P.SPORT_TYPE COLLATE utf8mb4_unicode_ci
                = B.SPORT_TYPE COLLATE utf8mb4_unicode_ci

            AND P.BET_OPTION COLLATE utf8mb4_unicode_ci
                = B.BET_OPTION COLLATE utf8mb4_unicode_ci

            AND P.KBO_PICK COLLATE utf8mb4_unicode_ci
                = B.KBO_PICK COLLATE utf8mb4_unicode_ci

            AND P.KBO_PICK IS NOT NULL
      )
    ORDER BY RAND()
    LIMIT 1
) X;

