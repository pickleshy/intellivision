FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py config.py ./
COPY templates/ templates/
COPY static/ static/

EXPOSE 5001

ENV FLASK_APP=app.py
ENV PYTHONUNBUFFERED=1

ARG GIT_COMMIT_HASH=""
ARG GIT_COMMIT_DATE=""
ENV GIT_COMMIT_HASH=${GIT_COMMIT_HASH}
ENV GIT_COMMIT_DATE=${GIT_COMMIT_DATE}

CMD ["python", "app.py"]
