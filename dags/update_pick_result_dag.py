from pathlib import Path

import pendulum
from airflow.decorators import dag, task
from airflow.providers.mysql.hooks.mysql import MySqlHook


SQL_DIR = Path("/opt/airflow/sql")
MYSQL_CONN_ID = "kbo_mysql"


@dag(
    dag_id="update_pick_result_dag",
    description="10분마다 경기 결과를 기준으로 tb_pick.pick_result를 업데이트하는 배치",
    start_date=pendulum.datetime(2026, 4, 25, tz="Asia/Seoul"),
    schedule="*/10 * * * *",
    catchup=False,
    max_active_runs=1,
    tags=["kbo", "mysql", "pick", "10min"],
)
def update_pick_result_dag():

    @task
    def execute_update_pick_result():
        sql_path = SQL_DIR / "update_pick_result.sql"

        if not sql_path.exists():
            raise FileNotFoundError(f"SQL file not found: {sql_path}")

        sql = sql_path.read_text(encoding="utf-8")

        print("===== 실행 SQL 파일 =====")
        print(sql_path)
        print("===== SQL 내용 =====")
        print(sql)

        mysql_hook = MySqlHook(mysql_conn_id=MYSQL_CONN_ID)
        mysql_hook.run(sql, autocommit=True)

        print("tb_pick 경기 결과 업데이트 완료")

    execute_update_pick_result()


update_pick_result_dag()
