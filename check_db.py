import pymysql
import os
from dotenv import load_dotenv

load_dotenv('/var/www/nounours/API/python-api/.env')

conn = pymysql.connect(
    host=os.getenv('DB_HOST', 'localhost'),
    user=os.getenv('DB_USER', 'root'), 
    password=os.getenv('DB_PASSWORD', ''),
    database=os.getenv('DB_NAME', 'SAE501'),
    cursorclass=pymysql.cursors.DictCursor
)

with conn.cursor() as cursor:
    cursor.execute("DESCRIBE COMPTES")
    columns = cursor.fetchall()
    print([col['Field'] for col in columns])

conn.close()
