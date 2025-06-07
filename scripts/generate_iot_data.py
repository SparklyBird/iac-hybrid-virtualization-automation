import mysql.connector
from datetime import datetime, timedelta, timezone
import random

# Connection configuration
conn = mysql.connector.connect(
    host="[MYSQL_ZEROTIER_IP_ADDRESS]",
    user="iot_user",
    password="######",
    database="iot"
)
cursor = conn.cursor()

# Time interval
start_time = datetime(2024, 10, 1, tzinfo=timezone.utc)
end_time = datetime(2025, 4, 1, tzinfo=timezone.utc)
time_step = timedelta(seconds=30)
current_time = start_time

# Initial values
temperature = 22.0
water = 50.0
humidity = 60.0
light = 500.0
co2 = 600.0
pressure = 1013.0
noise = 50.0

# Ranges
ranges = {
    "temperature": (15, 30),
    "water": (0, 100),
    "humidity": (30, 90),
    "light": (0, 1000),
    "co2": (400, 1000),
    "pressure": (980, 1050),
    "noise": (30, 90)
}

# Smooth oscillation
def smooth_random(prev, min_val, max_val, delta):
    value = prev + random.uniform(-delta, delta)
    return max(min(value, max_val), min_val)

# Prepare SQL
insert_sql = """
INSERT INTO iot_data (
    timestamp, temperature_C, water_level_percent,
    humidity_percent, light_lux, co2_ppm,
    pressure_hPa, noise_dB
) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
"""

count = 0
while current_time <= end_time:
    temperature = smooth_random(temperature, *ranges["temperature"], delta=0.4)
    water = smooth_random(water, *ranges["water"], delta=0.5)
    humidity = smooth_random(humidity, *ranges["humidity"], delta=0.5)
    light = smooth_random(light, *ranges["light"], delta=15)
    co2 = smooth_random(co2, *ranges["co2"], delta=10)
    pressure = smooth_random(pressure, *ranges["pressure"], delta=1)
    noise = smooth_random(noise, *ranges["noise"], delta=1.5)
    
    values = (
        current_time.strftime('%Y-%m-%d %H:%M:%S'),
        round(temperature, 2),
        round(water, 2),
        round(humidity, 2),
        round(light, 2),
        round(co2, 2),
        round(pressure, 2),
        round(noise, 2)
    )
    
    cursor.execute(insert_sql, values)
    count += 1
    
    if count % 1000 == 0:
        conn.commit()
        print(f"Inserted {count} records...")
        
    current_time += time_step

conn.commit()
cursor.close()
conn.close()

print(f"[✓] Done! A total of {count} records were inserted.")
