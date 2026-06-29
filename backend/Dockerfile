FROM python:3.11-slim

WORKDIR /app

# Copy requirements.txt and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the backend source code into /app/backend
COPY . /app/backend/

# Expose port 8000
EXPOSE 8000

# Set PYTHONPATH so that backend is found as a package
ENV PYTHONPATH=/app

# Start the server using the correct module path
CMD ["uvicorn", "backend.app.main:app", "--host", "0.0.0.0", "--port", "8000"]
