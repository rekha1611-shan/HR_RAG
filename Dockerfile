# Google App Engine Flexible custom runtime for the Streamlit HR RAG chatbot.
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    STREAMLIT_SERVER_HEADLESS=true \
    STREAMLIT_SERVER_ADDRESS=0.0.0.0 \
    PORT=8080

WORKDIR /app

# Install dependencies in a separate layer for better build caching.
COPY requirements.txt ./requirements.txt
RUN python -m pip install --upgrade pip \
    && python -m pip install --no-cache-dir -r requirements.txt

# Copy application source, FAISS index, and HR documents.
# .env is excluded by .dockerignore and must not be baked into the image.
COPY . .

# App Engine Flexible routes HTTP traffic to the container on port 8080.
EXPOSE 8080

# Container-level health check using Streamlit's built-in health endpoint.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/_stcore/health', timeout=3)" || exit 1

# Shell form is intentional so $PORT is expanded at runtime.
# App Engine provides PORT; 8080 is the safe fallback for local execution.
CMD streamlit run app_with_memory.py   --server.address=0.0.0.0  --server.port=${PORT:-8080}  --server.headless=true  --browser.gatherUsageStats=false
