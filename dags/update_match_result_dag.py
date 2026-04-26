from pathlib import Path

import pendulum
from airflow.decorators import dag, task
from airflow.providers.mysql.hooks.mysql import MySqlHook


SQL_DIR = Path("/opt/airflow/sql")
MYSQL_CONN_ID = "kbo_mysql"


@dag(
    dag_id="update_match_result_dag",
    description="매시간 10분에 tb_match_result 데이터를 생성/갱신하는 배치",
    start_date=pendulum.datetime(2026, 4, 26, tz="Asia/Seoul"),
    schedule="10 * * * *",
    catchup=False,
    max_active_runs=1,
    tags=["kbo", "mysql", "match-result", "hourly"],
)
def update_match_result_dag():

    @task
    def execute_update_match_result():
        sql_path = SQL_DIR / "update_match_result.sql"

        if not sql_path.exists():
            raise FileNotFoundError(f"SQL file not found: {sql_path}")

        sql = sql_path.read_text(encoding="utf-8")

        print("===== 실행 SQL 파일 =====")
        print(sql_path)
        print("===== SQL 길이 =====")
        print(f"{len(sql)} characters")

        mysql_hook = MySqlHook(mysql_conn_id=MYSQL_CONN_ID)
        mysql_hook.run(sql, autocommit=True, split_statements=True)

        print("tb_match_result 배치 실행 완료")

    execute_update_match_result()


update_match_result_dag()
