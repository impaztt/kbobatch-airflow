

UPDATE kbo_stat.tb_pick A
JOIN kbo_stat.tb_betman_sd_game_now B
  ON A.YEAR COLLATE utf8mb4_unicode_ci = B.YEAR COLLATE utf8mb4_unicode_ci
 AND A.ROUND COLLATE utf8mb4_unicode_ci = B.ROUND COLLATE utf8mb4_unicode_ci
 AND A.GAME_NUMBER COLLATE utf8mb4_unicode_ci = B.GAME_NUMBER COLLATE utf8mb4_unicode_ci
 AND A.LEAGUE COLLATE utf8mb4_unicode_ci = B.LEAGUE COLLATE utf8mb4_unicode_ci
 AND A.SPORT_TYPE COLLATE utf8mb4_unicode_ci = B.SPORT_TYPE COLLATE utf8mb4_unicode_ci
 AND A.BET_OPTION COLLATE utf8mb4_unicode_ci = B.BET_OPTION COLLATE utf8mb4_unicode_ci
SET A.GAME_DATE = B.GAME_DATE
WHERE A.GAME_DATE IS NULL;

