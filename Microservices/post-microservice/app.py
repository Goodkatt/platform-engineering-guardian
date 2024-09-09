from flask import Flask, request, jsonify
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

@app.route('/add_person', methods=['POST'])
def add_person():
    data = request.get_json()
    person_id = data.get('PersonID')
    full_name = data.get('FullName')
    if not person_id or not full_name:
        return jsonify({'error': 'Invalid input'}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('INSERT INTO Person (PersonID, FullName) VALUES (%s, %s)', (person_id, full_name))
        conn.commit()
        return jsonify({'message': 'Person added successfully'}), 201
    except mysql.connector.Error as err:
        return jsonify({'error': str(err)}), 500
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)