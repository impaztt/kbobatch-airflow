UPDATE kbo_stat.tb_pick b
JOIN kbo_stat.tb_betman_sd_game_result a 
ON (
    a.game_number COLLATE utf8mb4_general_ci = b.game_number COLLATE utf8mb4_general_ci
    AND a.league COLLATE utf8mb4_general_ci = b.league COLLATE utf8mb4_general_ci 
    AND a.year COLLATE utf8mb4_general_ci = b.year COLLATE utf8mb4_general_ci 
    AND a.sport_type COLLATE utf8mb4_general_ci = b.sport_type COLLATE utf8mb4_general_ci 
    AND a.bet_option COLLATE utf8mb4_general_ci = b.bet_option COLLATE utf8mb4_general_ci 
    AND a.home_team COLLATE utf8mb4_general_ci = b.home_team COLLATE utf8mb4_general_ci
    AND a.away_team COLLATE utf8mb4_general_ci = b.away_team COLLATE utf8mb4_general_ci
    AND a.round COLLATE utf8mb4_general_ci = b.round COLLATE utf8mb4_general_ci
	
AND b.PICK_ID >= '18'
    AND b.pick_result = '경기 전'
    AND a.game_result <> '경기전'
) 
SET 
    b.pick_result = (
        CASE WHEN   a.game_result COLLATE utf8mb4_general_ci = '취소' THEN '취소'
 
            WHEN b.kbo_pick COLLATE utf8mb4_general_ci = a.game_result COLLATE utf8mb4_general_ci 
            THEN '적중' 
            ELSE '비적중' 
        END
    ),
    b.update_dt = NOW(),
    b.game_result = a.game_result;
