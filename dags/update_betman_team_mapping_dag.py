from pathlib import Path

import pendulum
from airflow.decorators import dag, task
from airflow.providers.mysql.hooks.mysql import MySqlHook


SQL_DIR = Path("/opt/airflow/sql")
MYSQL_CONN_ID = "kbo_mysql"


@dag(
    dag_id="update_betman_team_mapping_dag",
    description="매일 06시에 betman 경기 결과 테이블의 팀명/리그명을 매핑 테이블 기준으로 정규화하는 배치",
    start_date=pendulum.datetime(2026, 4, 25, tz="Asia/Seoul"),
    schedule="0 6 * * *",
    catchup=False,
    max_active_runs=1,
    tags=["kbo", "mysql", "team-mapping", "daily"],
)
def update_betman_team_mapping_dag():

    @task
    def execute_update_betman_team_mapping():
        sql_path = SQL_DIR / "update_betman_team_mapping.sql"

        if not sql_path.exists():
            raise FileNotFoundError(f"SQL file not found: {sql_path}")

        sql = sql_path.read_text(encoding="utf-8")

        print("===== 실행 SQL 파일 =====")
        print(sql_path)
        print("===== SQL 내용 =====")
        print(sql)

        mysql_hook = MySqlHook(mysql_conn_id=MYSQL_CONN_ID)
        mysql_hook.run(sql, autocommit=True)

        print("betman 팀명/리그명 매핑 업데이트 완료")

    execute_update_betman_team_mapping()


update_betman_team_mapping_dag()
