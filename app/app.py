# app/app.py
from flask import Flask, render_template_string, request, jsonify, url_for
import os
import pymysql
import math
from urllib.parse import urlencode

app = Flask(__name__)

# --- Configuration ---
RECORDS_PER_PAGE = 25

# --- Database connection details ---
db_host = os.environ.get('DB_HOST', '[MYSQL_ZEROTIER_IP_ADDRESS]')
db_user = os.environ.get('DB_USER', 'iot_user')
db_password = os.environ.get('DB_PASSWORD', '######')
db_name = os.environ.get('DB_NAME', 'iot')

def get_db_connection():
  try:
    connection = pymysql.connect(host=db_host,
                                 user=db_user,
                                 password=db_password,
                                 database=db_name,
                                 cursorclass=pymysql.cursors.DictCursor,
                                 connect_timeout=5)
    return connection
  except pymysql.Error as e:
    print(f"Error connecting to MySQL Database: {e}")
    app.logger.error(f"Database connection error: {e}")
    return None

# --- HTML Template ---
HTML_TEMPLATE = """
<!doctype html>
<html lang="en">
<head>
 <meta charset="utf-8">
 <meta name="viewport" content="width=device-width, initial-scale=1">
 <title>IoT Sensor Data</title>
 <style>
 body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; margin: 20px; background-color: #f8f9fa; color: #212529; }
 .container { max-width: 1200px; margin: auto; background-color: #fff; padding: 20px 30px; border-radius: 8px; box-shadow: 0 0 15px rgba(0,0,0,0.1); }
 h1 { color: #343a40; border-bottom: 2px solid #dee2e6; padding-bottom: 10px; margin-bottom: 20px; }
 .search-form { background-color: #f8f9fa; padding: 15px 20px; border-radius: 5px; margin-bottom: 25px; border: 1px solid #dee2e6; display: flex; align-items: center; flex-wrap: wrap; gap: 15px;}
 .search-form label { font-weight: 500; margin-right: 5px; color: #495057;}
 .search-form input[type="datetime-local"] { padding: 8px 10px; border: 1px solid #ced4da; border-radius: 4px; font-size: 0.9em; }
 .search-form button { padding: 8px 15px; border: none; border-radius: 4px; cursor: pointer; font-size: 0.9em; }
 .search-form .btn-search { background-color: #007bff; color: white; }
 .search-form .btn-search:hover { background-color: #0056b3; }
 .search-form .btn-clear { background-color: #6c757d; color: white; }
 .search-form .btn-clear:hover { background-color: #5a6268; }
 .search-active-filters { font-size: 0.9em; color: #6c757d; margin-bottom: 15px; }
 table { border-collapse: collapse; width: 100%; margin-top: 5px; background-color: #fff; font-size: 0.9em; }
 th, td { border: 1px solid #dee2e6; padding: 10px 12px; text-align: left; vertical-align: middle; }
 th { background-color: #e9ecef; font-weight: 600; color: #495057; white-space: nowrap;}
 tr:nth-child(even) { background-color: #f8f9fa; }
 tr:hover { background-color: #e9ecef; }
 .error { color: #dc3545; background-color: #f8d7da; border: 1px solid #f5c6cb; padding: 10px; border-radius: 4px; margin-top: 15px; }
 .no-data { color: #6c757d; margin-top: 15px; text-align: center; padding: 20px; background-color: #f8f9fa; border: 1px solid #dee2e6; border-radius: 4px;}
 .pagination-container { display: flex; justify-content: space-between; align-items: center; margin-top: 25px; padding-top: 15px; border-top: 1px solid #dee2e6; font-size: 0.9em; }
 .pagination-info { color: #6c757d; }
 .pagination-links a, .pagination-links span {
 display: inline-block; padding: 6px 12px;
 text-decoration: none;
 border: 1px solid #dee2e6;
 color: white;
 background-color: #007bff;
 margin-left: -1px;
 }
 .pagination-links a:first-child, .pagination-links span:first-child { margin-left: 0; border-top-left-radius: 4px; border-bottom-left-radius: 4px;}
 .pagination-links a:last-child, .pagination-links span:last-child { border-top-right-radius: 4px; border-bottom-right-radius: 4px;}
 .pagination-links span.current {
 background-color: grey;
 color: white;
 border-color: #6c757d;
 z-index: 2;
 position: relative;
 }
 .pagination-links span.disabled {
 color: #adb5bd;
 background-color: #e9ecef;
 border-color: #dee2e6;
 cursor: default;
 }
 .pagination-links a:hover {
 background-color: #0056b3;
 border-color: #0056b3;
 z-index: 1;
 position: relative;
 }
 .pagination-links span.dots { border: none; padding: 6px 4px; color: #6c757d; background-color: transparent; }
 .footer { margin-top: 30px; font-size: 0.8em; color: #6c757d; text-align: center; padding-top: 15px; border-top: 1px solid #dee2e6;}
 </style>
</head>
<body>
<div class="container">
 <h1>IoT Sensor Data</h1>
 <form method="GET" action="{{ url_for('index') }}" class="search-form">
 <label for="date_from">Date from:</label>
 <input type="datetime-local" id="date_from" name="date_from" value="{{ date_from or '' }}">
 <label for="date_to">Date to:</label>
 <input type="datetime-local" id="date_to" name="date_to" value="{{ date_to or '' }}">
 <button type="submit" class="btn-search">Search</button>
 <a href="{{ url_for('index') }}" class="btn-clear" style="text-decoration: none;">Clear</a>
 </form>
 {% if date_from or date_to %}
 <div class="search-active-filters">
 Active filters:
 {% if date_from %} Date from {{ date_from }}{% endif %}
 {% if date_to %} {{ ' to ' if date_from else 'Date to ' }}{{ date_to }}{% endif %}
 </div>
 {% endif %}
 {% if error %}
 <p class="error"><strong>Error:</strong> {{ error }}</p>
 {% elif data %}
 <table>
 <thead>
 <tr>
 <th>Timestamp</th>
 <th>Temperature (°C)</th>
 <th>Water Level (%)</th>
 <th>Humidity (%)</th>
 <th>Light (lux)</th>
 <th>CO₂ (ppm)</th>
 <th>Pressure (hPa)</th>
 <th>Noise (dB)</th>
 </tr>
 </thead>
 <tbody>
 {% for row in data %}
 <tr>
 <td>{{ row.timestamp.strftime('%Y-%m-%d %H:%M:%S') if row.timestamp else 'N/A' }}</td>
 <td>{{ row.temperature_C }}</td>
 <td>{{ row.water_level_percent }}</td>
 <td>{{ row.humidity_percent }}</td>
 <td>{{ row.light_lux }}</td>
 <td>{{ row.co2_ppm }}</td>
 <td>{{ row.pressure_hPa }}</td>
 <td>{{ row.noise_dB }}</td>
 </tr>
 {% endfor %}
 </tbody>
 </table>
 <div class="pagination-container">
 <div class="pagination-info">
 {% if total_records > 0 %}
 Showing records {{ (page - 1) * per_page + 1 }} to {{ min(page * per_page, total_records) }} of {{ total_records }}
 {% else %}
 No records found
 {% endif %}
 </div>
 <div class="pagination-links">
 {% if total_pages > 1 %}
 {% set url_params = {} %}
 {% if date_from %}{% set _ = url_params.update({'date_from': date_from}) %}{% endif %}
 {% if date_to %}{% set _ = url_params.update({'date_to': date_to}) %}{% endif %}
 {% if page > 1 %}
 <a href="{{ url_for('index', page=1, **url_params) }}" title="First page">&laquo;&laquo;</a>
 <a href="{{ url_for('index', page=page-1, **url_params) }}" title="Previous page">&laquo;</a>
 {% else %}
 <span class="disabled">&laquo;&laquo;</span>
 <span class="disabled">&laquo;</span>
 {% endif %}
 {% set start_page = max(1, page - 2) %}
 {% set end_page = min(total_pages, page + 2) %}
 {% if start_page > 1 %}
 <a href="{{ url_for('index', page=1, **url_params) }}">1</a>
 {% if start_page > 2 %}
 <span class="dots">...</span>
 {% endif %}
 {% endif %}
 {% for p in range(start_page, end_page + 1) %}
 {% if p == page %}
 <span class="current">{{ p }}</span>
 {% else %}
 <a href="{{ url_for('index', page=p, **url_params) }}">{{ p }}</a>
 {% endif %}
 {% endfor %}
 {% if end_page < total_pages %}
 {% if end_page < total_pages - 1 %}
 <span class="dots">...</span>
 {% endif %}
 <a href="{{ url_for('index', page=total_pages, **url_params) }}">{{ total_pages }}</a>
 {% endif %}
 {% if page < total_pages %}
 <a href="{{ url_for('index', page=page + 1, **url_params) }}" title="Next page">&raquo;</a>
 <a href="{{ url_for('index', page=total_pages, **url_params) }}" title="Last page">&raquo;&raquo;</a>
 {% else %}
 <span class="disabled">&raquo;</span>
 <span class="disabled">&raquo;&raquo;</span>
 {% endif %}
 {% endif %}
 </div>
 </div>
 {% else %}
 {% if date_from or date_to %}
 <p class="no-data">No records found matching the search criteria.</p>
 {% else %}
 <p class="no-data">No data found or available.</p>
 {% endif %}
 {% endif %}
 <p class="footer">Data from MySQL database: {{ db_host }}/{{ db_name }}</p>
</div>
</body>
</html>
"""

