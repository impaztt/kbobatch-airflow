delete from kbo_stat.tb_kbl_today_bet where schd_ymd = DATE_FORMAT(CURDATE(), '%Y%m%d');

INSERT INTO  kbo_stat.tb_match_result
WITH BALANCE AS 
(
SELECT A.TEAMCODE, SUM(100점환산), ROUND( ( SUM(100점환산) - 300 ) / 300 , 3 ) +1  AS RATE
FROM 
(
-- 1
 SELECT * 
 FROM (
   WITH RecentGames AS (
      SELECT 
          home_team_code,
          winner,
          ROW_NUMBER() OVER (
              PARTITION BY home_team_code
              ORDER BY STR_TO_DATE(game_date, '%Y-%m-%d') DESC
          ) AS rn
      FROM tb_game_info
  )
  SELECT 
      a.home_team_code AS teamCode, '1 최근경기승리' AS SEQ , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) AS winCount , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) * 10 AS 100점환산
  FROM RecentGames a
  JOIN tb_team_info b
    ON a.home_team_code = b.team_code
  WHERE a.rn <= 10
  AND a.home_team_code = 'SS'
  GROUP BY a.home_team_code 
 ) A

 
  UNION ALL 
 -- 2
 SELECT *
 FROM (
  WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and  ( a_code = 'SS' OR h_code  = 'SS' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ) ,
 
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
 ),
 
 
 SCORE_RESULT AS (
 
 select a.*,b.*,'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.home_id
 and b.h_code <> 'SS'
 
 union all
 
 select a.*,b.*,'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.away_id
 and b.a_code <> 'SS'
 
 )
  
 SELECT 'SS' AS teamCode , '2 타율'  AS SEQ ,  round( sum(hit) / sum(ab), 3)   ,  round( sum(hit) / sum(ab), 3) * 3.3 * 100 
 from SCORE_RESULT  a  
 ) A 
 
 UNION ALL
 -- 3
 SELECT *
 FROM (
 WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and ( a_code = 'SS' OR h_code  = 'SS' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ),
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
  
  
 ),
 
 SCORE_RESULT AS (
 
 select a.*,b.*, 'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE b
 where a.id = b.home_id
 and b.h_code = 'SS'
 
 union all
 
 select a.*,b.*, 'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE  b
 where a.id = b.away_id
 and b.a_code = 'SS'
 
 )
   
 SELECT 'SS', '3 방어율', ROUND( (SUM(er) / SUM(inn)) * 9 , 2) AS 전체방어율  , 100- ( ROUND( (SUM(er) / SUM(inn)) * 9 , 2) - 3.85 ) * 15  AS 100점환산 
 from SCORE_RESULT  a   
 ) A
 
 UNION ALL 
 -- 4
 SELECT *
 FROM 
 ( 
 WITH param AS (
     SELECT  
         home_team_code ,
         away_team_code 
     FROM tb_game_info  a 
     WHERE home_team_code = 'SS'
     AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y-%m-%d') = a.game_date
     
 ),
 -- ① 시즌 맞대결 : 홈/원정 모두 포함
 matchup AS (
     SELECT
         p.home_team_code,
         p.away_team_code,
         COUNT(1) AS total_games,
         -- 홈팀이 홈일 때, 홈 승리 + 원정일 때, 원정 승리 합산
         SUM(
             CASE
                 WHEN (b.team_code = p.home_team_code AND c.team_code = p.away_team_code AND winner = 'HOME') THEN 1
                 WHEN (b.team_code = p.away_team_code AND c.team_code = p.home_team_code AND winner = 'AWAY') THEN 1
                 ELSE 0
             END
         ) AS home_team_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND (
             (b.team_code = p.home_team_code AND c.team_code = p.away_team_code) OR
             (b.team_code = p.away_team_code AND c.team_code = p.home_team_code)
           )
     GROUP BY p.home_team_code, p.away_team_code
 ),
 -- ② 시즌 홈경기 승률 (전체 홈경기 기준)
 home_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_home_games,
         SUM(CASE WHEN winner = 'HOME' THEN 1 ELSE 0 END) AS home_team_home_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND b.team_code = p.home_team_code
     GROUP BY p.home_team_code
 ),
 -- ③ 시즌 원정경기 승률 (전체 원정경기 기준)
 away_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_away_games,
         SUM(CASE WHEN winner = 'AWAY' THEN 1 ELSE 0 END) AS home_team_away_wins
     FROM tb_game_info a
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND c.team_code = p.home_team_code
     GROUP BY p.home_team_code
 )
 SELECT
   p.home_team_code  AS 홈팀명,
    '4 맞대결',
 --    c.team_name AS 상대팀명, 
     ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) AS 시즌맞대결승률
     ,ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) * 100  AS 100점환산 
  
 FROM param p
 LEFT JOIN matchup m ON p.home_team_code = m.home_team_code AND p.away_team_code = m.away_team_code
 LEFT JOIN home_games h ON p.home_team_code = h.home_team_code
 LEFT JOIN away_games a ON p.home_team_code = a.home_team_code
 LEFT JOIN tb_team_info b ON p.home_team_code = b.team_code
 LEFT JOIN tb_team_info c ON p.away_team_code = c.team_code
 
 )  A 
 
 UNION ALL 
 -- 5
 
 SELECT *
 FROM 
 (
   WITH base AS (
     -- 시즌 전체 득점 데이터 (홈/원정 합산)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_score
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate  >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 득점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS home_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 득점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS away_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_score,
         RANK() OVER (ORDER BY season_avg_score DESC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_score,
         RANK() OVER (ORDER BY home_avg_score DESC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_score,
         RANK() OVER (ORDER BY away_avg_score DESC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code, 
     '5 시즌득점', 
     season_avg_score,
     case when season_avg_score >= 10 then 10 else season_avg_score end * 10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'SS'  
 ) A 
  
 UNION ALL 
 -- 6
 SELECT *
 FROM 
 (
 WITH base AS (
     -- 시즌 전체 실점 데이터 (홈/원정 구분 없음)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_loss
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 실점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS home_avg_loss
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 실점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS away_avg_loss
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_loss,
         RANK() OVER (ORDER BY season_avg_loss ASC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_loss,
         RANK() OVER (ORDER BY home_avg_loss ASC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_loss,
         RANK() OVER (ORDER BY away_avg_loss ASC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code,
     '6 시즌실점', 
     b.season_avg_loss,
     case when season_avg_loss >= 10 then 10 else season_avg_loss end * -10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'SS' -- 'LG', 'HH'
 
 ) A
 
) A
GROUP BY A.TEAMCODE

)
SELECT  A.GAME_NUMBER,
		A.game_date,
        A.BET_OPTION,
        A.HOME_TEAM,
        A.AWAY_TEAM,
        A.홈승배당,
        A.홈무배당,
        A.홈패배당,
         A.승_승률,
        A.무_승률,
        A.패_승률,
        A.전체_승_승률,
        A.전체_무_승률,
        A.전체_패_승률,
        ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) AS 홈승_보정,
        CASE WHEN A.BET_OPTION IN ('승1패','전반') THEN ROUND( 100 - (  ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) ) 
                        - ( ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ),1) ELSE NULL END AS 홈무_보정,
        CASE WHEN A.BET_OPTION IN ('일반','핸디캡','언더오버') THEN  100 - ROUND(((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100 ),1) 
          WHEN A.BET_OPTION IN ('승1패','전반')    THEN        ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ELSE NULL
        END AS 홈패_보정
FROM 
(

SELECT
            A.GAME_NUMBER,
            A.game_date,
--             A.SPORT_TYPE,
--             A.LEAGUE,
            A.BET_OPTION,
            A.HOME_TEAM,
            A.AWAY_TEAM,
            A.ALLOCATION_WIN AS 홈승배당,
            A.ALLOCATION_DRAW AS 홈무배당,
            A.ALLOCATION_LOSE AS 홈패배당,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINLEAGUETOTALGAMES,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 승_승률,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWLEAGUETOTALGAMES,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 무_승률,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSELEAGUETOTALGAMES,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSELEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 패_승률,
--            SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINTOTALGAMES,
  --          SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 ) AS 전체_승_승률,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWTOTALGAMES,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWHITGAMES,
            ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_무_승률,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSETOTALGAMES,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSEHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_패_승률,

((  ( MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_le_ev,

(( ( MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_le_ev,

( (( MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END)  ) *  A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_ev, 

(((             ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 )  ) *  A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_all_ev,
 
 
(((  ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) ) *   A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_all_ev,

(((     ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 )  ) * A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_evS


        FROM
            (
                SELECT A.GAME_NUMBER, A.SPORT_TYPE, A.LEAGUE, A.BET_OPTION, ALLOCATION_WIN, ALLOCATION_DRAW, ALLOCATION_LOSE, A.HOME_TEAM, A.AWAY_TEAM, A.game_date
                FROM kbo_stat.tb_betman_sd_game_now A , ( select  replace(B.TEAM_NAME, ' ', '')  as TEAM_NAME, TEAM_CODE from kbo_stat.tb_team_info B ) B 
                WHERE A.LEAGUE = 'KBO'
                AND A.SPORT_TYPE = '야구'
                -- AND  DATE_FORMAT(NOW()-1, '%Y%m%d') = '20250405' --   DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')-1
                AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y%m%d') =  DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')
                AND A.BET_OPTION NOT IN ( 'SUM','전반' ) 
                AND B.TEAM_CODE = 'SS'
                AND A.HOME_TEAM COLLATE utf8mb4_unicode_ci = B.TEAM_NAME
 
            ) A LEFT OUTER JOIN
            (
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '언더' AND BET_OPTION  IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '언더' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN
                UNION ALL
                
                SELECT SPORT_TYPE, BET_OPTION,LEAGUE, 0 AS ALLOCATION_WIN, ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('승패','핸디캡','승무패','전반 승무패') THEN 1
                                 WHEN GAME_RESULT IN (1, '①') AND BET_OPTION = '승1패' THEN 1
                                 WHEN GAME_RESULT IN (5, '⑤') AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('일반','핸디캡','승무패','전반 승무패') THEN 1
                                        WHEN GAME_RESULT IN  (1, '①')  AND BET_OPTION = '승1패' THEN 1
                                        WHEN GAME_RESULT IN  (5, '⑤')  AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_DRAW
                UNION ALL
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, 0 AS ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '오버' AND BET_OPTION = '언더오버' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '오버' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                 where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_LOSE
            ) B
            ON ( A.SPORT_TYPE = B.SPORT_TYPE
                AND A.BET_OPTION = B.BET_OPTION
                AND ( A.ALLOCATION_WIN = B.ALLOCATION_WIN OR A.ALLOCATION_DRAW = B.ALLOCATION_DRAW OR A.ALLOCATION_LOSE = B.ALLOCATION_LOSE )
                )

        GROUP BY A.GAME_NUMBER,
        	     A.game_date,
                 A.SPORT_TYPE,
                 A.LEAGUE,
                 A.BET_OPTION,
                 A.HOME_TEAM,
                 A.AWAY_TEAM,
                 A.ALLOCATION_WIN,
                 A.ALLOCATION_DRAW,
                 A.ALLOCATION_LOSE
ORDER BY 1
)  A, BALANCE B 
ORDER BY 1;









-- HT
INSERT INTO  kbo_stat.tb_match_result
WITH BALANCE AS 
(
SELECT A.TEAMCODE, SUM(100점환산), ROUND( ( SUM(100점환산) - 300 ) / 300 , 3 ) +1  AS RATE
FROM 
(
-- 1
 SELECT * 
 FROM (
   WITH RecentGames AS (
      SELECT 
          home_team_code,
          winner,
          ROW_NUMBER() OVER (
              PARTITION BY home_team_code
              ORDER BY STR_TO_DATE(game_date, '%Y-%m-%d') DESC
          ) AS rn
      FROM tb_game_info
  )
  SELECT 
      a.home_team_code AS teamCode, '1 최근경기승리' AS SEQ , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) AS winCount , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) * 10 AS 100점환산
  FROM RecentGames a
  JOIN tb_team_info b
    ON a.home_team_code = b.team_code
  WHERE a.rn <= 10
  AND a.home_team_code = 'HT'
  GROUP BY a.home_team_code 
 ) A

 
  UNION ALL 
 -- 2
 SELECT *
 FROM (
  WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and  ( a_code = 'HT' OR h_code  = 'HT' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ) ,
 
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
 ),
 
 
 SCORE_RESULT AS (
 
 select a.*,b.*,'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.home_id
 and b.h_code <> 'HT'
 
 union all
 
 select a.*,b.*,'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.away_id
 and b.a_code <> 'HT'
 
 )
  
 SELECT 'HT' AS teamCode , '2 타율'  AS SEQ ,  round( sum(hit) / sum(ab), 3)   ,  round( sum(hit) / sum(ab), 3) * 3.3 * 100 
 from SCORE_RESULT  a  
 ) A 
 
 UNION ALL
 -- 3
 SELECT *
 FROM (
 WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and ( a_code = 'HT' OR h_code  = 'HT' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ),
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
  
  
 ),
 
 SCORE_RESULT AS (
 
 select a.*,b.*, 'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE b
 where a.id = b.home_id
 and b.h_code = 'HT'
 
 union all
 
 select a.*,b.*, 'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE  b
 where a.id = b.away_id
 and b.a_code = 'HT'
 
 )
   
 SELECT 'HT', '3 방어율', ROUND( (SUM(er) / SUM(inn)) * 9 , 2) AS 전체방어율  , 100- ( ROUND( (SUM(er) / SUM(inn)) * 9 , 2) - 3.85 ) * 15  AS 100점환산 
 from SCORE_RESULT  a   
 ) A
 
 UNION ALL 
 -- 4
 SELECT *
 FROM 
 ( 
 WITH param AS (
     SELECT  
         home_team_code ,
         away_team_code 
     FROM tb_game_info  a 
     WHERE home_team_code = 'HT'
     AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y-%m-%d') = a.game_date
     
 ),
 -- ① 시즌 맞대결 : 홈/원정 모두 포함
 matchup AS (
     SELECT
         p.home_team_code,
         p.away_team_code,
         COUNT(1) AS total_games,
         -- 홈팀이 홈일 때, 홈 승리 + 원정일 때, 원정 승리 합산
         SUM(
             CASE
                 WHEN (b.team_code = p.home_team_code AND c.team_code = p.away_team_code AND winner = 'HOME') THEN 1
                 WHEN (b.team_code = p.away_team_code AND c.team_code = p.home_team_code AND winner = 'AWAY') THEN 1
                 ELSE 0
             END
         ) AS home_team_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND (
             (b.team_code = p.home_team_code AND c.team_code = p.away_team_code) OR
             (b.team_code = p.away_team_code AND c.team_code = p.home_team_code)
           )
     GROUP BY p.home_team_code, p.away_team_code
 ),
 -- ② 시즌 홈경기 승률 (전체 홈경기 기준)
 home_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_home_games,
         SUM(CASE WHEN winner = 'HOME' THEN 1 ELSE 0 END) AS home_team_home_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND b.team_code = p.home_team_code
     GROUP BY p.home_team_code
 ),
 -- ③ 시즌 원정경기 승률 (전체 원정경기 기준)
 away_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_away_games,
         SUM(CASE WHEN winner = 'AWAY' THEN 1 ELSE 0 END) AS home_team_away_wins
     FROM tb_game_info a
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND c.team_code = p.home_team_code
     GROUP BY p.home_team_code
 )
 SELECT
   p.home_team_code  AS 홈팀명,
    '4 맞대결',
 --    c.team_name AS 상대팀명, 
     ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) AS 시즌맞대결승률
     ,ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) * 100  AS 100점환산 
  
 FROM param p
 LEFT JOIN matchup m ON p.home_team_code = m.home_team_code AND p.away_team_code = m.away_team_code
 LEFT JOIN home_games h ON p.home_team_code = h.home_team_code
 LEFT JOIN away_games a ON p.home_team_code = a.home_team_code
 LEFT JOIN tb_team_info b ON p.home_team_code = b.team_code
 LEFT JOIN tb_team_info c ON p.away_team_code = c.team_code
 
 )  A 
 
 UNION ALL 
 -- 5
 
 SELECT *
 FROM 
 (
   WITH base AS (
     -- 시즌 전체 득점 데이터 (홈/원정 합산)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_score
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate  >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 득점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS home_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 득점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS away_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_score,
         RANK() OVER (ORDER BY season_avg_score DESC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_score,
         RANK() OVER (ORDER BY home_avg_score DESC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_score,
         RANK() OVER (ORDER BY away_avg_score DESC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code, 
     '5 시즌득점', 
     season_avg_score,
     case when season_avg_score >= 10 then 10 else season_avg_score end * 10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'HT' -- 'LG', 'HH' 
 ) A 
  
 UNION ALL 
 -- 6
 SELECT *
 FROM 
 (
 WITH base AS (
     -- 시즌 전체 실점 데이터 (홈/원정 구분 없음)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_loHT
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 실점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS home_avg_loHT
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 실점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS away_avg_loHT
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_loHT,
         RANK() OVER (ORDER BY season_avg_loHT ASC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_loHT,
         RANK() OVER (ORDER BY home_avg_loHT ASC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_loHT,
         RANK() OVER (ORDER BY away_avg_loHT ASC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code,
     '6 시즌실점', 
     b.season_avg_loHT,
     case when season_avg_loHT >= 10 then 10 else season_avg_loHT end * -10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'HT' -- 'LG', 'HH'
 
 ) A
 
) A
GROUP BY A.TEAMCODE

)
SELECT  A.GAME_NUMBER,
		A.game_date,
        A.BET_OPTION,
        A.HOME_TEAM,
        A.AWAY_TEAM,
        A.홈승배당,
        A.홈무배당,
        A.홈패배당,
         A.승_승률,
        A.무_승률,
        A.패_승률,
        A.전체_승_승률,
        A.전체_무_승률,
        A.전체_패_승률,
        ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) AS 홈승_보정,
        CASE WHEN A.BET_OPTION IN ('승1패','전반') THEN ROUND( 100 - (  ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) ) 
                        - ( ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ),1) ELSE NULL END AS 홈무_보정,
        CASE WHEN A.BET_OPTION IN ('일반','핸디캡','언더오버') THEN  100 - ROUND(((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100 ),1) 
          WHEN A.BET_OPTION IN ('승1패','전반')    THEN        ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ELSE NULL
        END AS 홈패_보정
FROM 
(

SELECT
            A.GAME_NUMBER,
            A.game_date,
--             A.SPORT_TYPE,
--             A.LEAGUE,
            A.BET_OPTION,
            A.HOME_TEAM,
            A.AWAY_TEAM,
            A.ALLOCATION_WIN AS 홈승배당,
            A.ALLOCATION_DRAW AS 홈무배당,
            A.ALLOCATION_LOSE AS 홈패배당,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINLEAGUETOTALGAMES,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 승_승률,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWLEAGUETOTALGAMES,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 무_승률,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSELEAGUETOTALGAMES,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSELEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 패_승률,
--            SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINTOTALGAMES,
  --          SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 ) AS 전체_승_승률,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWTOTALGAMES,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWHITGAMES,
            ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_무_승률,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSETOTALGAMES,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSEHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_패_승률,

((  ( MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_le_ev,

(( ( MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_le_ev,

( (( MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END)  ) *  A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_ev, 

(((             ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 )  ) *  A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_all_ev,
 
 
(((  ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) ) *   A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_all_ev,

(((     ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 )  ) * A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_evS


        FROM
            (
                SELECT A.GAME_NUMBER, A.SPORT_TYPE, A.LEAGUE, A.BET_OPTION, ALLOCATION_WIN, ALLOCATION_DRAW, ALLOCATION_LOSE, A.HOME_TEAM, A.AWAY_TEAM, A.game_date
                FROM kbo_stat.tb_betman_sd_game_now A , ( select  replace(B.TEAM_NAME, ' ', '')  as TEAM_NAME, TEAM_CODE from kbo_stat.tb_team_info B ) B 
                WHERE A.LEAGUE = 'KBO'
                AND A.SPORT_TYPE = '야구'
                -- AND  DATE_FORMAT(NOW()-1, '%Y%m%d') = '20250405' --   DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')-1
                AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y%m%d') =  DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')
                AND A.BET_OPTION NOT IN ( 'SUM','전반' ) 
                AND B.TEAM_CODE = 'HT'
                AND A.HOME_TEAM COLLATE utf8mb4_unicode_ci = B.TEAM_NAME
 
            ) A LEFT OUTER JOIN
            (
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '언더' AND BET_OPTION  IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '언더' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN
                UNION ALL
                
                SELECT SPORT_TYPE, BET_OPTION,LEAGUE, 0 AS ALLOCATION_WIN, ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('승패','핸디캡','승무패','전반 승무패') THEN 1
                                 WHEN GAME_RESULT IN (1, '①') AND BET_OPTION = '승1패' THEN 1
                                 WHEN GAME_RESULT IN (5, '⑤') AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('일반','핸디캡','승무패','전반 승무패') THEN 1
                                        WHEN GAME_RESULT IN  (1, '①')  AND BET_OPTION = '승1패' THEN 1
                                        WHEN GAME_RESULT IN  (5, '⑤')  AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_DRAW
                UNION ALL
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, 0 AS ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '오버' AND BET_OPTION = '언더오버' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '오버' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                 where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_LOSE
            ) B
            ON ( A.SPORT_TYPE = B.SPORT_TYPE
                AND A.BET_OPTION = B.BET_OPTION
                AND ( A.ALLOCATION_WIN = B.ALLOCATION_WIN OR A.ALLOCATION_DRAW = B.ALLOCATION_DRAW OR A.ALLOCATION_LOSE = B.ALLOCATION_LOSE )
                )

        GROUP BY A.GAME_NUMBER,
        	     A.game_date,
                 A.SPORT_TYPE,
                 A.LEAGUE,
                 A.BET_OPTION,
                 A.HOME_TEAM,
                 A.AWAY_TEAM,
                 A.ALLOCATION_WIN,
                 A.ALLOCATION_DRAW,
                 A.ALLOCATION_LOSE
ORDER BY 1
)  A, BALANCE B 
ORDER BY 1;



-- LG 
INSERT INTO  kbo_stat.tb_match_result
WITH BALANCE AS 
(
SELECT A.TEAMCODE, SUM(100점환산), ROUND( ( SUM(100점환산) - 300 ) / 300 , 3 ) +1  AS RATE
FROM 
(
-- 1
 SELECT * 
 FROM (
   WITH RecentGames AS (
      SELECT 
          home_team_code,
          winner,
          ROW_NUMBER() OVER (
              PARTITION BY home_team_code
              ORDER BY STR_TO_DATE(game_date, '%Y-%m-%d') DESC
          ) AS rn
      FROM tb_game_info
  )
  SELECT 
      a.home_team_code AS teamCode, '1 최근경기승리' AS SEQ , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) AS winCount , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) * 10 AS 100점환산
  FROM RecentGames a
  JOIN tb_team_info b
    ON a.home_team_code = b.team_code
  WHERE a.rn <= 10
  AND a.home_team_code = 'LG'
  GROUP BY a.home_team_code 
 ) A

 
  UNION ALL 
 -- 2
 SELECT *
 FROM (
  WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and  ( a_code = 'LG' OR h_code  = 'LG' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ) ,
 
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
 ),
 
 
 SCORE_RESULT AS (
 
 select a.*,b.*,'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.home_id
 and b.h_code <> 'LG'
 
 union all
 
 select a.*,b.*,'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.away_id
 and b.a_code <> 'LG'
 
 )
  
 SELECT 'LG' AS teamCode , '2 타율'  AS SEQ ,  round( sum(hit) / sum(ab), 3)   ,  round( sum(hit) / sum(ab), 3) * 3.3 * 100 
 from SCORE_RESULT  a  
 ) A 
 
 UNION ALL
 -- 3
 SELECT *
 FROM (
 WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and ( a_code = 'LG' OR h_code  = 'LG' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ),
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
  
  
 ),
 
 SCORE_RESULT AS (
 
 select a.*,b.*, 'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE b
 where a.id = b.home_id
 and b.h_code = 'LG'
 
 union all
 
 select a.*,b.*, 'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE  b
 where a.id = b.away_id
 and b.a_code = 'LG'
 
 )
   
 SELECT 'LG', '3 방어율', ROUND( (SUM(er) / SUM(inn)) * 9 , 2) AS 전체방어율  , 100- ( ROUND( (SUM(er) / SUM(inn)) * 9 , 2) - 3.85 ) * 15  AS 100점환산 
 from SCORE_RESULT  a   
 ) A
 
 UNION ALL 
 -- 4
 SELECT *
 FROM 
 ( 
 WITH param AS (
     SELECT  
         home_team_code ,
         away_team_code 
     FROM tb_game_info  a 
     WHERE home_team_code = 'LG'
     AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y-%m-%d') = a.game_date
     
 ),
 -- ① 시즌 맞대결 : 홈/원정 모두 포함
 matchup AS (
     SELECT
         p.home_team_code,
         p.away_team_code,
         COUNT(1) AS total_games,
         -- 홈팀이 홈일 때, 홈 승리 + 원정일 때, 원정 승리 합산
         SUM(
             CASE
                 WHEN (b.team_code = p.home_team_code AND c.team_code = p.away_team_code AND winner = 'HOME') THEN 1
                 WHEN (b.team_code = p.away_team_code AND c.team_code = p.home_team_code AND winner = 'AWAY') THEN 1
                 ELSE 0
             END
         ) AS home_team_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND (
             (b.team_code = p.home_team_code AND c.team_code = p.away_team_code) OR
             (b.team_code = p.away_team_code AND c.team_code = p.home_team_code)
           )
     GROUP BY p.home_team_code, p.away_team_code
 ),
 -- ② 시즌 홈경기 승률 (전체 홈경기 기준)
 home_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_home_games,
         SUM(CASE WHEN winner = 'HOME' THEN 1 ELSE 0 END) AS home_team_home_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND b.team_code = p.home_team_code
     GROUP BY p.home_team_code
 ),
 -- ③ 시즌 원정경기 승률 (전체 원정경기 기준)
 away_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_away_games,
         SUM(CASE WHEN winner = 'AWAY' THEN 1 ELSE 0 END) AS home_team_away_wins
     FROM tb_game_info a
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND c.team_code = p.home_team_code
     GROUP BY p.home_team_code
 )
 SELECT
   p.home_team_code  AS 홈팀명,
    '4 맞대결',
 --    c.team_name AS 상대팀명, 
     ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) AS 시즌맞대결승률
     ,ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) * 100  AS 100점환산 
  
 FROM param p
 LEFT JOIN matchup m ON p.home_team_code = m.home_team_code AND p.away_team_code = m.away_team_code
 LEFT JOIN home_games h ON p.home_team_code = h.home_team_code
 LEFT JOIN away_games a ON p.home_team_code = a.home_team_code
 LEFT JOIN tb_team_info b ON p.home_team_code = b.team_code
 LEFT JOIN tb_team_info c ON p.away_team_code = c.team_code
 
 )  A 
 
 UNION ALL 
 -- 5
 
 SELECT *
 FROM 
 (
   WITH base AS (
     -- 시즌 전체 득점 데이터 (홈/원정 합산)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_score
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate  >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 득점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS home_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 득점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS away_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_score,
         RANK() OVER (ORDER BY season_avg_score DESC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_score,
         RANK() OVER (ORDER BY home_avg_score DESC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_score,
         RANK() OVER (ORDER BY away_avg_score DESC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code, 
     '5 시즌득점', 
     season_avg_score,
     case when season_avg_score >= 10 then 10 else season_avg_score end * 10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'LG' -- 'LG', 'HH' 
 ) A 
  
 UNION ALL 
 -- 6
 SELECT *
 FROM 
 (
 WITH base AS (
     -- 시즌 전체 실점 데이터 (홈/원정 구분 없음)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_loLG
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 실점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS home_avg_loLG
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 실점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS away_avg_loLG
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_loLG,
         RANK() OVER (ORDER BY season_avg_loLG ASC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_loLG,
         RANK() OVER (ORDER BY home_avg_loLG ASC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_loLG,
         RANK() OVER (ORDER BY away_avg_loLG ASC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code,
     '6 시즌실점', 
     b.season_avg_loLG,
     case when season_avg_loLG >= 10 then 10 else season_avg_loLG end * -10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'LG' -- 'LG', 'HH'
 
 ) A
 
) A
GROUP BY A.TEAMCODE

)
SELECT  A.GAME_NUMBER,
		A.game_date,
        A.BET_OPTION,
        A.HOME_TEAM,
        A.AWAY_TEAM,
        A.홈승배당,
        A.홈무배당,
        A.홈패배당,
         A.승_승률,
        A.무_승률,
        A.패_승률,
        A.전체_승_승률,
        A.전체_무_승률,
        A.전체_패_승률,
        ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) AS 홈승_보정,
        CASE WHEN A.BET_OPTION IN ('승1패','전반') THEN ROUND( 100 - (  ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) ) 
                        - ( ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ),1) ELSE NULL END AS 홈무_보정,
        CASE WHEN A.BET_OPTION IN ('일반','핸디캡','언더오버') THEN  100 - ROUND(((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100 ),1) 
          WHEN A.BET_OPTION IN ('승1패','전반')    THEN        ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ELSE NULL
        END AS 홈패_보정
FROM 
(

SELECT
            A.GAME_NUMBER,
            A.game_date,
--             A.SPORT_TYPE,
--             A.LEAGUE,
            A.BET_OPTION,
            A.HOME_TEAM,
            A.AWAY_TEAM,
            A.ALLOCATION_WIN AS 홈승배당,
            A.ALLOCATION_DRAW AS 홈무배당,
            A.ALLOCATION_LOSE AS 홈패배당,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINLEAGUETOTALGAMES,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 승_승률,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWLEAGUETOTALGAMES,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 무_승률,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSELEAGUETOTALGAMES,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSELEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 패_승률,
--            SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINTOTALGAMES,
  --          SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 ) AS 전체_승_승률,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWTOTALGAMES,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWHITGAMES,
            ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_무_승률,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSETOTALGAMES,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSEHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_패_승률,

((  ( MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_le_ev,

(( ( MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_le_ev,

( (( MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END)  ) *  A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_ev, 

(((             ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 )  ) *  A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_all_ev,
 
 
(((  ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) ) *   A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_all_ev,

(((     ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 )  ) * A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_evS


        FROM
            (
                SELECT A.GAME_NUMBER, A.SPORT_TYPE, A.LEAGUE, A.BET_OPTION, ALLOCATION_WIN, ALLOCATION_DRAW, ALLOCATION_LOSE, A.HOME_TEAM, A.AWAY_TEAM, A.game_date
                FROM kbo_stat.tb_betman_sd_game_now A , ( select  replace(B.TEAM_NAME, ' ', '')  as TEAM_NAME, TEAM_CODE from kbo_stat.tb_team_info B ) B 
                WHERE A.LEAGUE = 'KBO'
                AND A.SPORT_TYPE = '야구'
                -- AND  DATE_FORMAT(NOW()-1, '%Y%m%d') = '20250405' --   DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')-1
                AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y%m%d') =  DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')
                AND A.BET_OPTION NOT IN ( 'SUM','전반' ) 
                AND B.TEAM_CODE = 'LG'
                AND A.HOME_TEAM COLLATE utf8mb4_unicode_ci = B.TEAM_NAME
 
            ) A LEFT OUTER JOIN
            (
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '언더' AND BET_OPTION  IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '언더' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN
                UNION ALL
                
                SELECT SPORT_TYPE, BET_OPTION,LEAGUE, 0 AS ALLOCATION_WIN, ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('승패','핸디캡','승무패','전반 승무패') THEN 1
                                 WHEN GAME_RESULT IN (1, '①') AND BET_OPTION = '승1패' THEN 1
                                 WHEN GAME_RESULT IN (5, '⑤') AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('일반','핸디캡','승무패','전반 승무패') THEN 1
                                        WHEN GAME_RESULT IN  (1, '①')  AND BET_OPTION = '승1패' THEN 1
                                        WHEN GAME_RESULT IN  (5, '⑤')  AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_DRAW
                UNION ALL
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, 0 AS ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '오버' AND BET_OPTION = '언더오버' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '오버' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                 where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_LOSE
            ) B
            ON ( A.SPORT_TYPE = B.SPORT_TYPE
                AND A.BET_OPTION = B.BET_OPTION
                AND ( A.ALLOCATION_WIN = B.ALLOCATION_WIN OR A.ALLOCATION_DRAW = B.ALLOCATION_DRAW OR A.ALLOCATION_LOSE = B.ALLOCATION_LOSE )
                )

        GROUP BY A.GAME_NUMBER,
        	     A.game_date,
                 A.SPORT_TYPE,
                 A.LEAGUE,
                 A.BET_OPTION,
                 A.HOME_TEAM,
                 A.AWAY_TEAM,
                 A.ALLOCATION_WIN,
                 A.ALLOCATION_DRAW,
                 A.ALLOCATION_LOSE
ORDER BY 1
)  A, BALANCE B 
ORDER BY 1;


-- WO
INSERT INTO  kbo_stat.tb_match_result
WITH BALANCE AS 
(
SELECT A.TEAMCODE, SUM(100점환산), ROUND( ( SUM(100점환산) - 300 ) / 300 , 3 ) +1  AS RATE
FROM 
(
-- 1
 SELECT * 
 FROM (
   WITH RecentGames AS (
      SELECT 
          home_team_code,
          winner,
          ROW_NUMBER() OVER (
              PARTITION BY home_team_code
              ORDER BY STR_TO_DATE(game_date, '%Y-%m-%d') DESC
          ) AS rn
      FROM tb_game_info
  )
  SELECT 
      a.home_team_code AS teamCode, '1 최근경기승리' AS SEQ , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) AS winCount , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) * 10 AS 100점환산
  FROM RecentGames a
  JOIN tb_team_info b
    ON a.home_team_code = b.team_code
  WHERE a.rn <= 10
  AND a.home_team_code = 'WO'
  GROUP BY a.home_team_code 
 ) A

 
  UNION ALL 
 -- 2
 SELECT *
 FROM (
  WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and  ( a_code = 'WO' OR h_code  = 'WO' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ) ,
 
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
 ),
 
 
 SCORE_RESULT AS (
 
 select a.*,b.*,'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.home_id
 and b.h_code <> 'WO'
 
 union all
 
 select a.*,b.*,'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.away_id
 and b.a_code <> 'WO'
 
 )
  
 SELECT 'WO' AS teamCode , '2 타율'  AS SEQ ,  round( sum(hit) / sum(ab), 3)   ,  round( sum(hit) / sum(ab), 3) * 3.3 * 100 
 from SCORE_RESULT  a  
 ) A 
 
 UNION ALL
 -- 3
 SELECT *
 FROM (
 WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and ( a_code = 'WO' OR h_code  = 'WO' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ),
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
  
  
 ),
 
 SCORE_RESULT AS (
 
 select a.*,b.*, 'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE b
 where a.id = b.home_id
 and b.h_code = 'WO'
 
 union all
 
 select a.*,b.*, 'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE  b
 where a.id = b.away_id
 and b.a_code = 'WO'
 
 )
   
 SELECT 'WO', '3 방어율', ROUND( (SUM(er) / SUM(inn)) * 9 , 2) AS 전체방어율  , 100- ( ROUND( (SUM(er) / SUM(inn)) * 9 , 2) - 3.85 ) * 15  AS 100점환산 
 from SCORE_RESULT  a   
 ) A
 
 UNION ALL 
 -- 4
 SELECT *
 FROM 
 ( 
 WITH param AS (
     SELECT  
         home_team_code ,
         away_team_code 
     FROM tb_game_info  a 
     WHERE home_team_code = 'WO'
     AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y-%m-%d') = a.game_date
     
 ),
 -- ① 시즌 맞대결 : 홈/원정 모두 포함
 matchup AS (
     SELECT
         p.home_team_code,
         p.away_team_code,
         COUNT(1) AS total_games,
         -- 홈팀이 홈일 때, 홈 승리 + 원정일 때, 원정 승리 합산
         SUM(
             CASE
                 WHEN (b.team_code = p.home_team_code AND c.team_code = p.away_team_code AND winner = 'HOME') THEN 1
                 WHEN (b.team_code = p.away_team_code AND c.team_code = p.home_team_code AND winner = 'AWAY') THEN 1
                 ELSE 0
             END
         ) AS home_team_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND (
             (b.team_code = p.home_team_code AND c.team_code = p.away_team_code) OR
             (b.team_code = p.away_team_code AND c.team_code = p.home_team_code)
           )
     GROUP BY p.home_team_code, p.away_team_code
 ),
 -- ② 시즌 홈경기 승률 (전체 홈경기 기준)
 home_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_home_games,
         SUM(CASE WHEN winner = 'HOME' THEN 1 ELSE 0 END) AS home_team_home_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND b.team_code = p.home_team_code
     GROUP BY p.home_team_code
 ),
 -- ③ 시즌 원정경기 승률 (전체 원정경기 기준)
 away_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_away_games,
         SUM(CASE WHEN winner = 'AWAY' THEN 1 ELSE 0 END) AS home_team_away_wins
     FROM tb_game_info a
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND c.team_code = p.home_team_code
     GROUP BY p.home_team_code
 )
 SELECT
   p.home_team_code  AS 홈팀명,
    '4 맞대결',
 --    c.team_name AS 상대팀명, 
     ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) AS 시즌맞대결승률
     ,ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) * 100  AS 100점환산 
  
 FROM param p
 LEFT JOIN matchup m ON p.home_team_code = m.home_team_code AND p.away_team_code = m.away_team_code
 LEFT JOIN home_games h ON p.home_team_code = h.home_team_code
 LEFT JOIN away_games a ON p.home_team_code = a.home_team_code
 LEFT JOIN tb_team_info b ON p.home_team_code = b.team_code
 LEFT JOIN tb_team_info c ON p.away_team_code = c.team_code
 
 )  A 
 
 UNION ALL 
 -- 5
 
 SELECT *
 FROM 
 (
   WITH base AS (
     -- 시즌 전체 득점 데이터 (홈/원정 합산)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_score
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate  >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 득점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS home_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 득점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS away_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_score,
         RANK() OVER (ORDER BY season_avg_score DESC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_score,
         RANK() OVER (ORDER BY home_avg_score DESC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_score,
         RANK() OVER (ORDER BY away_avg_score DESC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code, 
     '5 시즌득점', 
     season_avg_score,
     case when season_avg_score >= 10 then 10 else season_avg_score end * 10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'WO' -- 'WO', 'HH' 
 ) A 
  
 UNION ALL 
 -- 6
 SELECT *
 FROM 
 (
 WITH base AS (
     -- 시즌 전체 실점 데이터 (홈/원정 구분 없음)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_loWO
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 실점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS home_avg_loWO
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 실점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS away_avg_loWO
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_loWO,
         RANK() OVER (ORDER BY season_avg_loWO ASC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_loWO,
         RANK() OVER (ORDER BY home_avg_loWO ASC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_loWO,
         RANK() OVER (ORDER BY away_avg_loWO ASC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code,
     '6 시즌실점', 
     b.season_avg_loWO,
     case when season_avg_loWO >= 10 then 10 else season_avg_loWO end * -10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'WO' -- 'WO', 'HH'
 
 ) A
 
) A
GROUP BY A.TEAMCODE

)
SELECT  A.GAME_NUMBER,
		A.game_date,
        A.BET_OPTION,
        A.HOME_TEAM,
        A.AWAY_TEAM,
        A.홈승배당,
        A.홈무배당,
        A.홈패배당,
         A.승_승률,
        A.무_승률,
        A.패_승률,
        A.전체_승_승률,
        A.전체_무_승률,
        A.전체_패_승률,
        ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) AS 홈승_보정,
        CASE WHEN A.BET_OPTION IN ('승1패','전반') THEN ROUND( 100 - (  ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) ) 
                        - ( ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ),1) ELSE NULL END AS 홈무_보정,
        CASE WHEN A.BET_OPTION IN ('일반','핸디캡','언더오버') THEN  100 - ROUND(((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100 ),1) 
          WHEN A.BET_OPTION IN ('승1패','전반')    THEN        ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ELSE NULL
        END AS 홈패_보정
FROM 
(

SELECT
            A.GAME_NUMBER,
            A.game_date,
--             A.SPORT_TYPE,
--             A.LEAGUE,
            A.BET_OPTION,
            A.HOME_TEAM,
            A.AWAY_TEAM,
            A.ALLOCATION_WIN AS 홈승배당,
            A.ALLOCATION_DRAW AS 홈무배당,
            A.ALLOCATION_LOSE AS 홈패배당,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINLEAGUETOTAWOAMES,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 승_승률,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWLEAGUETOTAWOAMES,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 무_승률,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSELEAGUETOTAWOAMES,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSELEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 패_승률,
--            SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINTOTAWOAMES,
  --          SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 ) AS 전체_승_승률,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWTOTAWOAMES,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWHITGAMES,
            ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_무_승률,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSETOTAWOAMES,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSEHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_패_승률,

((  ( MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_le_ev,

(( ( MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_le_ev,

( (( MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END)  ) *  A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_ev, 

(((             ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 )  ) *  A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_all_ev,
 
 
(((  ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) ) *   A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_all_ev,

(((     ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 )  ) * A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_evS


        FROM
            (
                SELECT A.GAME_NUMBER, A.SPORT_TYPE, A.LEAGUE, A.BET_OPTION, ALLOCATION_WIN, ALLOCATION_DRAW, ALLOCATION_LOSE, A.HOME_TEAM, A.AWAY_TEAM, A.game_date
                FROM kbo_stat.tb_betman_sd_game_now A , ( select  replace(B.TEAM_NAME, ' ', '')  as TEAM_NAME, TEAM_CODE from kbo_stat.tb_team_info B ) B 
                WHERE A.LEAGUE = 'KBO'
                AND A.SPORT_TYPE = '야구'
                -- AND  DATE_FORMAT(NOW()-1, '%Y%m%d') = '20250405' --   DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')-1
                AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y%m%d') =  DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')
                AND A.BET_OPTION NOT IN ( 'SUM','전반' ) 
                AND B.TEAM_CODE = 'WO'
                AND A.HOME_TEAM COLLATE utf8mb4_unicode_ci = B.TEAM_NAME
 
            ) A LEFT OUTER JOIN
            (
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '언더' AND BET_OPTION  IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '언더' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN
                UNION ALL
                
                SELECT SPORT_TYPE, BET_OPTION,LEAGUE, 0 AS ALLOCATION_WIN, ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('승패','핸디캡','승무패','전반 승무패') THEN 1
                                 WHEN GAME_RESULT IN (1, '①') AND BET_OPTION = '승1패' THEN 1
                                 WHEN GAME_RESULT IN (5, '⑤') AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('일반','핸디캡','승무패','전반 승무패') THEN 1
                                        WHEN GAME_RESULT IN  (1, '①')  AND BET_OPTION = '승1패' THEN 1
                                        WHEN GAME_RESULT IN  (5, '⑤')  AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_DRAW
                UNION ALL
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, 0 AS ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '오버' AND BET_OPTION = '언더오버' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '오버' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                 where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_LOSE
            ) B
            ON ( A.SPORT_TYPE = B.SPORT_TYPE
                AND A.BET_OPTION = B.BET_OPTION
                AND ( A.ALLOCATION_WIN = B.ALLOCATION_WIN OR A.ALLOCATION_DRAW = B.ALLOCATION_DRAW OR A.ALLOCATION_LOSE = B.ALLOCATION_LOSE )
                )

        GROUP BY A.GAME_NUMBER,
        	     A.game_date,
                 A.SPORT_TYPE,
                 A.LEAGUE,
                 A.BET_OPTION,
                 A.HOME_TEAM,
                 A.AWAY_TEAM,
                 A.ALLOCATION_WIN,
                 A.ALLOCATION_DRAW,
                 A.ALLOCATION_LOSE
ORDER BY 1
)  A, BALANCE B 
ORDER BY 1;


-- HH
INSERT INTO  kbo_stat.tb_match_result
WITH BALANCE AS 
(
SELECT A.TEAMCODE, SUM(100점환산), ROUND( ( SUM(100점환산) - 300 ) / 300 , 3 ) +1  AS RATE
FROM 
(
-- 1
 SELECT * 
 FROM (
   WITH RecentGames AS (
      SELECT 
          home_team_code,
          winner,
          ROW_NUMBER() OVER (
              PARTITION BY home_team_code
              ORDER BY STR_TO_DATE(game_date, '%Y-%m-%d') DESC
          ) AS rn
      FROM tb_game_info
  )
  SELECT 
      a.home_team_code AS teamCode, '1 최근경기승리' AS SEQ , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) AS winCount , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) * 10 AS 100점환산
  FROM RecentGames a
  JOIN tb_team_info b
    ON a.home_team_code = b.team_code
  WHERE a.rn <= 10
  AND a.home_team_code = 'HH'
  GROUP BY a.home_team_code 
 ) A

 
  UNION ALL 
 -- 2
 SELECT *
 FROM (
  WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and  ( a_code = 'HH' OR h_code  = 'HH' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ) ,
 
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
 ),
 
 
 SCORE_RESULT AS (
 
 select a.*,b.*,'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.home_id
 and b.h_code <> 'HH'
 
 union all
 
 select a.*,b.*,'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.away_id
 and b.a_code <> 'HH'
 
 )
  
 SELECT 'HH' AS teamCode , '2 타율'  AS SEQ ,  round( sum(hit) / sum(ab), 3)   ,  round( sum(hit) / sum(ab), 3) * 3.3 * 100 
 from SCORE_RESULT  a  
 ) A 
 
 UNION ALL
 -- 3
 SELECT *
 FROM (
 WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and ( a_code = 'HH' OR h_code  = 'HH' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ),
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
  
  
 ),
 
 SCORE_RESULT AS (
 
 select a.*,b.*, 'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE b
 where a.id = b.home_id
 and b.h_code = 'HH'
 
 union all
 
 select a.*,b.*, 'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE  b
 where a.id = b.away_id
 and b.a_code = 'HH'
 
 )
   
 SELECT 'HH', '3 방어율', ROUND( (SUM(er) / SUM(inn)) * 9 , 2) AS 전체방어율  , 100- ( ROUND( (SUM(er) / SUM(inn)) * 9 , 2) - 3.85 ) * 15  AS 100점환산 
 from SCORE_RESULT  a   
 ) A
 
 UNION ALL 
 -- 4
 SELECT *
 FROM 
 ( 
 WITH param AS (
     SELECT  
         home_team_code ,
         away_team_code 
     FROM tb_game_info  a 
     WHERE home_team_code = 'HH'
     AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y-%m-%d') = a.game_date
     
 ),
 -- ① 시즌 맞대결 : 홈/원정 모두 포함
 matchup AS (
     SELECT
         p.home_team_code,
         p.away_team_code,
         COUNT(1) AS total_games,
         -- 홈팀이 홈일 때, 홈 승리 + 원정일 때, 원정 승리 합산
         SUM(
             CASE
                 WHEN (b.team_code = p.home_team_code AND c.team_code = p.away_team_code AND winner = 'HOME') THEN 1
                 WHEN (b.team_code = p.away_team_code AND c.team_code = p.home_team_code AND winner = 'AWAY') THEN 1
                 ELSE 0
             END
         ) AS home_team_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND (
             (b.team_code = p.home_team_code AND c.team_code = p.away_team_code) OR
             (b.team_code = p.away_team_code AND c.team_code = p.home_team_code)
           )
     GROUP BY p.home_team_code, p.away_team_code
 ),
 -- ② 시즌 홈경기 승률 (전체 홈경기 기준)
 home_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_home_games,
         SUM(CASE WHEN winner = 'HOME' THEN 1 ELSE 0 END) AS home_team_home_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND b.team_code = p.home_team_code
     GROUP BY p.home_team_code
 ),
 -- ③ 시즌 원정경기 승률 (전체 원정경기 기준)
 away_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_away_games,
         SUM(CASE WHEN winner = 'AWAY' THEN 1 ELSE 0 END) AS home_team_away_wins
     FROM tb_game_info a
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND c.team_code = p.home_team_code
     GROUP BY p.home_team_code
 )
 SELECT
   p.home_team_code  AS 홈팀명,
    '4 맞대결',
 --    c.team_name AS 상대팀명, 
     ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) AS 시즌맞대결승률
     ,ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) * 100  AS 100점환산 
  
 FROM param p
 LEFT JOIN matchup m ON p.home_team_code = m.home_team_code AND p.away_team_code = m.away_team_code
 LEFT JOIN home_games h ON p.home_team_code = h.home_team_code
 LEFT JOIN away_games a ON p.home_team_code = a.home_team_code
 LEFT JOIN tb_team_info b ON p.home_team_code = b.team_code
 LEFT JOIN tb_team_info c ON p.away_team_code = c.team_code
 
 )  A 
 
 UNION ALL 
 -- 5
 
 SELECT *
 FROM 
 (
   WITH base AS (
     -- 시즌 전체 득점 데이터 (홈/원정 합산)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_score
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate  >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 득점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS home_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 득점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS away_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_score,
         RANK() OVER (ORDER BY season_avg_score DESC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_score,
         RANK() OVER (ORDER BY home_avg_score DESC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_score,
         RANK() OVER (ORDER BY away_avg_score DESC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code, 
     '5 시즌득점', 
     season_avg_score,
     case when season_avg_score >= 10 then 10 else season_avg_score end * 10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'HH' -- 'HH', 'HH' 
 ) A 
  
 UNION ALL 
 -- 6
 SELECT *
 FROM 
 (
 WITH base AS (
     -- 시즌 전체 실점 데이터 (홈/원정 구분 없음)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_loHH
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 실점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS home_avg_loHH
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 실점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS away_avg_loHH
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_loHH,
         RANK() OVER (ORDER BY season_avg_loHH ASC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_loHH,
         RANK() OVER (ORDER BY home_avg_loHH ASC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_loHH,
         RANK() OVER (ORDER BY away_avg_loHH ASC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code,
     '6 시즌실점', 
     b.season_avg_loHH,
     case when season_avg_loHH >= 10 then 10 else season_avg_loHH end * -10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'HH' -- 'HH', 'HH'
 
 ) A
 
) A
GROUP BY A.TEAMCODE

)
SELECT  A.GAME_NUMBER,
		A.game_date,
        A.BET_OPTION,
        A.HOME_TEAM,
        A.AWAY_TEAM,
        A.홈승배당,
        A.홈무배당,
        A.홈패배당,
         A.승_승률,
        A.무_승률,
        A.패_승률,
        A.전체_승_승률,
        A.전체_무_승률,
        A.전체_패_승률,
        ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) AS 홈승_보정,
        CASE WHEN A.BET_OPTION IN ('승1패','전반') THEN ROUND( 100 - (  ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) ) 
                        - ( ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ),1) ELSE NULL END AS 홈무_보정,
        CASE WHEN A.BET_OPTION IN ('일반','핸디캡','언더오버') THEN  100 - ROUND(((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100 ),1) 
          WHEN A.BET_OPTION IN ('승1패','전반')    THEN        ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ELSE NULL
        END AS 홈패_보정
FROM 
(

SELECT
            A.GAME_NUMBER,
            A.game_date,
--             A.SPORT_TYPE,
--             A.LEAGUE,
            A.BET_OPTION,
            A.HOME_TEAM,
            A.AWAY_TEAM,
            A.ALLOCATION_WIN AS 홈승배당,
            A.ALLOCATION_DRAW AS 홈무배당,
            A.ALLOCATION_LOSE AS 홈패배당,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINLEAGUETOTAHHAMES,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 승_승률,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWLEAGUETOTAHHAMES,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 무_승률,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSELEAGUETOTAHHAMES,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSELEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 패_승률,
--            SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINTOTAHHAMES,
  --          SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 ) AS 전체_승_승률,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWTOTAHHAMES,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWHITGAMES,
            ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_무_승률,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSETOTAHHAMES,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSEHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_패_승률,

((  ( MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_le_ev,

(( ( MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_le_ev,

( (( MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END)  ) *  A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_ev, 

(((             ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 )  ) *  A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_all_ev,
 
 
(((  ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) ) *   A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_all_ev,

(((     ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 )  ) * A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_evS


        FROM
            (
                SELECT A.GAME_NUMBER, A.SPORT_TYPE, A.LEAGUE, A.BET_OPTION, ALLOCATION_WIN, ALLOCATION_DRAW, ALLOCATION_LOSE, A.HOME_TEAM, A.AWAY_TEAM, A.game_date
                FROM kbo_stat.tb_betman_sd_game_now A , ( select  replace(B.TEAM_NAME, ' ', '')  as TEAM_NAME, TEAM_CODE from kbo_stat.tb_team_info B ) B 
                WHERE A.LEAGUE = 'KBO'
                AND A.SPORT_TYPE = '야구'
                -- AND  DATE_FORMAT(NOW()-1, '%Y%m%d') = '20250405' --   DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')-1
                AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y%m%d') =  DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')
                AND A.BET_OPTION NOT IN ( 'SUM','전반' ) 
                AND B.TEAM_CODE = 'HH'
                AND A.HOME_TEAM COLLATE utf8mb4_unicode_ci = B.TEAM_NAME
 
            ) A LEFT OUTER JOIN
            (
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '언더' AND BET_OPTION  IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '언더' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN
                UNION ALL
                
                SELECT SPORT_TYPE, BET_OPTION,LEAGUE, 0 AS ALLOCATION_WIN, ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('승패','핸디캡','승무패','전반 승무패') THEN 1
                                 WHEN GAME_RESULT IN (1, '①') AND BET_OPTION = '승1패' THEN 1
                                 WHEN GAME_RESULT IN (5, '⑤') AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('일반','핸디캡','승무패','전반 승무패') THEN 1
                                        WHEN GAME_RESULT IN  (1, '①')  AND BET_OPTION = '승1패' THEN 1
                                        WHEN GAME_RESULT IN  (5, '⑤')  AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_DRAW
                UNION ALL
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, 0 AS ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '오버' AND BET_OPTION = '언더오버' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '오버' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                 where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_LOSE
            ) B
            ON ( A.SPORT_TYPE = B.SPORT_TYPE
                AND A.BET_OPTION = B.BET_OPTION
                AND ( A.ALLOCATION_WIN = B.ALLOCATION_WIN OR A.ALLOCATION_DRAW = B.ALLOCATION_DRAW OR A.ALLOCATION_LOSE = B.ALLOCATION_LOSE )
                )

        GROUP BY A.GAME_NUMBER,
        	     A.game_date,
                 A.SPORT_TYPE,
                 A.LEAGUE,
                 A.BET_OPTION,
                 A.HOME_TEAM,
                 A.AWAY_TEAM,
                 A.ALLOCATION_WIN,
                 A.ALLOCATION_DRAW,
                 A.ALLOCATION_LOSE
ORDER BY 1
)  A, BALANCE B 
ORDER BY 1;




-- OB
INSERT INTO  kbo_stat.tb_match_result
WITH BALANCE AS 
(
SELECT A.TEAMCODE, SUM(100점환산), ROUND( ( SUM(100점환산) - 300 ) / 300 , 3 ) +1  AS RATE
FROM 
(
-- 1
 SELECT * 
 FROM (
   WITH RecentGames AS (
      SELECT 
          home_team_code,
          winner,
          ROW_NUMBER() OVER (
              PARTITION BY home_team_code
              ORDER BY STR_TO_DATE(game_date, '%Y-%m-%d') DESC
          ) AS rn
      FROM tb_game_info
  )
  SELECT 
      a.home_team_code AS teamCode, '1 최근경기승리' AS SEQ , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) AS winCount , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) * 10 AS 100점환산
  FROM RecentGames a
  JOIN tb_team_info b
    ON a.home_team_code = b.team_code
  WHERE a.rn <= 10
  AND a.home_team_code = 'OB'
  GROUP BY a.home_team_code 
 ) A

 
  UNION ALL 
 -- 2
 SELECT *
 FROM (
  WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and  ( a_code = 'OB' OR h_code  = 'OB' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ) ,
 
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
 ),
 
 
 SCORE_RESULT AS (
 
 select a.*,b.*,'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.home_id
 and b.h_code <> 'OB'
 
 union all
 
 select a.*,b.*,'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.away_id
 and b.a_code <> 'OB'
 
 )
  
 SELECT 'OB' AS teamCode , '2 타율'  AS SEQ ,  round( sum(hit) / sum(ab), 3)   ,  round( sum(hit) / sum(ab), 3) * 3.3 * 100 
 from SCORE_RESULT  a  
 ) A 
 
 UNION ALL
 -- 3
 SELECT *
 FROM (
 WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and ( a_code = 'OB' OR h_code  = 'OB' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ),
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
  
  
 ),
 
 SCORE_RESULT AS (
 
 select a.*,b.*, 'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE b
 where a.id = b.home_id
 and b.h_code = 'OB'
 
 union all
 
 select a.*,b.*, 'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE  b
 where a.id = b.away_id
 and b.a_code = 'OB'
 
 )
   
 SELECT 'OB', '3 방어율', ROUND( (SUM(er) / SUM(inn)) * 9 , 2) AS 전체방어율  , 100- ( ROUND( (SUM(er) / SUM(inn)) * 9 , 2) - 3.85 ) * 15  AS 100점환산 
 from SCORE_RESULT  a   
 ) A
 
 UNION ALL 
 -- 4
 SELECT *
 FROM 
 ( 
 WITH param AS (
     SELECT  
         home_team_code ,
         away_team_code 
     FROM tb_game_info  a 
     WHERE home_team_code = 'OB'
     AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y-%m-%d') = a.game_date
     
 ),
 -- ① 시즌 맞대결 : 홈/원정 모두 포함
 matchup AS (
     SELECT
         p.home_team_code,
         p.away_team_code,
         COUNT(1) AS total_games,
         -- 홈팀이 홈일 때, 홈 승리 + 원정일 때, 원정 승리 합산
         SUM(
             CASE
                 WHEN (b.team_code = p.home_team_code AND c.team_code = p.away_team_code AND winner = 'HOME') THEN 1
                 WHEN (b.team_code = p.away_team_code AND c.team_code = p.home_team_code AND winner = 'AWAY') THEN 1
                 ELSE 0
             END
         ) AS home_team_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND (
             (b.team_code = p.home_team_code AND c.team_code = p.away_team_code) OR
             (b.team_code = p.away_team_code AND c.team_code = p.home_team_code)
           )
     GROUP BY p.home_team_code, p.away_team_code
 ),
 -- ② 시즌 홈경기 승률 (전체 홈경기 기준)
 home_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_home_games,
         SUM(CASE WHEN winner = 'HOME' THEN 1 ELSE 0 END) AS home_team_home_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND b.team_code = p.home_team_code
     GROUP BY p.home_team_code
 ),
 -- ③ 시즌 원정경기 승률 (전체 원정경기 기준)
 away_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_away_games,
         SUM(CASE WHEN winner = 'AWAY' THEN 1 ELSE 0 END) AS home_team_away_wins
     FROM tb_game_info a
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND c.team_code = p.home_team_code
     GROUP BY p.home_team_code
 )
 SELECT
   p.home_team_code  AS 홈팀명,
    '4 맞대결',
 --    c.team_name AS 상대팀명, 
     ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) AS 시즌맞대결승률
     ,ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) * 100  AS 100점환산 
  
 FROM param p
 LEFT JOIN matchup m ON p.home_team_code = m.home_team_code AND p.away_team_code = m.away_team_code
 LEFT JOIN home_games h ON p.home_team_code = h.home_team_code
 LEFT JOIN away_games a ON p.home_team_code = a.home_team_code
 LEFT JOIN tb_team_info b ON p.home_team_code = b.team_code
 LEFT JOIN tb_team_info c ON p.away_team_code = c.team_code
 
 )  A 
 
 UNION ALL 
 -- 5
 
 SELECT *
 FROM 
 (
   WITH base AS (
     -- 시즌 전체 득점 데이터 (홈/원정 합산)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_score
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate  >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 득점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS home_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 득점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS away_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_score,
         RANK() OVER (ORDER BY season_avg_score DESC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_score,
         RANK() OVER (ORDER BY home_avg_score DESC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_score,
         RANK() OVER (ORDER BY away_avg_score DESC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code, 
     '5 시즌득점', 
     season_avg_score,
     case when season_avg_score >= 10 then 10 else season_avg_score end * 10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'OB' -- 'OB', 'OB' 
 ) A 
  
 UNION ALL 
 -- 6
 SELECT *
 FROM 
 (
 WITH base AS (
     -- 시즌 전체 실점 데이터 (홈/원정 구분 없음)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_loOB
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 실점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS home_avg_loOB
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 실점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS away_avg_loOB
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_loOB,
         RANK() OVER (ORDER BY season_avg_loOB ASC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_loOB,
         RANK() OVER (ORDER BY home_avg_loOB ASC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_loOB,
         RANK() OVER (ORDER BY away_avg_loOB ASC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code,
     '6 시즌실점', 
     b.season_avg_loOB,
     case when season_avg_loOB >= 10 then 10 else season_avg_loOB end * -10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'OB' -- 'OB', 'OB'
 
 ) A
 
) A
GROUP BY A.TEAMCODE

)
SELECT  A.GAME_NUMBER,
		A.game_date,
        A.BET_OPTION,
        A.HOME_TEAM,
        A.AWAY_TEAM,
        A.홈승배당,
        A.홈무배당,
        A.홈패배당,
         A.승_승률,
        A.무_승률,
        A.패_승률,
        A.전체_승_승률,
        A.전체_무_승률,
        A.전체_패_승률,
        ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) AS 홈승_보정,
        CASE WHEN A.BET_OPTION IN ('승1패','전반') THEN ROUND( 100 - (  ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) ) 
                        - ( ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ),1) ELSE NULL END AS 홈무_보정,
        CASE WHEN A.BET_OPTION IN ('일반','핸디캡','언더오버') THEN  100 - ROUND(((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100 ),1) 
          WHEN A.BET_OPTION IN ('승1패','전반')    THEN        ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ELSE NULL
        END AS 홈패_보정
FROM 
(

SELECT
            A.GAME_NUMBER,
            A.game_date,
--             A.SPORT_TYPE,
--             A.LEAGUE,
            A.BET_OPTION,
            A.HOME_TEAM,
            A.AWAY_TEAM,
            A.ALLOCATION_WIN AS 홈승배당,
            A.ALLOCATION_DRAW AS 홈무배당,
            A.ALLOCATION_LOSE AS 홈패배당,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINLEAGUETOTAOBAMES,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 승_승률,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWLEAGUETOTAOBAMES,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 무_승률,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSELEAGUETOTAOBAMES,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSELEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 패_승률,
--            SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINTOTAOBAMES,
  --          SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 ) AS 전체_승_승률,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWTOTAOBAMES,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWHITGAMES,
            ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_무_승률,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSETOTAOBAMES,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSEHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_패_승률,

((  ( MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_le_ev,

(( ( MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_le_ev,

( (( MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END)  ) *  A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_ev, 

(((             ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 )  ) *  A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_all_ev,
 
 
(((  ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) ) *   A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_all_ev,

(((     ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 )  ) * A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_evS


        FROM
            (
                SELECT A.GAME_NUMBER, A.SPORT_TYPE, A.LEAGUE, A.BET_OPTION, ALLOCATION_WIN, ALLOCATION_DRAW, ALLOCATION_LOSE, A.HOME_TEAM, A.AWAY_TEAM, A.game_date
                FROM kbo_stat.tb_betman_sd_game_now A , ( select  replace(B.TEAM_NAME, ' ', '')  as TEAM_NAME, TEAM_CODE from kbo_stat.tb_team_info B ) B 
                WHERE A.LEAGUE = 'KBO'
                AND A.SPORT_TYPE = '야구'
                -- AND  DATE_FORMAT(NOW()-1, '%Y%m%d') = '20250405' --   DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')-1
                AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y%m%d') =  DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')
                AND A.BET_OPTION NOT IN ( 'SUM','전반' ) 
                AND B.TEAM_CODE = 'OB'
                AND A.HOME_TEAM COLLATE utf8mb4_unicode_ci = B.TEAM_NAME
 
            ) A LEFT OUTER JOIN
            (
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '언더' AND BET_OPTION  IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '언더' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN
                UNION ALL
                
                SELECT SPORT_TYPE, BET_OPTION,LEAGUE, 0 AS ALLOCATION_WIN, ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('승패','핸디캡','승무패','전반 승무패') THEN 1
                                 WHEN GAME_RESULT IN (1, '①') AND BET_OPTION = '승1패' THEN 1
                                 WHEN GAME_RESULT IN (5, '⑤') AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('일반','핸디캡','승무패','전반 승무패') THEN 1
                                        WHEN GAME_RESULT IN  (1, '①')  AND BET_OPTION = '승1패' THEN 1
                                        WHEN GAME_RESULT IN  (5, '⑤')  AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_DRAW
                UNION ALL
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, 0 AS ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '오버' AND BET_OPTION = '언더오버' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '오버' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                 where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_LOSE
            ) B
            ON ( A.SPORT_TYPE = B.SPORT_TYPE
                AND A.BET_OPTION = B.BET_OPTION
                AND ( A.ALLOCATION_WIN = B.ALLOCATION_WIN OR A.ALLOCATION_DRAW = B.ALLOCATION_DRAW OR A.ALLOCATION_LOSE = B.ALLOCATION_LOSE )
                )

        GROUP BY A.GAME_NUMBER,
        	     A.game_date,
                 A.SPORT_TYPE,
                 A.LEAGUE,
                 A.BET_OPTION,
                 A.HOME_TEAM,
                 A.AWAY_TEAM,
                 A.ALLOCATION_WIN,
                 A.ALLOCATION_DRAW,
                 A.ALLOCATION_LOSE
ORDER BY 1
)  A, BALANCE B 
ORDER BY 1;



-- SK
INSERT INTO  kbo_stat.tb_match_result
WITH BALANCE AS 
(
SELECT A.TEAMCODE, SUM(100점환산), ROUND( ( SUM(100점환산) - 300 ) / 300 , 3 ) +1  AS RATE
FROM 
(
-- 1
 SELECT * 
 FROM (
   WITH RecentGames AS (
      SELECT 
          home_team_code,
          winner,
          ROW_NUMBER() OVER (
              PARTITION BY home_team_code
              ORDER BY STR_TO_DATE(game_date, '%Y-%m-%d') DESC
          ) AS rn
      FROM tb_game_info
  )
  SELECT 
      a.home_team_code AS teamCode, '1 최근경기승리' AS SEQ , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) AS winCount , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) * 10 AS 100점환산
  FROM RecentGames a
  JOIN tb_team_info b
    ON a.home_team_code = b.team_code
  WHERE a.rn <= 10
  AND a.home_team_code = 'SK'
  GROUP BY a.home_team_code 
 ) A

 
  UNION ALL 
 -- 2
 SELECT *
 FROM (
  WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and  ( a_code = 'SK' OR h_code  = 'SK' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ) ,
 
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
 ),
 
 
 SCORE_RESULT AS (
 
 select a.*,b.*,'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.home_id
 and b.h_code <> 'SK'
 
 union all
 
 select a.*,b.*,'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.away_id
 and b.a_code <> 'SK'
 
 )
  
 SELECT 'SK' AS teamCode , '2 타율'  AS SEQ ,  round( sum(hit) / sum(ab), 3)   ,  round( sum(hit) / sum(ab), 3) * 3.3 * 100 
 from SCORE_RESULT  a  
 ) A 
 
 UNION ALL
 -- 3
 SELECT *
 FROM (
 WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and ( a_code = 'SK' OR h_code  = 'SK' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ),
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
  
  
 ),
 
 SCORE_RESULT AS (
 
 select a.*,b.*, 'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE b
 where a.id = b.home_id
 and b.h_code = 'SK'
 
 union all
 
 select a.*,b.*, 'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE  b
 where a.id = b.away_id
 and b.a_code = 'SK'
 
 )
   
 SELECT 'SK', '3 방어율', ROUND( (SUM(er) / SUM(inn)) * 9 , 2) AS 전체방어율  , 100- ( ROUND( (SUM(er) / SUM(inn)) * 9 , 2) - 3.85 ) * 15  AS 100점환산 
 from SCORE_RESULT  a   
 ) A
 
 UNION ALL 
 -- 4
 SELECT *
 FROM 
 ( 
 WITH param AS (
     SELECT  
         home_team_code ,
         away_team_code 
     FROM tb_game_info  a 
     WHERE home_team_code = 'SK'
     AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y-%m-%d') = a.game_date
     
 ),
 -- ① 시즌 맞대결 : 홈/원정 모두 포함
 matchup AS (
     SELECT
         p.home_team_code,
         p.away_team_code,
         COUNT(1) AS total_games,
         -- 홈팀이 홈일 때, 홈 승리 + 원정일 때, 원정 승리 합산
         SUM(
             CASE
                 WHEN (b.team_code = p.home_team_code AND c.team_code = p.away_team_code AND winner = 'HOME') THEN 1
                 WHEN (b.team_code = p.away_team_code AND c.team_code = p.home_team_code AND winner = 'AWAY') THEN 1
                 ELSE 0
             END
         ) AS home_team_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND (
             (b.team_code = p.home_team_code AND c.team_code = p.away_team_code) OR
             (b.team_code = p.away_team_code AND c.team_code = p.home_team_code)
           )
     GROUP BY p.home_team_code, p.away_team_code
 ),
 -- ② 시즌 홈경기 승률 (전체 홈경기 기준)
 home_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_home_games,
         SUM(CASE WHEN winner = 'HOME' THEN 1 ELSE 0 END) AS home_team_home_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND b.team_code = p.home_team_code
     GROUP BY p.home_team_code
 ),
 -- ③ 시즌 원정경기 승률 (전체 원정경기 기준)
 away_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_away_games,
         SUM(CASE WHEN winner = 'AWAY' THEN 1 ELSE 0 END) AS home_team_away_wins
     FROM tb_game_info a
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND c.team_code = p.home_team_code
     GROUP BY p.home_team_code
 )
 SELECT
   p.home_team_code  AS 홈팀명,
    '4 맞대결',
 --    c.team_name AS 상대팀명, 
     ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) AS 시즌맞대결승률
     ,ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) * 100  AS 100점환산 
  
 FROM param p
 LEFT JOIN matchup m ON p.home_team_code = m.home_team_code AND p.away_team_code = m.away_team_code
 LEFT JOIN home_games h ON p.home_team_code = h.home_team_code
 LEFT JOIN away_games a ON p.home_team_code = a.home_team_code
 LEFT JOIN tb_team_info b ON p.home_team_code = b.team_code
 LEFT JOIN tb_team_info c ON p.away_team_code = c.team_code
 
 )  A 
 
 UNION ALL 
 -- 5
 
 SELECT *
 FROM 
 (
   WITH base AS (
     -- 시즌 전체 득점 데이터 (홈/원정 합산)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_score
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate  >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 득점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS home_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 득점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS away_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_score,
         RANK() OVER (ORDER BY season_avg_score DESC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_score,
         RANK() OVER (ORDER BY home_avg_score DESC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_score,
         RANK() OVER (ORDER BY away_avg_score DESC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code, 
     '5 시즌득점', 
     season_avg_score,
     case when season_avg_score >= 10 then 10 else season_avg_score end * 10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'SK' -- 'SK', 'SK' 
 ) A 
  
 UNION ALL 
 -- 6
 SELECT *
 FROM 
 (
 WITH base AS (
     -- 시즌 전체 실점 데이터 (홈/원정 구분 없음)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_loSK
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 실점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS home_avg_loSK
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 실점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS away_avg_loSK
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_loSK,
         RANK() OVER (ORDER BY season_avg_loSK ASC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_loSK,
         RANK() OVER (ORDER BY home_avg_loSK ASC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_loSK,
         RANK() OVER (ORDER BY away_avg_loSK ASC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code,
     '6 시즌실점', 
     b.season_avg_loSK,
     case when season_avg_loSK >= 10 then 10 else season_avg_loSK end * -10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'SK' -- 'SK', 'SK'
 
 ) A
 
) A
GROUP BY A.TEAMCODE

)
SELECT  A.GAME_NUMBER,
		A.game_date,
        A.BET_OPTION,
        A.HOME_TEAM,
        A.AWAY_TEAM,
        A.홈승배당,
        A.홈무배당,
        A.홈패배당,
         A.승_승률,
        A.무_승률,
        A.패_승률,
        A.전체_승_승률,
        A.전체_무_승률,
        A.전체_패_승률,
        ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) AS 홈승_보정,
        CASE WHEN A.BET_OPTION IN ('승1패','전반') THEN ROUND( 100 - (  ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) ) 
                        - ( ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ),1) ELSE NULL END AS 홈무_보정,
        CASE WHEN A.BET_OPTION IN ('일반','핸디캡','언더오버') THEN  100 - ROUND(((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100 ),1) 
          WHEN A.BET_OPTION IN ('승1패','전반')    THEN        ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ELSE NULL
        END AS 홈패_보정
FROM 
(

SELECT
            A.GAME_NUMBER,
            A.game_date,
--             A.SPORT_TYPE,
--             A.LEAGUE,
            A.BET_OPTION,
            A.HOME_TEAM,
            A.AWAY_TEAM,
            A.ALLOCATION_WIN AS 홈승배당,
            A.ALLOCATION_DRAW AS 홈무배당,
            A.ALLOCATION_LOSE AS 홈패배당,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINLEAGUETOTASKAMES,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 승_승률,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWLEAGUETOTASKAMES,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 무_승률,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSELEAGUETOTASKAMES,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSELEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 패_승률,
--            SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINTOTASKAMES,
  --          SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 ) AS 전체_승_승률,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWTOTASKAMES,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWHITGAMES,
            ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_무_승률,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSETOTASKAMES,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSEHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_패_승률,

((  ( MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_le_ev,

(( ( MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_le_ev,

( (( MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END)  ) *  A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_ev, 

(((             ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 )  ) *  A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_all_ev,
 
 
(((  ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) ) *   A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_all_ev,

(((     ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 )  ) * A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_evS


        FROM
            (
                SELECT A.GAME_NUMBER, A.SPORT_TYPE, A.LEAGUE, A.BET_OPTION, ALLOCATION_WIN, ALLOCATION_DRAW, ALLOCATION_LOSE, A.HOME_TEAM, A.AWAY_TEAM, A.game_date
                FROM kbo_stat.tb_betman_sd_game_now A , ( select  replace(B.TEAM_NAME, ' ', '')  as TEAM_NAME, TEAM_CODE from kbo_stat.tb_team_info B ) B 
                WHERE A.LEAGUE = 'KBO'
                AND A.SPORT_TYPE = '야구'
                -- AND  DATE_FORMAT(NOW()-1, '%Y%m%d') = '20250405' --   DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')-1
                AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y%m%d') =  DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')
                AND A.BET_OPTION NOT IN ( 'SUM','전반' ) 
                AND B.TEAM_CODE = 'SK'
                AND A.HOME_TEAM COLLATE utf8mb4_unicode_ci = B.TEAM_NAME
 
            ) A LEFT OUTER JOIN
            (
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '언더' AND BET_OPTION  IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '언더' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN
                UNION ALL
                
                SELECT SPORT_TYPE, BET_OPTION,LEAGUE, 0 AS ALLOCATION_WIN, ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('승패','핸디캡','승무패','전반 승무패') THEN 1
                                 WHEN GAME_RESULT IN (1, '①') AND BET_OPTION = '승1패' THEN 1
                                 WHEN GAME_RESULT IN (5, '⑤') AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('일반','핸디캡','승무패','전반 승무패') THEN 1
                                        WHEN GAME_RESULT IN  (1, '①')  AND BET_OPTION = '승1패' THEN 1
                                        WHEN GAME_RESULT IN  (5, '⑤')  AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_DRAW
                UNION ALL
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, 0 AS ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '오버' AND BET_OPTION = '언더오버' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '오버' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                 where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_LOSE
            ) B
            ON ( A.SPORT_TYPE = B.SPORT_TYPE
                AND A.BET_OPTION = B.BET_OPTION
                AND ( A.ALLOCATION_WIN = B.ALLOCATION_WIN OR A.ALLOCATION_DRAW = B.ALLOCATION_DRAW OR A.ALLOCATION_LOSE = B.ALLOCATION_LOSE )
                )

        GROUP BY A.GAME_NUMBER,
        	     A.game_date,
                 A.SPORT_TYPE,
                 A.LEAGUE,
                 A.BET_OPTION,
                 A.HOME_TEAM,
                 A.AWAY_TEAM,
                 A.ALLOCATION_WIN,
                 A.ALLOCATION_DRAW,
                 A.ALLOCATION_LOSE
ORDER BY 1
)  A, BALANCE B 
ORDER BY 1;



-- LT
INSERT INTO  kbo_stat.tb_match_result
WITH BALANCE AS 
(
SELECT A.TEAMCODE, SUM(100점환산), ROUND( ( SUM(100점환산) - 300 ) / 300 , 3 ) +1  AS RATE
FROM 
(
-- 1
 SELECT * 
 FROM (
   WITH RecentGames AS (
      SELECT 
          home_team_code,
          winner,
          ROW_NUMBER() OVER (
              PARTITION BY home_team_code
              ORDER BY STR_TO_DATE(game_date, '%Y-%m-%d') DESC
          ) AS rn
      FROM tb_game_info
  )
  SELECT 
      a.home_team_code AS teamCode, '1 최근경기승리' AS SEQ , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) AS winCount , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) * 10 AS 100점환산
  FROM RecentGames a
  JOIN tb_team_info b
    ON a.home_team_code = b.team_code
  WHERE a.rn <= 10
  AND a.home_team_code = 'LT'
  GROUP BY a.home_team_code 
 ) A

 
  UNION ALL 
 -- 2
 SELECT *
 FROM (
  WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and  ( a_code = 'LT' OR h_code  = 'LT' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ) ,
 
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
 ),
 
 
 SCORE_RESULT AS (
 
 select a.*,b.*,'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.home_id
 and b.h_code <> 'LT'
 
 union all
 
 select a.*,b.*,'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.away_id
 and b.a_code <> 'LT'
 
 )
  
 SELECT 'LT' AS teamCode , '2 타율'  AS SEQ ,  round( sum(hit) / sum(ab), 3)   ,  round( sum(hit) / sum(ab), 3) * 3.3 * 100 
 from SCORE_RESULT  a  
 ) A 
 
 UNION ALL
 -- 3
 SELECT *
 FROM (
 WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_result_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and ( a_code = 'LT' OR h_code  = 'LT' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_result_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ),
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_result_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
  
  
 ),
 
 SCORE_RESULT AS (
 
 select a.*,b.*, 'HOME' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE b
 where a.id = b.home_id
 and b.h_code = 'LT'
 
 union all
 
 select a.*,b.*, 'AWAY' AS HW -- HOME
 from tb_result_tab_team_pitching_boxscore_away a  , SCORE  b
 where a.id = b.away_id
 and b.a_code = 'LT'
 
 )
   
 SELECT 'LT', '3 방어율', ROUND( (SUM(er) / SUM(inn)) * 9 , 2) AS 전체방어율  , 100- ( ROUND( (SUM(er) / SUM(inn)) * 9 , 2) - 3.85 ) * 15  AS 100점환산 
 from SCORE_RESULT  a   
 ) A
 
 UNION ALL 
 -- 4
 SELECT *
 FROM 
 ( 
 WITH param AS (
     SELECT  
         home_team_code ,
         away_team_code 
     FROM tb_game_info  a 
     WHERE home_team_code = 'LT'
     AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y-%m-%d') = a.game_date
     
 ),
 -- ① 시즌 맞대결 : 홈/원정 모두 포함
 matchup AS (
     SELECT
         p.home_team_code,
         p.away_team_code,
         COUNT(1) AS total_games,
         -- 홈팀이 홈일 때, 홈 승리 + 원정일 때, 원정 승리 합산
         SUM(
             CASE
                 WHEN (b.team_code = p.home_team_code AND c.team_code = p.away_team_code AND winner = 'HOME') THEN 1
                 WHEN (b.team_code = p.away_team_code AND c.team_code = p.home_team_code AND winner = 'AWAY') THEN 1
                 ELSE 0
             END
         ) AS home_team_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND (
             (b.team_code = p.home_team_code AND c.team_code = p.away_team_code) OR
             (b.team_code = p.away_team_code AND c.team_code = p.home_team_code)
           )
     GROUP BY p.home_team_code, p.away_team_code
 ),
 -- ② 시즌 홈경기 승률 (전체 홈경기 기준)
 home_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_home_games,
         SUM(CASE WHEN winner = 'HOME' THEN 1 ELSE 0 END) AS home_team_home_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND b.team_code = p.home_team_code
     GROUP BY p.home_team_code
 ),
 -- ③ 시즌 원정경기 승률 (전체 원정경기 기준)
 away_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_away_games,
         SUM(CASE WHEN winner = 'AWAY' THEN 1 ELSE 0 END) AS home_team_away_wins
     FROM tb_game_info a
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND c.team_code = p.home_team_code
     GROUP BY p.home_team_code
 )
 SELECT
   p.home_team_code  AS 홈팀명,
    '4 맞대결',
 --    c.team_name AS 상대팀명, 
     ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) AS 시즌맞대결승률
     ,ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) * 100  AS 100점환산 
  
 FROM param p
 LEFT JOIN matchup m ON p.home_team_code = m.home_team_code AND p.away_team_code = m.away_team_code
 LEFT JOIN home_games h ON p.home_team_code = h.home_team_code
 LEFT JOIN away_games a ON p.home_team_code = a.home_team_code
 LEFT JOIN tb_team_info b ON p.home_team_code = b.team_code
 LEFT JOIN tb_team_info c ON p.away_team_code = c.team_code
 
 )  A 
 
 UNION ALL 
 -- 5
 
 SELECT *
 FROM 
 (
   WITH base AS (
     -- 시즌 전체 득점 데이터 (홈/원정 합산)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_score
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate  >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 득점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS home_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 득점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS away_avg_score
     FROM tb_result_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_score,
         RANK() OVER (ORDER BY season_avg_score DESC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_score,
         RANK() OVER (ORDER BY home_avg_score DESC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_score,
         RANK() OVER (ORDER BY away_avg_score DESC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code, 
     '5 시즌득점', 
     season_avg_score,
     case when season_avg_score >= 10 then 10 else season_avg_score end * 10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'LT' -- 'LT', 'LT' 
 ) A 
  
 UNION ALL 
 -- 6
 SELECT *
 FROM 
 (
 WITH base AS (
     -- 시즌 전체 실점 데이터 (홈/원정 구분 없음)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_loLT
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_result_tab_recent_vs_game
         WHERE gdate >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 실점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS home_avg_loLT
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 실점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS away_avg_loLT
     FROM tb_result_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_loLT,
         RANK() OVER (ORDER BY season_avg_loLT ASC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_loLT,
         RANK() OVER (ORDER BY home_avg_loLT ASC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_loLT,
         RANK() OVER (ORDER BY away_avg_loLT ASC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code,
     '6 시즌실점', 
     b.season_avg_loLT,
     case when season_avg_loLT >= 10 then 10 else season_avg_loLT end * -10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'LT' -- 'LT', 'LT'
 
 ) A
 
) A
GROUP BY A.TEAMCODE

)
SELECT  A.GAME_NUMBER,
		A.game_date,
        A.BET_OPTION,
        A.HOME_TEAM,
        A.AWAY_TEAM,
        A.홈승배당,
        A.홈무배당,
        A.홈패배당,
         A.승_승률,
        A.무_승률,
        A.패_승률,
        A.전체_승_승률,
        A.전체_무_승률,
        A.전체_패_승률,
        ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) AS 홈승_보정,
        CASE WHEN A.BET_OPTION IN ('승1패','전반') THEN ROUND( 100 - (  ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) ) 
                        - ( ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ),1) ELSE NULL END AS 홈무_보정,
        CASE WHEN A.BET_OPTION IN ('일반','핸디캡','언더오버') THEN  100 - ROUND(((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100 ),1) 
          WHEN A.BET_OPTION IN ('승1패','전반')    THEN        ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ELSE NULL
        END AS 홈패_보정
FROM 
(

SELECT
            A.GAME_NUMBER,
            A.game_date,
--             A.SPORT_TYPE,
--             A.LEAGUE,
            A.BET_OPTION,
            A.HOME_TEAM,
            A.AWAY_TEAM,
            A.ALLOCATION_WIN AS 홈승배당,
            A.ALLOCATION_DRAW AS 홈무배당,
            A.ALLOCATION_LOSE AS 홈패배당,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINLEAGUETOTALTAMES,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 승_승률,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWLEAGUETOTALTAMES,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 무_승률,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSELEAGUETOTALTAMES,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSELEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 패_승률,
--            SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINTOTALTAMES,
  --          SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 ) AS 전체_승_승률,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWTOTALTAMES,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWHITGAMES,
            ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_무_승률,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSETOTALTAMES,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSEHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_패_승률,

((  ( MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_le_ev,

(( ( MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_le_ev,

( (( MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END)  ) *  A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_ev, 

(((             ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 )  ) *  A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_all_ev,
 
 
(((  ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) ) *   A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_all_ev,

(((     ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 )  ) * A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_evS


        FROM
            (
                SELECT A.GAME_NUMBER, A.SPORT_TYPE, A.LEAGUE, A.BET_OPTION, ALLOCATION_WIN, ALLOCATION_DRAW, ALLOCATION_LOSE, A.HOME_TEAM, A.AWAY_TEAM, A.game_date
                FROM kbo_stat.tb_betman_sd_game_now A , ( select  replace(B.TEAM_NAME, ' ', '')  as TEAM_NAME, TEAM_CODE from kbo_stat.tb_team_info B ) B 
                WHERE A.LEAGUE = 'KBO'
                AND A.SPORT_TYPE = '야구'
                -- AND  DATE_FORMAT(NOW()-1, '%Y%m%d') = '20250405' --   DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')-1
                AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y%m%d') =  DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')
                AND A.BET_OPTION NOT IN ( 'SUM','전반' ) 
                AND B.TEAM_CODE = 'LT'
                AND A.HOME_TEAM COLLATE utf8mb4_unicode_ci = B.TEAM_NAME
 
            ) A LEFT OUTER JOIN
            (
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '언더' AND BET_OPTION  IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '언더' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN
                UNION ALL
                
                SELECT SPORT_TYPE, BET_OPTION,LEAGUE, 0 AS ALLOCATION_WIN, ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('승패','핸디캡','승무패','전반 승무패') THEN 1
                                 WHEN GAME_RESULT IN (1, '①') AND BET_OPTION = '승1패' THEN 1
                                 WHEN GAME_RESULT IN (5, '⑤') AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '무' AND BET_OPTION IN ('일반','핸디캡','승무패','전반 승무패') THEN 1
                                        WHEN GAME_RESULT IN  (1, '①')  AND BET_OPTION = '승1패' THEN 1
                                        WHEN GAME_RESULT IN  (5, '⑤')  AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_DRAW
                UNION ALL
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, 0 AS ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESULT = '오버' AND BET_OPTION = '언더오버' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESULT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESULT = '오버' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_result
                 where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_LOSE
            ) B
            ON ( A.SPORT_TYPE = B.SPORT_TYPE
                AND A.BET_OPTION = B.BET_OPTION
                AND ( A.ALLOCATION_WIN = B.ALLOCATION_WIN OR A.ALLOCATION_DRAW = B.ALLOCATION_DRAW OR A.ALLOCATION_LOSE = B.ALLOCATION_LOSE )
                )

        GROUP BY A.GAME_NUMBER,
        	     A.game_date,
                 A.SPORT_TYPE,
                 A.LEAGUE,
                 A.BET_OPTION,
                 A.HOME_TEAM,
                 A.AWAY_TEAM,
                 A.ALLOCATION_WIN,
                 A.ALLOCATION_DRAW,
                 A.ALLOCATION_LOSE
ORDER BY 1
)  A, BALANCE B 
ORDER BY 1;



-- KT
INSERT INTO  kbo_stat.tb_match_resuKT
WITH BALANCE AS 
(
SELECT A.TEAMCODE, SUM(100점환산), ROUND( ( SUM(100점환산) - 300 ) / 300 , 3 ) +1  AS RATE
FROM 
(
-- 1
 SELECT * 
 FROM (
   WITH RecentGames AS (
      SELECT 
          home_team_code,
          winner,
          ROW_NUMBER() OVER (
              PARTITION BY home_team_code
              ORDER BY STR_TO_DATE(game_date, '%Y-%m-%d') DESC
          ) AS rn
      FROM tb_game_info
  )
  SELECT 
      a.home_team_code AS teamCode, '1 최근경기승리' AS SEQ , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) AS winCount , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) * 10 AS 100점환산
  FROM RecentGames a
  JOIN tb_team_info b
    ON a.home_team_code = b.team_code
  WHERE a.rn <= 10
  AND a.home_team_code = 'KT'
  GROUP BY a.home_team_code 
 ) A

 
  UNION ALL 
 -- 2
 SELECT *
 FROM (
  WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_resuKT_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and  ( a_code = 'KT' OR h_code  = 'KT' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_resuKT_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ) ,
 
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_resuKT_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
 ),
 
 
 SCORE_RESUKT AS (
 
 select a.*,b.*,'HOME' AS HW -- HOME
 from tb_resuKT_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.home_id
 and b.h_code <> 'KT'
 
 union all
 
 select a.*,b.*,'AWAY' AS HW -- HOME
 from tb_resuKT_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.away_id
 and b.a_code <> 'KT'
 
 )
  
 SELECT 'KT' AS teamCode , '2 타율'  AS SEQ ,  round( sum(hit) / sum(ab), 3)   ,  round( sum(hit) / sum(ab), 3) * 3.3 * 100 
 from SCORE_RESUKT  a  
 ) A 
 
 UNION ALL
 -- 3
 SELECT *
 FROM (
 WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_resuKT_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and ( a_code = 'KT' OR h_code  = 'KT' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_resuKT_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ),
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_resuKT_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
  
  
 ),
 
 SCORE_RESUKT AS (
 
 select a.*,b.*, 'HOME' AS HW -- HOME
 from tb_resuKT_tab_team_pitching_boxscore_away a  , SCORE b
 where a.id = b.home_id
 and b.h_code = 'KT'
 
 union all
 
 select a.*,b.*, 'AWAY' AS HW -- HOME
 from tb_resuKT_tab_team_pitching_boxscore_away a  , SCORE  b
 where a.id = b.away_id
 and b.a_code = 'KT'
 
 )
   
 SELECT 'KT', '3 방어율', ROUND( (SUM(er) / SUM(inn)) * 9 , 2) AS 전체방어율  , 100- ( ROUND( (SUM(er) / SUM(inn)) * 9 , 2) - 3.85 ) * 15  AS 100점환산 
 from SCORE_RESUKT  a   
 ) A
 
 UNION ALL 
 -- 4
 SELECT *
 FROM 
 ( 
 WITH param AS (
     SELECT  
         home_team_code ,
         away_team_code 
     FROM tb_game_info  a 
     WHERE home_team_code = 'KT'
     AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y-%m-%d') = a.game_date
     
 ),
 -- ① 시즌 맞대결 : 홈/원정 모두 포함
 matchup AS (
     SELECT
         p.home_team_code,
         p.away_team_code,
         COUNT(1) AS total_games,
         -- 홈팀이 홈일 때, 홈 승리 + 원정일 때, 원정 승리 합산
         SUM(
             CASE
                 WHEN (b.team_code = p.home_team_code AND c.team_code = p.away_team_code AND winner = 'HOME') THEN 1
                 WHEN (b.team_code = p.away_team_code AND c.team_code = p.home_team_code AND winner = 'AWAY') THEN 1
                 ELSE 0
             END
         ) AS home_team_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND (
             (b.team_code = p.home_team_code AND c.team_code = p.away_team_code) OR
             (b.team_code = p.away_team_code AND c.team_code = p.home_team_code)
           )
     GROUP BY p.home_team_code, p.away_team_code
 ),
 -- ② 시즌 홈경기 승률 (전체 홈경기 기준)
 home_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_home_games,
         SUM(CASE WHEN winner = 'HOME' THEN 1 ELSE 0 END) AS home_team_home_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND b.team_code = p.home_team_code
     GROUP BY p.home_team_code
 ),
 -- ③ 시즌 원정경기 승률 (전체 원정경기 기준)
 away_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_away_games,
         SUM(CASE WHEN winner = 'AWAY' THEN 1 ELSE 0 END) AS home_team_away_wins
     FROM tb_game_info a
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND c.team_code = p.home_team_code
     GROUP BY p.home_team_code
 )
 SELECT
   p.home_team_code  AS 홈팀명,
    '4 맞대결',
 --    c.team_name AS 상대팀명, 
     ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) AS 시즌맞대결승률
     ,ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) * 100  AS 100점환산 
  
 FROM param p
 LEFT JOIN matchup m ON p.home_team_code = m.home_team_code AND p.away_team_code = m.away_team_code
 LEFT JOIN home_games h ON p.home_team_code = h.home_team_code
 LEFT JOIN away_games a ON p.home_team_code = a.home_team_code
 LEFT JOIN tb_team_info b ON p.home_team_code = b.team_code
 LEFT JOIN tb_team_info c ON p.away_team_code = c.team_code
 
 )  A 
 
 UNION ALL 
 -- 5
 
 SELECT *
 FROM 
 (
   WITH base AS (
     -- 시즌 전체 득점 데이터 (홈/원정 합산)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_score
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_resuKT_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_resuKT_tab_recent_vs_game
         WHERE gdate  >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 득점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS home_avg_score
     FROM tb_resuKT_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 득점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS away_avg_score
     FROM tb_resuKT_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_score,
         RANK() OVER (ORDER BY season_avg_score DESC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_score,
         RANK() OVER (ORDER BY home_avg_score DESC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_score,
         RANK() OVER (ORDER BY away_avg_score DESC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code, 
     '5 시즌득점', 
     season_avg_score,
     case when season_avg_score >= 10 then 10 else season_avg_score end * 10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'KT' -- 'KT', 'KT' 
 ) A 
  
 UNION ALL 
 -- 6
 SELECT *
 FROM 
 (
 WITH base AS (
     -- 시즌 전체 실점 데이터 (홈/원정 구분 없음)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_loKT
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_resuKT_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_resuKT_tab_recent_vs_game
         WHERE gdate >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 실점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS home_avg_loKT
     FROM tb_resuKT_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 실점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS away_avg_loKT
     FROM tb_resuKT_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_loKT,
         RANK() OVER (ORDER BY season_avg_loKT ASC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_loKT,
         RANK() OVER (ORDER BY home_avg_loKT ASC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_loKT,
         RANK() OVER (ORDER BY away_avg_loKT ASC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code,
     '6 시즌실점', 
     b.season_avg_loKT,
     case when season_avg_loKT >= 10 then 10 else season_avg_loKT end * -10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'KT' -- 'KT', 'KT'
 
 ) A
 
) A
GROUP BY A.TEAMCODE

)
SELECT  A.GAME_NUMBER,
		A.game_date,
        A.BET_OPTION,
        A.HOME_TEAM,
        A.AWAY_TEAM,
        A.홈승배당,
        A.홈무배당,
        A.홈패배당,
         A.승_승률,
        A.무_승률,
        A.패_승률,
        A.전체_승_승률,
        A.전체_무_승률,
        A.전체_패_승률,
        ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) AS 홈승_보정,
        CASE WHEN A.BET_OPTION IN ('승1패','전반') THEN ROUND( 100 - (  ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) ) 
                        - ( ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ),1) ELSE NULL END AS 홈무_보정,
        CASE WHEN A.BET_OPTION IN ('일반','핸디캡','언더오버') THEN  100 - ROUND(((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100 ),1) 
          WHEN A.BET_OPTION IN ('승1패','전반')    THEN        ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ELSE NULL
        END AS 홈패_보정
FROM 
(

SELECT
            A.GAME_NUMBER,
            A.game_date,
--             A.SPORT_TYPE,
--             A.LEAGUE,
            A.BET_OPTION,
            A.HOME_TEAM,
            A.AWAY_TEAM,
            A.ALLOCATION_WIN AS 홈승배당,
            A.ALLOCATION_DRAW AS 홈무배당,
            A.ALLOCATION_LOSE AS 홈패배당,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINLEAGUETOTAKTAMES,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 승_승률,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWLEAGUETOTAKTAMES,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 무_승률,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSELEAGUETOTAKTAMES,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSELEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 패_승률,
--            SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINTOTAKTAMES,
  --          SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 ) AS 전체_승_승률,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWTOTAKTAMES,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWHITGAMES,
            ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_무_승률,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSETOTAKTAMES,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSEHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_패_승률,

((  ( MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_le_ev,

(( ( MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_le_ev,

( (( MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END)  ) *  A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_ev, 

(((             ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 )  ) *  A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_all_ev,
 
 
(((  ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) ) *   A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_all_ev,

(((     ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 )  ) * A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_evS


        FROM
            (
                SELECT A.GAME_NUMBER, A.SPORT_TYPE, A.LEAGUE, A.BET_OPTION, ALLOCATION_WIN, ALLOCATION_DRAW, ALLOCATION_LOSE, A.HOME_TEAM, A.AWAY_TEAM, A.game_date
                FROM kbo_stat.tb_betman_sd_game_now A , ( select  replace(B.TEAM_NAME, ' ', '')  as TEAM_NAME, TEAM_CODE from kbo_stat.tb_team_info B ) B 
                WHERE A.LEAGUE = 'KBO'
                AND A.SPORT_TYPE = '야구'
                -- AND  DATE_FORMAT(NOW()-1, '%Y%m%d') = '20250405' --   DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')-1
                AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y%m%d') =  DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')
                AND A.BET_OPTION NOT IN ( 'SUM','전반' ) 
                AND B.TEAM_CODE = 'KT'
                AND A.HOME_TEAM COLLATE utf8mb4_unicode_ci = B.TEAM_NAME
 
            ) A LEFT OUTER JOIN
            (
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESUKT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESUKT = '언더' AND BET_OPTION  IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESUKT = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESUKT = '언더' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_resuKT
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN
                UNION ALL
                
                SELECT SPORT_TYPE, BET_OPTION,LEAGUE, 0 AS ALLOCATION_WIN, ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESUKT = '무' AND BET_OPTION IN ('승패','핸디캡','승무패','전반 승무패') THEN 1
                                 WHEN GAME_RESUKT IN (1, '①') AND BET_OPTION = '승1패' THEN 1
                                 WHEN GAME_RESUKT IN (5, '⑤') AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESUKT = '무' AND BET_OPTION IN ('일반','핸디캡','승무패','전반 승무패') THEN 1
                                        WHEN GAME_RESUKT IN  (1, '①')  AND BET_OPTION = '승1패' THEN 1
                                        WHEN GAME_RESUKT IN  (5, '⑤')  AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_resuKT
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_DRAW
                UNION ALL
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, 0 AS ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESUKT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESUKT = '오버' AND BET_OPTION = '언더오버' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESUKT = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESUKT = '오버' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_resuKT
                 where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_LOSE
            ) B
            ON ( A.SPORT_TYPE = B.SPORT_TYPE
                AND A.BET_OPTION = B.BET_OPTION
                AND ( A.ALLOCATION_WIN = B.ALLOCATION_WIN OR A.ALLOCATION_DRAW = B.ALLOCATION_DRAW OR A.ALLOCATION_LOSE = B.ALLOCATION_LOSE )
                )

        GROUP BY A.GAME_NUMBER,
        	     A.game_date,
                 A.SPORT_TYPE,
                 A.LEAGUE,
                 A.BET_OPTION,
                 A.HOME_TEAM,
                 A.AWAY_TEAM,
                 A.ALLOCATION_WIN,
                 A.ALLOCATION_DRAW,
                 A.ALLOCATION_LOSE
ORDER BY 1
)  A, BALANCE B 
ORDER BY 1;




-- NC
INSERT INTO  kbo_stat.tb_match_resuNC
WITH BALANCE AS 
(
SELECT A.TEAMCODE, SUM(100점환산), ROUND( ( SUM(100점환산) - 300 ) / 300 , 3 ) +1  AS RATE
FROM 
(
-- 1
 SELECT * 
 FROM (
   WITH RecentGames AS (
      SELECT 
          home_team_code,
          winner,
          ROW_NUMBER() OVER (
              PARTITION BY home_team_code
              ORDER BY STR_TO_DATE(game_date, '%Y-%m-%d') DESC
          ) AS rn
      FROM tb_game_info
  )
  SELECT 
      a.home_team_code AS teamCode, '1 최근경기승리' AS SEQ , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) AS winCount , SUM(CASE WHEN a.winner = 'HOME' THEN 1 ELSE 0 END) * 10 AS 100점환산
  FROM RecentGames a
  JOIN tb_team_info b
    ON a.home_team_code = b.team_code
  WHERE a.rn <= 10
  AND a.home_team_code = 'NC'
  GROUP BY a.home_team_code 
 ) A

 
  UNION ALL 
 -- 2
 SELECT *
 FROM (
  WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_resuNC_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and  ( a_code = 'NC' OR h_code  = 'NC' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_resuNC_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ) ,
 
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_resuNC_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
 ),
 
 
 SCORE_RESUNC AS (
 
 select a.*,b.*,'HOME' AS HW -- HOME
 from tb_resuNC_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.home_id
 and b.h_code <> 'NC'
 
 union all
 
 select a.*,b.*,'AWAY' AS HW -- HOME
 from tb_resuNC_tab_team_pitching_boxscore_away a , SCORE b 
 where a.id = b.away_id
 and b.a_code <> 'NC'
 
 )
  
 SELECT 'NC' AS teamCode , '2 타율'  AS SEQ ,  round( sum(hit) / sum(ab), 3)   ,  round( sum(hit) / sum(ab), 3) * 3.3 * 100 
 from SCORE_RESUNC  a  
 ) A 
 
 UNION ALL
 -- 3
 SELECT *
 FROM (
 WITH GAME AS (
     select a_code, h_code, max(id) as id
         from tb_resuNC_tab_game_info
         where   gdate BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '%Y%m%d') + 0
            AND DATE_FORMAT(CURDATE(), '%Y%m%d') + 0
         and ( a_code = 'NC' OR h_code  = 'NC' )
         group by gdate, a_code, h_code
         
 ),
 
 PITCHING_BOX AS (
     select a.team_pitching_boxscore_id as id , b.a_code, b.h_code
         from tb_resuNC_tab_record_data a , GAME b 
   where a.game_info_id = b.id 
 ),
 
 SCORE AS (
 
 SELECT a.home_id , a.away_id , b.a_code, b.h_code
 FROM tb_resuNC_tab_team_pitching_boxscore a , PITCHING_BOX b 
 where a.id  = b.id
 
  
  
  
 ),
 
 SCORE_RESUNC AS (
 
 select a.*,b.*, 'HOME' AS HW -- HOME
 from tb_resuNC_tab_team_pitching_boxscore_away a  , SCORE b
 where a.id = b.home_id
 and b.h_code = 'NC'
 
 union all
 
 select a.*,b.*, 'AWAY' AS HW -- HOME
 from tb_resuNC_tab_team_pitching_boxscore_away a  , SCORE  b
 where a.id = b.away_id
 and b.a_code = 'NC'
 
 )
   
 SELECT 'NC', '3 방어율', ROUND( (SUM(er) / SUM(inn)) * 9 , 2) AS 전체방어율  , 100- ( ROUND( (SUM(er) / SUM(inn)) * 9 , 2) - 3.85 ) * 15  AS 100점환산 
 from SCORE_RESUNC  a   
 ) A
 
 UNION ALL 
 -- 4
 SELECT *
 FROM 
 ( 
 WITH param AS (
     SELECT  
         home_team_code ,
         away_team_code 
     FROM tb_game_info  a 
     WHERE home_team_code = 'NC'
     AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y-%m-%d') = a.game_date
     
 ),
 -- ① 시즌 맞대결 : 홈/원정 모두 포함
 matchup AS (
     SELECT
         p.home_team_code,
         p.away_team_code,
         COUNT(1) AS total_games,
         -- 홈팀이 홈일 때, 홈 승리 + 원정일 때, 원정 승리 합산
         SUM(
             CASE
                 WHEN (b.team_code = p.home_team_code AND c.team_code = p.away_team_code AND winner = 'HOME') THEN 1
                 WHEN (b.team_code = p.away_team_code AND c.team_code = p.home_team_code AND winner = 'AWAY') THEN 1
                 ELSE 0
             END
         ) AS home_team_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND (
             (b.team_code = p.home_team_code AND c.team_code = p.away_team_code) OR
             (b.team_code = p.away_team_code AND c.team_code = p.home_team_code)
           )
     GROUP BY p.home_team_code, p.away_team_code
 ),
 -- ② 시즌 홈경기 승률 (전체 홈경기 기준)
 home_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_home_games,
         SUM(CASE WHEN winner = 'HOME' THEN 1 ELSE 0 END) AS home_team_home_wins
     FROM tb_game_info a
     JOIN tb_team_info b ON a.home_team_code = b.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND b.team_code = p.home_team_code
     GROUP BY p.home_team_code
 ),
 -- ③ 시즌 원정경기 승률 (전체 원정경기 기준)
 away_games AS (
     SELECT
         p.home_team_code,
         COUNT(1) AS total_away_games,
         SUM(CASE WHEN winner = 'AWAY' THEN 1 ELSE 0 END) AS home_team_away_wins
     FROM tb_game_info a
     JOIN tb_team_info c ON a.away_team_code = c.team_code
     JOIN param p ON 1 = 1
     WHERE a.game_date BETWEEN '2025-03-22' AND '2035-10-31'
       AND c.team_code = p.home_team_code
     GROUP BY p.home_team_code
 )
 SELECT
   p.home_team_code  AS 홈팀명,
    '4 맞대결',
 --    c.team_name AS 상대팀명, 
     ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) AS 시즌맞대결승률
     ,ROUND(m.home_team_wins / NULLIF(m.total_games, 0), 3) * 100  AS 100점환산 
  
 FROM param p
 LEFT JOIN matchup m ON p.home_team_code = m.home_team_code AND p.away_team_code = m.away_team_code
 LEFT JOIN home_games h ON p.home_team_code = h.home_team_code
 LEFT JOIN away_games a ON p.home_team_code = a.home_team_code
 LEFT JOIN tb_team_info b ON p.home_team_code = b.team_code
 LEFT JOIN tb_team_info c ON p.away_team_code = c.team_code
 
 )  A 
 
 UNION ALL 
 -- 5
 
 SELECT *
 FROM 
 (
   WITH base AS (
     -- 시즌 전체 득점 데이터 (홈/원정 합산)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_score
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_resuNC_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_resuNC_tab_recent_vs_game
         WHERE gdate  >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 득점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS home_avg_score
     FROM tb_resuNC_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 득점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS away_avg_score
     FROM tb_resuNC_tab_recent_vs_game
     WHERE gdate  >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_score,
         RANK() OVER (ORDER BY season_avg_score DESC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_score,
         RANK() OVER (ORDER BY home_avg_score DESC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_score,
         RANK() OVER (ORDER BY away_avg_score DESC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code, 
     '5 시즌득점', 
     season_avg_score,
     case when season_avg_score >= 10 then 10 else season_avg_score end * 10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'NC' -- 'NC', 'NC' 
 ) A 
  
 UNION ALL 
 -- 6
 SELECT *
 FROM 
 (
 WITH base AS (
     -- 시즌 전체 실점 데이터 (홈/원정 구분 없음)
     SELECT
         team_name,
         ROUND(SUM(team_score) / COUNT(1), 1) AS season_avg_loNC
     FROM (
         SELECT
             h_name AS team_name,
             gdate,
             a_score AS team_score
         FROM tb_resuNC_tab_recent_vs_game
         WHERE gdate >= 20250322
 
         UNION ALL
 
         SELECT
             a_name AS team_name,
             gdate,
             h_score AS team_score
         FROM tb_resuNC_tab_recent_vs_game
         WHERE gdate >= 20250322
     ) sub
     WHERE team_name NOT IN ('드림', '나눔')
     GROUP BY team_name
 ),
 
 home AS (
     -- 홈 경기에서 실점 데이터
     SELECT
         h_name AS team_name,
         ROUND(SUM(a_score) / COUNT(1), 1) AS home_avg_loNC
     FROM tb_resuNC_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND h_name NOT IN ('드림', '나눔')
     GROUP BY h_name
 ),
 
 away AS (
     -- 원정 경기에서 실점 데이터
     SELECT
         a_name AS team_name,
         ROUND(SUM(h_score) / COUNT(1), 1) AS away_avg_loNC
     FROM tb_resuNC_tab_recent_vs_game
     WHERE gdate >= 20250322
       AND a_name NOT IN ('드림', '나눔')
     GROUP BY a_name
 ),
 
 ranked_base AS (
     SELECT
         team_name,
         season_avg_loNC,
         RANK() OVER (ORDER BY season_avg_loNC ASC) AS season_rank
     FROM base
 ),
 
 ranked_home AS (
     SELECT
         team_name,
         home_avg_loNC,
         RANK() OVER (ORDER BY home_avg_loNC ASC) AS home_rank
     FROM home
 ),
 
 ranked_away AS (
     SELECT
         team_name,
         away_avg_loNC,
         RANK() OVER (ORDER BY away_avg_loNC ASC) AS away_rank
     FROM away
 )
 
 SELECT
     z.team_code,
     '6 시즌실점', 
     b.season_avg_loNC,
     case when season_avg_loNC >= 10 then 10 else season_avg_loNC end * -10 AS 100점환산
 FROM ranked_base b
 LEFT JOIN ranked_home h ON b.team_name = h.team_name
 LEFT JOIN ranked_away a ON b.team_name = a.team_name
 LEFT JOIN tb_team_info z ON  b.team_name =  SUBSTRING_INDEX(z.team_name, ' ', 1) 
 WHERE z.team_code = 'NC' -- 'NC', 'NC'
 
 ) A
 
) A
GROUP BY A.TEAMCODE

)
SELECT  A.GAME_NUMBER,
		A.game_date,
        A.BET_OPTION,
        A.HOME_TEAM,
        A.AWAY_TEAM,
        A.홈승배당,
        A.홈무배당,
        A.홈패배당,
         A.승_승률,
        A.무_승률,
        A.패_승률,
        A.전체_승_승률,
        A.전체_무_승률,
        A.전체_패_승률,
        ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) AS 홈승_보정,
        CASE WHEN A.BET_OPTION IN ('승1패','전반') THEN ROUND( 100 - (  ROUND((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100,1) ) 
                        - ( ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ),1) ELSE NULL END AS 홈무_보정,
        CASE WHEN A.BET_OPTION IN ('일반','핸디캡','언더오버') THEN  100 - ROUND(((A.승_승률 + A.전체_승_승률)/2 * B.RATE * 100 ),1) 
          WHEN A.BET_OPTION IN ('승1패','전반')    THEN        ROUND((A.패_승률 + A.전체_패_승률)/2 * B.RATE * 100,1) ELSE NULL
        END AS 홈패_보정
FROM 
(

SELECT
            A.GAME_NUMBER,
            A.game_date,
--             A.SPORT_TYPE,
--             A.LEAGUE,
            A.BET_OPTION,
            A.HOME_TEAM,
            A.AWAY_TEAM,
            A.ALLOCATION_WIN AS 홈승배당,
            A.ALLOCATION_DRAW AS 홈무배당,
            A.ALLOCATION_LOSE AS 홈패배당,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINLEAGUETOTANCAMES,
--            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 승_승률,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWLEAGUETOTANCAMES,
--            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWLEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 무_승률,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSELEAGUETOTANCAMES,
--            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSELEAGUEHITGAMES,
            MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) AS 패_승률,
--            SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS WINTOTANCAMES,
  --          SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS WINHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 ) AS 전체_승_승률,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS DRAWTOTANCAMES,
--            SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS DRAWHITGAMES,
            ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_무_승률,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) AS LOSETOTANCAMES,
--            SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) AS LOSEHITGAMES,
            ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) AS 전체_패_승률,

((  ( MAX(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_le_ev,

(( ( MAX(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END) ) * A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_le_ev,

( (( MAX(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.LEAGUE = B.LEAGUE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_RATE ELSE NULL END)  ) *  A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_ev, 

(((             ROUND(SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_WIN = B.ALLOCATION_WIN AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) , 2 )  ) *  A.ALLOCATION_WIN ) - 1 ) * 10000 AS win_all_ev,
 
 
(((  ROUND( SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_DRAW NOT IN ( 0,1 ) AND A.ALLOCATION_DRAW = B.ALLOCATION_DRAW AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 ) ) *   A.ALLOCATION_DRAW ) - 1 ) * 10000 AS draw_all_ev,

(((     ROUND(SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.HIT_GAME_CNT ELSE NULL END) / SUM(CASE WHEN A.ALLOCATION_LOSE = B.ALLOCATION_LOSE AND A.BET_OPTION = B.BET_OPTION AND A.SPORT_TYPE = B.SPORT_TYPE THEN B.ALL_GAME_CNT ELSE NULL END) ,2 )  ) * A.ALLOCATION_LOSE ) - 1 ) * 10000 AS lose_le_evS


        FROM
            (
                SELECT A.GAME_NUMBER, A.SPORT_TYPE, A.LEAGUE, A.BET_OPTION, ALLOCATION_WIN, ALLOCATION_DRAW, ALLOCATION_LOSE, A.HOME_TEAM, A.AWAY_TEAM, A.game_date
                FROM kbo_stat.tb_betman_sd_game_now A , ( select  replace(B.TEAM_NAME, ' ', '')  as TEAM_NAME, TEAM_CODE from kbo_stat.tb_team_info B ) B 
                WHERE A.LEAGUE = 'KBO'
                AND A.SPORT_TYPE = '야구'
                -- AND  DATE_FORMAT(NOW()-1, '%Y%m%d') = '20250405' --   DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')-1
                AND DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 0 DAY), '%Y%m%d') =  DATE_FORMAT(A.DEADLINE_DATE, '%Y%m%d')
                AND A.BET_OPTION NOT IN ( 'SUM','전반' ) 
                AND B.TEAM_CODE = 'NC'
                AND A.HOME_TEAM COLLATE utf8mb4_unicode_ci = B.TEAM_NAME
 
            ) A LEFT OUTER JOIN
            (
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESUNC = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESUNC = '언더' AND BET_OPTION  IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESUNC = '승' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESUNC = '언더' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_resuNC
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_WIN
                UNION ALL
                
                SELECT SPORT_TYPE, BET_OPTION,LEAGUE, 0 AS ALLOCATION_WIN, ALLOCATION_DRAW, 0 AS ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESUNC = '무' AND BET_OPTION IN ('승패','핸디캡','승무패','전반 승무패') THEN 1
                                 WHEN GAME_RESUNC IN (1, '①') AND BET_OPTION = '승1패' THEN 1
                                 WHEN GAME_RESUNC IN (5, '⑤') AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESUNC = '무' AND BET_OPTION IN ('일반','핸디캡','승무패','전반 승무패') THEN 1
                                        WHEN GAME_RESUNC IN  (1, '①')  AND BET_OPTION = '승1패' THEN 1
                                        WHEN GAME_RESUNC IN  (5, '⑤')  AND BET_OPTION = '승5패' THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_resuNC
                where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_DRAW
                UNION ALL
                SELECT SPORT_TYPE, BET_OPTION, LEAGUE, 0 AS ALLOCATION_WIN, 0 AS ALLOCATION_DRAW, ALLOCATION_LOSE
                     , COUNT(1) AS ALL_GAME_CNT
                     , SUM(CASE WHEN GAME_RESUNC = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                WHEN GAME_RESUNC = '오버' AND BET_OPTION = '언더오버' THEN 1 ELSE 0 END ) AS HIT_GAME_CNT
                     , ROUND( SUM(CASE WHEN GAME_RESUNC = '패' AND BET_OPTION IN ('승패','핸디캡','승1패','승5패','승무패','전반 승무패','소수핸디캡') THEN 1
                                       WHEN GAME_RESUNC = '오버' AND BET_OPTION IN ('전반 언더오버', '언더오버')  THEN 1 ELSE 0 END ) / COUNT(1) ,2 ) AS HIT_GAME_RATE
                FROM kbo_stat.tb_betman_sd_game_resuNC
                 where SPORT_TYPE = '야구'
                GROUP BY SPORT_TYPE, BET_OPTION, LEAGUE, ALLOCATION_LOSE
            ) B
            ON ( A.SPORT_TYPE = B.SPORT_TYPE
                AND A.BET_OPTION = B.BET_OPTION
                AND ( A.ALLOCATION_WIN = B.ALLOCATION_WIN OR A.ALLOCATION_DRAW = B.ALLOCATION_DRAW OR A.ALLOCATION_LOSE = B.ALLOCATION_LOSE )
                )

        GROUP BY A.GAME_NUMBER,
        	     A.game_date,
                 A.SPORT_TYPE,
                 A.LEAGUE,
                 A.BET_OPTION,
                 A.HOME_TEAM,
                 A.AWAY_TEAM,
                 A.ALLOCATION_WIN,
                 A.ALLOCATION_DRAW,
                 A.ALLOCATION_LOSE
ORDER BY 1
)  A, BALANCE B 
ORDER BY 1;

