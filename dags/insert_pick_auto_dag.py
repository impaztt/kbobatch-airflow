from pathlib import Path

import pendulum
from airflow.decorators import dag, task
from airflow.providers.mysql.hooks.mysql import MySqlHook


SQL_DIR = Path("/opt/airflow/sql/pick_auto")
MYSQL_CONN_ID = "kbo_mysql"


SQL_FILES = [
    "01_insert_pick_auto.sql",
    "02_update_pick_auto.sql",
]


@dag(
    dag_id="insert_pick_auto_dag",
    description="매 15분마다 tb_pick 자동 픽 INSERT 후 UPDATE를 순차 실행하는 배치",
    start_date=pendulum.datetime(2026, 4, 26, tz="Asia/Seoul"),
    schedule="*/15 * * * *",
    catchup=False,
    max_active_runs=1,
    tags=["kbo", "mysql", "pick", "15min"],
)
def insert_pick_auto_dag():

    previous_task = None

    for index, sql_file in enumerate(SQL_FILES, start=1):

        @task
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


insert_pick_auto_dag()
