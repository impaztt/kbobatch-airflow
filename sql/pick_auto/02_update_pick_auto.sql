

update  kbo_stat.tb_pick a 
join kbo_stat.tb_betman_sd_game_now b
on ( a.year COLLATE utf8mb4_unicode_ci= b.year  COLLATE utf8mb4_unicode_ci
and a.round COLLATE utf8mb4_unicode_ci = b.round COLLATE utf8mb4_unicode_ci 
and a.GAME_NUMBER COLLATE utf8mb4_unicode_ci  = b.game_number COLLATE utf8mb4_unicode_ci 
and a.league COLLATE utf8mb4_unicode_ci  = b.league COLLATE utf8mb4_unicode_ci
and a.SPORT_TYPE  COLLATE utf8mb4_unicode_ci  =b.SPORT_TYPE 
and a.bet_option COLLATE utf8mb4_unicode_ci  = b.bet_option COLLATE utf8mb4_unicode_ci 
) 
set a.game_date = b.game_date
where a.game_date is null
;
