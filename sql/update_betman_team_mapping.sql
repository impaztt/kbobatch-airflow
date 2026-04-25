UPDATE kbo_stat.tb_betman_sd_game_result a
JOIN kbo_stat.tb_team_mapping b
  ON a.home_team COLLATE utf8mb4_unicode_ci
     = b.team_name_before COLLATE utf8mb4_unicode_ci
 AND (
      a.league COLLATE utf8mb4_unicode_ci
        = b.league_name COLLATE utf8mb4_unicode_ci
      OR
      a.league COLLATE utf8mb4_unicode_ci
        = b.league_name_before COLLATE utf8mb4_unicode_ci
 )
SET 
    a.home_team = b.team_name,
    a.league = b.league_name
WHERE a.game_date < '2026-04-22';


UPDATE kbo_stat.tb_betman_sd_game_result a
JOIN kbo_stat.tb_team_mapping b
  ON a.away_team COLLATE utf8mb4_unicode_ci
     = b.team_name_before COLLATE utf8mb4_unicode_ci
 AND (
      a.league COLLATE utf8mb4_unicode_ci
        = b.league_name COLLATE utf8mb4_unicode_ci
      OR
      a.league COLLATE utf8mb4_unicode_ci
        = b.league_name_before COLLATE utf8mb4_unicode_ci
 )
SET 
    a.away_team = b.team_name,
    a.league = b.league_name
WHERE a.game_date < '2026-04-22';
