DELETE FROM kbo_stat.tb_match_result WHERE DATE_FORMAT(game_date, '%Y%m%d') = DATE_FORMAT(CURDATE(), '%Y%m%d');
