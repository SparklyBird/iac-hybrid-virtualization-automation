# Use the official Python 3.9 slim base image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Install required Python libraries
# --no-cache-dir reduces image size by not storing the cache
# --upgrade ensures the latest version of pip is installed
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir Flask pymysql

# Copy the application code from the local 'app' folder to the '/app' folder in the container
COPY app.py .

# Specify the port the application will use inside the container
EXPOSE 5000

# Command to be executed when starting the container
# Runs the Python interpreter with the app.py script
CMD ["python", "app.py"]
