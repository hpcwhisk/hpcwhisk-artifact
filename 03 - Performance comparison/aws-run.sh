#!/usr/bin/env bash

. serverless-benchmarks/python-venv/bin/activate
mkdir -p results
for t in bfs mst pagerank; do
	serverless-benchmarks/sebs.py experiment invoke perf-cost --config aws-$t.json --output-dir $PWD/aws-$t --cache cache --verbose
	serverless-benchmarks/sebs.py experiment process perf-cost --config aws-$t.json --output-dir $PWD/aws-$t
	cp aws-$t/perf-cost/result.csv results/aws-$t.csv
done
