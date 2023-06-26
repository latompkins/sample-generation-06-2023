#!/usr/bin/scl enable devtoolset-8 -- /bin/bash
#SBATCH --ntasks=1
#SBATCH --time=8:00:00
#SBATCH --mem=3000M
#SBATCH --partition=shared
#SBATCH --output="./logs/slurm-log-%j.out"
date
OPTIND=1

# pre-define optional arguments
m_opt = 0
f_opt = 'test'

# optional arguments passed when submitting
while getopts m:f: flag
do
    case "${flag}" in
        m) m_opt=${OPTARG};;
        f) f_opt=${OPTARG};;
    esac
done

# if running something from ldmx, make sure to source ldmx-env.sh
source /sdf/group/ldmx/users/meganloh/samples/ldmx-sw/scripts/ldmx-env.sh

# what you would like to submit goes below!

echo "Done."
