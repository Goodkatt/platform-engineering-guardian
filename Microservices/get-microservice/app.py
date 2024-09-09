from flask import Flask, jsonify
import mysql.connector
import os

app = Flask(__name__)

# Read database credentials from files
with open('/mnt/secrets-store/dbusername') as f:
    db_username = f.read().strip()
with open('/mnt/secrets-store/dbpassword') as f:
    db_password = f.read().strip()

# MySQL connection setup
def get_db_connection():
    connection = mysql.connector.connect(
        host='demodb.cf6vfrnlibdp.eu-west-1.rds.amazonaws.com',
        user=db_username,
        password=db_password,
        database='demodb'
    )
    return connection

@app.route('/get_people', methods=['GET'])
def get_people():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute('SELECT * FROM Person')
    people = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify(people)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
