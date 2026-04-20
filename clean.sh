#!/bin/bash

echo "removed build artifacts:"
rm -v *.wasm main.js */*.wgsl 2>/dev/null
