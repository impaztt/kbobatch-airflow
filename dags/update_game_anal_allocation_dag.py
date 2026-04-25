from pathlib import Path

import pendulum
from airflow.decorators import dag, task
from airflow.providers.mysql.hooks.mysql import MySqlHook


SQL_DIR = Path("/opt/airflow/sql")
MYSQL_CONN_ID = "kbo_mysql"


@dag(
    dag_id="update_game_anal_allocation_dag",
    description="매시간 15분, 35분, 55분에 배당 분석 allocation 테이블을 재생성하는 배치",
    start_date=pendulum.datetime(2026, 4, 25, tz="Asia/Seoul"),
    schedule="15,35,55 * * * *",
    catchup=False,
    max_active_runs=1,
    tags=["kbo", "mysql", "allocation", "20min"],
)
def update_game_anal_allocation_dag():

    @task
    def execute_update_game_anal_allocation():
        sql_path = SQL_DIR / "update_game_anal_allocation.sql"

        if not sql_path.exists():
            raise FileNotFoundError(f"SQL file not found: {sql_path}")

        sql = sql_path.read_text(encoding="utf-8")

        print("===== 실행 SQL 파일 =====")
        print(sql_path)
        print("===== SQL 내용 =====")
        print(sql)

        mysql_hook = MySqlHook(mysql_conn_id=MYSQL_CONN_ID)
        mysql_hook.run(sql, autocommit=True)

        print("tb_betman_sd_game_anal_allocation 재생성 완료")

    execute_update_game_anal_allocation()


update_game_anal_allocation_dag()
