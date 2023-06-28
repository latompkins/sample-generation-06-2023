#!/usr/bin/scl enable devtoolset-8 -- /bin/bash
#SBATCH --ntasks=1
#SBATCH --time=2:00:00
#SBATCH --mem=3000M
#SBATCH --partition=shared
#SBATCH --output="./logs/slurm-log-%j.out"
date
OPTIND=1

mult=1
version='v14-50bars'
configToRun='drawTracksvsEventsFromTree.C'

while getopts m:v: flag
do
    case "${flag}" in
        m) mult=${OPTARG};;
        v) version=${OPTARG};;
    esac

done

echo "mult is ${mult}, version is ${version}"

source /sdf/group/hps/users/bravo/src/root/buildV62202/bin/thisroot.sh

process="inclusive"
configToRun="drawTracksvsEventsFromTree.C"
outDir="/sdf/group/ldmx/users/meganloh/confusion_matrix/tracksvsevents/${version}/${process}_${mult}e"

fileList="${process}${mult}e-${version}.txt"

# ------- all set, execute ------

if [ ! -d ${outDir} ]
then
    echo "Creating output directory ${outDir}"
    mkdir -p ${outDir}
fi

# submit 
let iterator=1
for fileName in $(cat $fileList) ;
    do root -l -b -q ''$configToRun'+("'$fileName'","'$mult'","'$outDir/$process$mult\e-$version-run$iterator.root'")';
    ((iterator++))
done


echo "Done."
time