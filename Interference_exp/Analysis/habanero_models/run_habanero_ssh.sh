#!/bin/sh
#hedge.sh

#Slurm directives
#
#SBATCH -A dslab                         # The account name for the job.
#SBATCH -J choice_delta_val_interference # The job name.
#SBATCH -c 6                             # The number of cpu cores to use.
#SBATCH -t 72:00:00                      # The time the job will take to run.
#SBATCH --mem-per-cpu 8gb                # The memory the job will use per cpu core.
#SBATCH --mail-type=ALL
#SBATCH --mail-user=nb2869@columbia.edu

module load R/3.6.2
module load gcc/8.3.0

#Command to execute R code
R CMD BATCH --no-save --vanilla run_habanero_models_counterfactuals.R output_habanero_model_counterfactuals

# End of script
