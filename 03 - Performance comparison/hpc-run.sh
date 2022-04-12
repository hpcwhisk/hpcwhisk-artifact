#!/usr/bin/env bash

. serverless-benchmarks/python-venv/bin/activate
mkdir -p results
for t in bfs mst pagerank; do
	serverless-benchmarks/sebs.py experiment invoke perf-cost --config hpc-$t.json --output-dir $PWD/hpc-$t --cache hpc-cache --verbose
	serverless-benchmarks/sebs.py experiment process perf-cost --config hpc-$t.json --output-dir $PWD/hpc-$t
	cp hpc-$t/perf-cost/result.csv results/hpc-$t.csv
done
