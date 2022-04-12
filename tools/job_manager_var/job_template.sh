#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -J job_mintime
#SBATCH --cpus-per-task 24
#SBATCH -p lowprio
#SBATCH -A plgwhisk
#SBATCH --time 02:00:00
#SBATCH --time-min 00:02:00
#SBATCH -o /net/archive/groups/plggwhisk/job_manager/outputs/invoker_%j.out
#SBATCH -e /net/archive/groups/plggwhisk/job_manager/outputs/invoker_%j.out

module add plgrid/tools/java8/1.8.0_144
module add plgrid/tools/singularity/stable

#INVOKER_ID="${1-generated_$RANDOM}"
INVOKER_ID="${SLURM_JOB_ID}"
BASE_PATH="/net/archive/groups/plggwhisk/native_invoker/"


cd ${BASE_PATH}
source ${BASE_PATH}/conf/environment.sh
export INVOKER_OPTS="$INVOKER_OPTS $(${BASE_PATH}/bin/transformEnvironment.sh)"

exec ${BASE_PATH}/bin/invoker --id ${INVOKER_ID} --uniqueName ${INVOKER_ID}

#testing
#echo "Test run of invoker ${INVOKER_ID}"
#sleep 3m

# you can stop all jobs by using this command:
# scancel $(squeue -u $USER -o %i -h | paste -sd,)
