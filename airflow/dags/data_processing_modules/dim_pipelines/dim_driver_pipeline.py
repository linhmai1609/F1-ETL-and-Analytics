# import common.http as http
import pandas as pd
from airflow.models import Connection
import psycopg2
from psycopg2.pool import ThreadedConnectionPool
import logging
import requests

def get_from_url(url):
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        print(f"An error occurred: {e}")
        return None


class DimDriverPipeline:
    def __init__(self):
        # config = pd.read_csv('./config.csv')
        # self.url = config.loc[config['Table'] == 'dim_driver', 'URL'].values[0]
        self.url = 'https://api.openf1.org/v1/drivers'

        # Set up logging
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        self.insert_statements = []

    def get_driver_data(self) -> pd.DataFrame:
        json_data = get_from_url(self.url)
        return pd.DataFrame(json_data)
    
    def driver_data_insert_grouping(self, df: pd.DataFrame) -> None:

        # Function to add extra apostrophe to each occurrence
        def double_apostrophes(val):
            if isinstance(val, str) and "'" in val:
                return val.replace("'", "''")  # Replace each ' with ''
            return val
            
        # Apply the function to all string columns in the DataFrame
        df = df.applymap(double_apostrophes)
        df.drop(columns=['session_key'], inplace=True)
        df['driver_id'] = df['meeting_key'].astype(str)+'_'+df['driver_number'].astype(str)
        # df['driver_id'] = df['driver_id'].str.replace(' ', '-').str.lower()
        df.rename(columns={'meeting_key': 'effective_from_meeting'}, inplace=True)
        df['effective_to_meeting'] = df['effective_from_meeting']
        df['is_latest'] = True

        df.sort_values(by=['full_name', 'effective_from_meeting'], inplace=True)
        # df.to_csv("dim_driver_debug.csv", index=False)

        grouped = df.groupby('full_name')
        for group_key, group_df in grouped:
            tmp_insert_statement = f"""
                INSERT INTO dim_driver ({', '.join(df.columns.to_list())}) VALUES 
            """
            insert_statements: list[str] = []
            for _, row in group_df.iterrows():
                insert_statements.append(f"""({', '.join(f"'{word}'" for word in row)})""")
                # insert_statements.append(tmp_insert_statement + f"""({', '.join(f"'{word}'" for word in row)}); """)
            tmp_insert_statement = tmp_insert_statement + ', ' .join(insert_statements)
            self.insert_statements.append(tmp_insert_statement)
            # self.insert_statements.append(insert_statements)


    def load_data(self, conn: Connection) -> None:
        # connection = conn.get_conn()
        pool = ThreadedConnectionPool(1, 5,
                                      database =conn.schema,
                                        user = conn.login,
                                        password = conn.password,
                                        host = conn.host,
                                        port = conn.port
                                    )
                                      
        connection = None
        try:
            connection = pool.getconn()
            with connection.cursor() as cursor:
                # for statement_group in self.insert_statements:
                for statement in self.insert_statements:
                    # for statement in statement_group:
                    try: 
                        self.logger.info(f"Executing: {statement}")
                        cursor.execute(statement)
                        connection.commit()
                    except Exception as e:
                        self.logger.error(f"Error executing statement: {e}")
                        connection.rollback()
                        raise e

        except Exception as e:
            self.logger.error(f"Error during database operation: {e}")
            if connection:
                connection.rollback()
        finally:
            pool.closeall()
            # connection.close()

if __name__ == "__main__":
    # conn = psycopg2.connect(
    #     database="f1_analytics",
    #     user='admin',
    #     password='pAssw0rd',
    #     host='localhost',
    #     port='5432'
    # )
    conn = Connection(
        conn_id='f1_analytics_db',
        conn_type='postgres',
        host='localhost',
        login='admin',
        password='pAssw0rd',
        schema='f1_analytics',
        port=5432
    )
    pipeline = DimDriverPipeline()
    df = pipeline.get_driver_data()
    pipeline.logger.info(f"Extracted {len(df)} records from source.")
    pipeline.driver_data_insert_grouping(df)
    pipeline.load_data(conn)  # You need to provide a valid Connection object here
    # with open("output.txt", "w") as f:
        # print(pipeline.insert_statements[0], file=f)