#!/bin/bash
for i in {1..10}; do
    curl -s http://localhost:8080
    echo
done
