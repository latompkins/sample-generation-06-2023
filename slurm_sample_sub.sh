#!/usr/bin/scl enable devtoolset-8 -- /bin/bash
#SBATCH --ntasks=1
#SBATCH --time=8:00:00
#SBATCH --mem=3000M
#SBATCH --partition=shared
#SBATCH --output="./logs/slurm-log-%j.out"
date
OPTIND=1

mult=1
nFiles=1
version='ldmx-det-v14-50bars'
offset=0

while getopts m:f:v:o: flag
do
    case "${flag}" in
        m) mult=${OPTARG};;
        f) nFiles=${OPTARG};;
        v) version=${OPTARG};;
        o) offset=${OPTARG};;
    esac

done

echo "mult is ${mult}, creating ${nFiles} files"

source /sdf/group/ldmx/users/meganloh/samples/ldmx-sw/scripts/ldmx-env.sh

process="inclusive"
configToRun="runSampleGeneration.py"
outDir="/sdf/group/ldmx/users/meganloh/samples/geometry-changes/${version}/${process}_${mult}e"

# ------- all set, execute ------

if [ ! -d ${outDir} ]
then
    echo "Creating output directory ${outDir}"
    mkdir -p ${outDir}
fi



# submit 
let runStart=$mult*10000+$offset
let startNb=0 #this could be become a command line arg 
let nb=$startNb+1
while [ $nb -le $((nFiles + startNb)) ]  ; do      
    let runNum=$nb+$runStart                                                                                                    
    outfile="${version}-${mult}e-${process}-run${runNum}.root" 
    echo "command is ${configToRun} $mult $runNum $version $outfile $outDir"
    ldmx fire ${configToRun} $mult $runNum $version $outfile $outDir # > ./logs/${version}/${process}_${mult}e${runNum}_outlog.txt
    ((nb++))
    date
done


echo "Done."