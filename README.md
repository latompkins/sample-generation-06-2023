# Generating custom geometry samples in SDF using SBATCH and making confusion matrices
## Getting Started
I use VSCode Remote SSH as my editor, and I would recommend it! Working with lots of files requires being really familiar with where everything is in what directory, and I find this much easier than just navigating Bash with vim or emacs. https://code.visualstudio.com/docs/remote/ssh
### Installing `ldmx-sw`
At the bottom of https://github.com/LDMX-Software/ldmx-sw/tree/521c4cb4b009ebef7e1d251907571c0ee5e33e53, in the README, follow the Quick Start directions from cloning the repo onwards. Don't forget to set up an SSH key in SDF! For the path of least resistance, install in the directory you will be producing your samples in (the samples can be in a subdirectory). In this case, the directory to install in would be `sample-generation-06-2023`.
### Using ROOT
Start by running `source /sdf/group/hps/users/bravo/src/root/buildV62202/bin/thisroot.sh`. Now you can use ROOT. In order to get to the ROOT interface, enter `root`. Now try using a TBrowser: enter `new TBrowser()` into the ROOT terminal. This will allow you to open `.root` files to check if they are broken. If it's broken, you won't be able to open the file at all.

To exit ROOT, enter `.q`.
## Useful commands and resources
- Every time you SSH into SDF, in order to use `ldmx-sw`, you must `source ldmx-sw/scripts/ldmx-env.sh`.
- Similarly, in order to use ROOT, enter `source /sdf/group/hps/users/bravo/src/root/buildV62202/bin/thisroot.sh`. This is Cameron's version of ROOT.
- If you make a change in `ldmx-sw` without making any new directories, you must `ldmx cmake \path\to\ldmx-sw` again.
- If you make a new directory in `ldmx-sw`, you must `ldmx make install` again.
  - Adding `-j2` is the number of cores you are using to run the command. If installing takes too long, you can add `-j4`. 

### Running scripts locally
- Bash: `. myScript.sh var1 var2 var3`
- C++ (ROOT): `root -l -b -q 'myScript.C+("string", int)'`
- Python (LDMX): `ldmx fire myScript.py var1 var2 var3`

### Batch submitting
- Make sure your runtime (defined at the top of the bash script to be submitted) is enough for the scripts you are running!
- `sbatch [something to run]` to submit a script.
- `squeue -u yourusername` to check your running submissions.
- `scancel ###` or `scancel -u yourusername` to manually cancel any failing or faulty submissions.

### Bash commands:
- My most used command is `ctrl`+`R`, which lets you reverse search previous commands. Great for re-running things or making small changes to previous commands! To iterate through results, use `ctrl`+`R` to go forwards and `ctrl`+`shift`+`R` to go backwards.
- Quitting a job: `ctrl`+`c`
- Iterating over a loop: (ex1) `for i in {1..10} ; do {... $i} ; done`, (ex2) `for i in string1 string2; do {... {$i}}; done`
  - In C scripts, if you are iterating over parameters, you need to have additional apostrophes (') surrounding the variables you're iterating over. (ex) `for i in string1 string2; do root -l -b -q 'myScript.C+("'${i}'"); done
- Write files and path to a `.txt`: `ls /path/to/files/*.root > fileList.txt`
- Copying to/from a remote machine: `scp /path/fileToCopy user@ssh.xxx:/path/` (if copying from remote machine, flip order)

## Making custom geometries
- Go to `\path\to\ldmx-sw\Detectors\data\`. Choose the correct Detector version (probably `v14`) to start editing from and make a copy of it under a different name (ex. `ldmx-det-v14-{describe main intended change in short phrase}`). There will be lots of `.gdml` files - all of the contents of the detector that will be present are in `detector.gdml`. But the main file you will probably edit for geometry changes will be `constants.gdml`, which has all of the numbers. If you do not need ECal and/or HCal information (you will only need ECal for trigger sum energies), you can delete the following lines from `detector.gdml`:
  - ```
      <physvol copynumber="6"> 
        <file name="/sdf/group/ldmx/users/meganloh/samples/ldmx-sw/install/data/detectors/ldmx-det-v14/ecal.gdml"/> 
        <positionref ref="em_calorimeter_pos"/> 
        <rotationref ref="identity"/> 
	    </physvol>
      <physvol copynumber="7"> 
        <file name="/sdf/group/ldmx/users/meganloh/samples/ldmx-sw/install/data/detectors/ldmx-det-v14/hcal.gdml"/> 
        <positionref ref="hadron_calorimeter_pos"/> 
        <rotationref ref="identity"/> 
      </physvol> 
- Once the appropriate geometry changes have been made, you must rerun `ldmx cmake \path\to\ldmx-sw` and `ldmx make install` to implement the changes.

## Creating custom geometry samples
`runSampleGeneration.py` actually generates the files, which is where we define the number of events per file, and where we choose what to keep in the file. However, since we typically make many files with many events, we use a Bash script to iterate over the Python script for us, which is `slurm_sample_sub.sh`. This script takes a few options:
1) `mult, -m` electron multiplicity, or the number of true electrons entering the detector at once. Default is 1.
2) `nFiles, -f` number of files to generate. Default is 1.
3) `version, -v` the version of the detector geometry you want to run over! This is where you put `ldmx-det-v14-short-phrase`.
4) `offset, -o` this is mainly for batch submissions so we can generate unique samples in reasonable batch submission sizes. This will change where your run number starts (e.g. `-o 20` makes `file-runx00021.root`). Default is 0.

The first thing is to test that nothing is broken. Try to run the script locally over a small number of files. Batch submitting a bunch of commands that will crash/fail is not good. Try `. slurm_sample_sub.sh -v ldmx-det-v14-your-version`. If you can see that it is running through events without any failures, you can `ctrl`+`c` to stop. You are now ready to batch submit!

In my version of the script, each file contains 2000 events. To submit 200,000 events per multiplicity (1-4e) with 20,000 events per submission, I would use
`for m in {1..4}; do for n in {0..9}; do sbatch slurm_sample_sub.sh -m ${m} -v ldmx-det-your-version -f 10 -o $((n * 10)); done; done`

You can check on your SBATCH submission in real time in the `logs` folder to make sure everything is running smoothly. You can also use `squeue -u yourusername` to see how long they have been running and whether this is reasonable (or too long, or not at all!).

### Creating confusion matrices
Now we have our files, but they are too chunky to work easily with (we have too many files and they are too big)! Confusion matrices are 2D histograms for the number of true electrons vs. the number of counted electrons (electrons counted by the trigger scintillator). This means we only need the counted electron number from each file, since we've already set the number of true electrons in the sample generation. This is found in `@TriggerPadTracks_sim.size()` in the ROOT File.

For this reason, there is `drawTracksvsEventsFromTree.C` that makes a new ROOT file just with the tracks (counted electrons) vs. events and with the correct number of bins. To run this over multiple files, we have another Bash script, `slurm_draw_sub.sh`, which has options mult `-m` and version `-v` to be used as before. The script **also expects** a `.txt` file of the form `inclusive[mult]e-[version].txt`, where now `version` does not require `ldmx-det-` in front of your personalized phrase anymore (redundant), unless you want to keep it for consistency. Thus, your first step is to create a list for your new samples. In a loop, this would be `for m in {1..4}; do ls /path/to/sample-out/inclusive_${m}e/*.root > inclusive${m}e-version.txt`. Then you can use
`for m in {1..4}; do sbatch slurm_draw_sub.sh -m ${m} -v yourversion; done`.

We are close!




## Troubleshooting
- If `ldmx cmake
## 