# --- Flask Route ---
@app.route('/')
def index():
    try:
        page = request.args.get('page', 1, type=int)
        if page < 1: page = 1
    except ValueError:
        page = 1
    
    date_from = request.args.get('date_from')
    date_to = request.args.get('date_to')
    
    conn = None
    data = None
    total_records = 0
    total_pages = 0
    error_message = None
    
    where_clauses = []
    sql_params = []
    
    if date_from:
        try:
            mysql_date_from = date_from.replace('T', ' ')
            where_clauses.append("timestamp >= %s")
            sql_params.append(mysql_date_from)
        except ValueError:
            error_message = "Invalid 'Date from' format."
            date_from = None
            
    if date_to:
        try:
            mysql_date_to = date_to.replace('T', ' ')
            where_clauses.append("timestamp <= %s")
            sql_params.append(mysql_date_to)
        except ValueError:
            if not error_message: error_message = "Invalid 'Date to' format."
            date_to = None
            
    where_sql = ""
    if where_clauses:
        where_sql = " WHERE " + " AND ".join(where_clauses)
        
    if not error_message:
        try:
            conn = get_db_connection()
            if conn:
                with conn.cursor() as cursor:
                    count_sql = f"SELECT COUNT(*) as count FROM iot_data{where_sql}"
                    cursor.execute(count_sql, tuple(sql_params))
                    result = cursor.fetchone()
                    total_records = result['count'] if result else 0
                    
                    if total_records > 0:
                        total_pages = math.ceil(total_records / RECORDS_PER_PAGE)
                        if page > total_pages: page = total_pages
                        offset = (page - 1) * RECORDS_PER_PAGE
                        data_sql = f"""
                            SELECT timestamp, temperature_C, water_level_percent, humidity_percent, 
                            light_lux, co2_ppm, pressure_hPa, noise_dB 
                            FROM iot_data
                            {where_sql} 
                            ORDER BY timestamp DESC 
                            LIMIT %s OFFSET %s
                        """
                        limit_offset_params = tuple(sql_params) + (RECORDS_PER_PAGE, offset)
                        cursor.execute(data_sql, limit_offset_params)
                        data = cursor.fetchall()
                    else:
                        page = 1
                        total_pages = 1
            else:
                error_message = "Failed to connect to the database."
        except pymysql.Error as e:
            error_message = f"Database error: {e}"
            app.logger.error(f"Database error: {e}")
        except Exception as e:
            error_message = f"An unexpected error occurred: {e}"
            app.logger.error(f"Unexpected error: {e}", exc_info=True)
        finally:
            if conn:
                conn.close()
                
    url_params = {}
    if date_from: url_params['date_from'] = date_from
    if date_to: url_params['date_to'] = date_to
    
    return render_template_string(
        HTML_TEMPLATE,
        data=data,
        error=error_message,
        db_host=db_host,
        db_name=db_name,
        page=page,
        total_pages=total_pages,
        total_records=total_records,
        per_page=RECORDS_PER_PAGE,
        date_from=date_from,
        date_to=date_to,
        url_params=url_params,
        min=min,
        max=max,
        range=range,
        url_for=url_for
    )

# Health check route
@app.route('/health')
def health_check():
    return jsonify({"status": "ok"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
