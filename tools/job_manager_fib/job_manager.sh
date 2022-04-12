#!/bin/bash

#USAGE: ./job_manager [partition]
# partition specification is optional, defaults to lowprio

DESIRED_JOB_COUNT=10
# job lenghts are in descending order for easier calculation of 'nice' parameter below
JOB_LENGTHS=(1:30:00 56:00 34:00 22:00 14:00 08:00 06:00 04:00 02:00)
JOB_NAME_PREFIX="i_"

PART=$1

BASE_DIR=$(dirname $(readlink -f $0))
JOB_TEMPLATE="job_template.sh"

while true; do
	for index in ${!JOB_LENGTHS[@]}; do
		length=${JOB_LENGTHS[${index}]}
		nicev=$((${index}*100))
		JOB_NAME="${JOB_NAME_PREFIX}${length}"
		JOB_COUNT=$(squeue -u ${USER} -n ${JOB_NAME} -t pd -h | wc -l)
		RUNNING_JOB_COUNT=$(squeue -u ${USER} -n ${JOB_NAME} -t r -h | wc -l)
		echo "Current number of pending jobs ${JOB_NAME}: ${JOB_COUNT}/${DESIRED_JOB_COUNT}, while running: ${RUNNING_JOB_COUNT}"

		if [ "${JOB_COUNT}" -lt "${DESIRED_JOB_COUNT}" ]; then
			let "difference=${DESIRED_JOB_COUNT}-${JOB_COUNT}"
			echo "Adding ${difference} jobs.."
			for i in $(seq ${difference}); do
				echo -n "Adding job ${i}/${difference} ... "
				sbatch -J ${JOB_NAME} -p ${PART:-lowprio} --nice=${nicev} --time=${length} ${BASE_DIR}/${JOB_TEMPLATE}
			done
		fi
	done
	echo "requested count: ${DESIRED_JOB_COUNT}, lengths: ${JOB_LENGTHS[@]}"
	echo "press [CTRL+C] to stop monitoring..."
	sleep 15s # allow slurm to catch up with jobs
done
