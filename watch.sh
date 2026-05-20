#!/bin/bash

PORT=3000
PIPE="/tmp/shader_ws_pipe"

mkdir -p out/shaders

rm -f $PIPE
mkfifo $PIPE

exec 3<> $PIPE

websocat --text -E ws-listen:127.0.0.1:$PORT broadcast:- <&3 &
WS_PID=$!

trap "echo -e '\nShutting down...'; kill $WS_PID 2>/dev/null; rm -f $PIPE; exec 3>&-; exit" INT TERM EXIT

echo "WebSocket server listening on ws://localhost:$PORT"
echo "Watching src/shaders/ for .glsl changes..."

fswatch -o src/shaders/*.glsl | while read num; do
    echo -e "Transpiling shaders..."
    naga --shader-stage compute --input-kind glsl src/shaders/compute.glsl out/shaders/compute.wgsl && \
    naga --shader-stage vertex --input-kind glsl src/shaders/vertex.glsl out/shaders/vertex.wgsl && \
    naga --shader-stage fragment --input-kind glsl src/shaders/fragment.glsl out/shaders/fragment.wgsl
    if [ $? -eq 0 ]; then
        echo "Success!"
        echo "shader_updated" >&3
    else
        echo "Failed!"
    fi
    sleep 0.5
done
