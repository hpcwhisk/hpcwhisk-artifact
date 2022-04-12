#!/bin/bash

echo Preparing base Python image
pushd openwhisk-runtime-python
./gradlew :core:python3AiActionLoop:distDocker -P dockerBuildArgs="GO_PROXY_GITHUB_USER=pmzuk GO_PROXY_BUILD_FROM=source" -P dockerImagePrefix=openwhisk
popd


echo Setup SeBS functions
. serverless-benchmarks/python-venv/bin/activate

for t in 503.graph-bfs 501.graph-pagerank 502.graph-mst; do
	serverless-benchmarks/sebs.py benchmark invoke $t test --cache $PWD/ow-cache  --repetitions 0  --config serverless-benchmarks/config/openwhisk.json  --verbose
done

echo Converting Docker images to Singularity images
docker run -d -p 5000:5000 --restart=always --name registry registry:2

mkdir -p spcleth
for t in 503.graph-bfs 501.graph-pagerank 502.graph-mst; do
	img=spcleth/serverless-benchmarks:openwhisk-$t-python-3.6
	sed -e "s|BASE_IMAGE|$img|" < skeleton.def > generated-$t.def
	docker tag $img localhost:5000/$img
	docker push localhost:5000/$img
	sudo SINGULARITY_NOHTTPS=1 singularity build $img.simg generated-$t.def
done

