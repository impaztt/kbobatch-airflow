from pathlib import Path

import pendulum
from airflow.decorators import dag, task
from airflow.providers.mysql.hooks.mysql import MySqlHook


SQL_DIR = Path("/opt/airflow/sql/match_result")
MYSQL_CONN_ID = "kbo_mysql"


SQL_FILES = [
    "01_delete_today.sql",
    "02_insert_ss.sql",
    "03_insert_lg.sql",
    "03_insert_wo.sql",
    "05_insert_hh.sql",
    "06_insert_ht.sql",
    "07_insert_ob.sql",
    "08_insert_sk.sql",
    "09_insert_lt.sql",
    "10_insert_kt.sql",
    "11_insert_nc.sql",
]


@dag(
    dag_id="update_match_result_dag",
    description="매시간 10분에 match result 삭제 후 팀별 INSERT 10개를 순차 실행하는 배치",
    start_date=pendulum.datetime(2026, 4, 26, tz="Asia/Seoul"),
    schedule="10 * * * *",
    catchup=False,
    max_active_runs=1,
    tags=["kbo", "mysql", "match-result", "hourly"],
)
def update_match_result_dag():

    previous_task = None

    for index, sql_file in enumerate(SQL_FILES, start=1):

        @task(
            task_id=f"step_{index:02d}_{sql_file.replace('.sql', '')}"
        )
        def execute_sql_file(sql_file_name: str):
            sql_path = SQL_DIR / sql_file_name

            if not sql_path.exists():
                raise FileNotFoundError(f"SQL file not found: {sql_path}")

            sql = sql_path.read_text(encoding="utf-8").strip()

            if not sql:
                raise ValueError(f"SQL file is empty: {sql_path}")

            print("===== 실행 SQL 파일 =====")
            print(sql_path)
            print("===== SQL 길이 =====")
            print(f"{len(sql)} characters")

            mysql_hook = MySqlHook(mysql_conn_id=MYSQL_CONN_ID)
            mysql_hook.run(sql, autocommit=True, split_statements=False)

            print(f"SQL 실행 완료: {sql_file_name}")

        current_task = execute_sql_file.override(
            task_id=f"step_{index:02d}_{sql_file.replace('.sql', '').replace('_', '-')}"
        )(sql_file)

        if previous_task:
            previous_task >> current_task

        previous_task = current_task


update_match_result_dag()
