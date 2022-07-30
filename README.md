# HPC-Whisk - Artifact 4

This is one of the artifacts for the following paper:

> Bartłomiej Przybylski, Paweł Żuk, Krzysztof Rzadca, _Call Scheduling to Reduce Response Time of a FaaS System_, IEEE Cluster 2022 - Preprint: https://arxiv.org/abs/2207.13168

Our system setup was based on the following external software:

* Slurm 19.05.8 (system)
* Gatling 3.5.1 (data gathering)
* Python 3.8.6 / matplotlib 3.3.2 / numpy 1.20.2 / seaborn 0.11.0 / bitarray 2.2.2 (offline analysis)

The reproduction of the experiment requires one to set up OpenWhisk ([with the changes described in the article](https://github.com/pmzuk/openwhisk-runtime-go/), Sec. III) and some adjustments in the configuration of the Slurm Workload Manager. For reference, we provide our Slurm configuration in the `tools/slurm.cfg` file.

We use Gatling to generate a 24h-long load in our experiments. In this repository, we provide the `tools/gatling.sh` script which is a wrapper that ensures the usage of a specific Gatling version (3.5.1) and the provided Gatling scenario. The `job-generation/job_generator.py` script in the [hpcwhisk](https://github.com/bartlomiejlagosz/hpcwhisk) repository (Artifact 1) registers test actions used in Gatling scenario.

This `hpcwhisk-artifact` git repository contains all the files that help to reproduce (1) the configuration of the cluster, (2) the process of data gathering, and (3) the process of data analysis. It consists of 5 separate folders.

## `tools` - the set of configuration files and job manager scripts

The `tools` folder contains the cluster configuration file (`slurm.cfg`), the bash scripts for job managers (`job_manager_fib` and `job_manager_var`), and the Gatling configuration files (`gatling` and `gatling.sh`).

The `activation_stats.py` script can be run on the OpenWhisk controller to generate the data for the OpenWhisk-level analysis.

## `00 - Introductory analysis` - Sec. I and Sec. IV-C

The `00 - Introductory analysis` directory contains original logs from our setup, gathered between February 21st and 27th, 2022. It also contains the Jupyter notebooks used to analyze these logs. Their content shows the exact command used to generate the logs, but also allow to reproduce the charts used in the paper (Fig. 1). The `00 - Introductory analysis - Idle nodes.ipynb` notebook was additionally used to generate the contents of Table I.

## `01 - Fib model analysis` - Sec. V-B-1 and Sec. V-C

This folder contains the Gatling-level and the Slurm-level log data gathered on March 17th, as well as the Jupyter notebooks used to analyze this data. The notebooks reveal the exact command used to generate the logs.

* The `01 - Fib model analysis - Slurm-level.ipynb` notebook was used to generate Slurm-level results (Fig. 4a, middle, Fig. 4c).
* The `01 - Fib model analysis - Simulation.ipynb` notebook was used to generate Simulation results (Fig. 4a, left).
* The `01 - Fib model analysis - OW-level.ipynb` notebook was used to generate OpenWhisk-level data (Fig. 4a, right). 
* The `01 - Fib model analysis - Load analysis.ipynb` notebook analyzes the data gathered by Gatling (Fig. 4b).

The results from all the notebooks were consolidated in Table II and described in the text.

## `02 - Var model analysis` - Sec. V-B-2 and Sec. V-C

The contents of this folder is organized similarly to `01 - Fib model analysis`.

## `03 - Performance comparison` - Sec. V-D

This folder contains the files necessary to reproduce data discussed in Sec. V-D, i.e. the comparison of internal execution time in AWS Lambda and in HPC-Whisk. The results can be generated based on the `hpc-run.sh` and `aws-run.sh` files. The results are analyzed in the `aws-hpc-compare.ipynb` notebook.
