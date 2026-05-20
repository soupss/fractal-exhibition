#!/bin/sh

set -x

mkdir -p out out/shaders

naga --shader-stage compute --input-kind glsl src/shaders/compute.glsl out/shaders/compute.wgsl
naga --shader-stage vertex --input-kind glsl src/shaders/vertex.glsl out/shaders/vertex.wgsl
naga --shader-stage fragment --input-kind glsl src/shaders/fragment.glsl out/shaders/fragment.wgsl

emcc -s USE_WEBGPU=1 -s WASM_BIGINT=1 -s ASYNCIFY -s EXPORTED_RUNTIME_METHODS="['ccall']" --embed-file out/shaders/@shaders/ src/main.c -o out/main.js

cp -r public/* out/
