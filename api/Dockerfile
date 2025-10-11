FROM python:3.12-slim
WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && mv ~/.local/bin/uv /usr/local/bin/uv \
    && rm -rf ~/.local \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*

RUN uv pip install --system fastapi email-validator uvicorn[standard]
COPY app.py .
EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
