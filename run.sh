#!/bin/bash
set -e

BACKEND_DIR="backend"
FRONTEND_DIR="frontend"
BACKEND_PORT=8080
FRONTEND_PORT=4200

start_backend() {
    echo "Starting backend..."
    cd "$BACKEND_DIR" || exit
    ./mvnw spring-boot:run > ../backend.log 2>&1 &
    BACKEND_PID=$!
    cd - >/dev/null

    echo "Waiting for backend to be ready..."
    for i in {1..30}; do
        nc -z localhost $BACKEND_PORT && break
        sleep 1
    done

    if ! nc -z localhost $BACKEND_PORT; then
        echo "Backend failed to start."
        stop_all
        exit 1
    fi
    echo "Backend is ready (port $BACKEND_PORT)."
}

start_frontend() {
    echo "Starting frontend..."
    cd "$FRONTEND_DIR" || exit
    npm install
    npx ng serve --host 0.0.0.0 --port $FRONTEND_PORT > ../frontend.log 2>&1 &
    FRONTEND_PID=$!
    cd - >/dev/null
    echo "Frontend started on port $FRONTEND_PORT : http://localhost:$FRONTEND_PORT"
}

stop_all() {
    echo "Stopping frontend..."
    pkill -f "ng serve" || true
    echo "Stopping backend..."
    pkill -f "spring-boot:run" || true
}


start_all() {
    start_backend || { echo "Cannot start frontend without backend."; stop_all; exit 1; }
    start_frontend || { echo "Frontend failed to start."; stop_all; exit 1; }
    echo "All services started successfully."
}

status_all() {
    echo "Backend PID: $(pgrep -f 'spring-boot:run' || echo 'not running')"
    echo "Frontend PID: $(pgrep -f 'ng serve' || echo 'not running')"
}

case "$1" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    status)
        status_all
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac
