# These are flags you must include - Two memory and one runtime.
# Runtime is either seconds or hours:min:sec

#$ -l tmem=1G
#$ -l h_vmem=2G
#$ -l h_rt=1:0:0 

#These are optional flags but you probably want them in all jobs

#$ -S /bin/bash
#$ -j y
#$ -N train_lahm_agent_mot17

# output directory for STDOUT file
#$ -o ~/run-log/

hostname
date

# See resources
echo GPUs: $(nvidia-smi -L)
echo Processors: $(nproc)

# conda env
export PATH=/home/$USER/miniconda3/bin:${PATH}
export LD_LIBRARY_PATH=/home/$USER/miniconda3/lib/:${LD_LIBRARY_PATH}
conda activate FairMOT
python --version

# Make scratch space
UNIQUEID=$(uuidgen)
UNIQUEID=${UNIQUEID:0:13}
BASEDIR="/scratch0/$USER/"
mkdir $BASEDIR
SCRATCH="${BASEDIR}${UNIQUEID}/"
mkdir $SCRATCH

# Directories for datasets and detections
DATADIR="${SCRATCH}datasets/"
mkdir $DATADIR
DETSDIR="${SCRATCH}detections/"
mkdir $DETSDIR
find $SCRATCH -maxdepth 2

# Directories for results
RESULTSDIR="${SCRATCH}results/"
mkdir $RESULTSDIR

# Download MOT17 data
mkdir "${DATADIR}MOT17/"
cd "${DATADIR}MOT17/"
wget -nv https://motchallenge.net/data/MOT17Det.zip
unzip -q MOT17Det.zip
rm MOT17Det.zip
rsync -ar --info=progress2 /home/$USER/repos/lahm-track/mot-gallery-agent/tools/seperate_seqs.py .
python seperate_seqs.py

# Download MOT20 data
# mkdir "${DATADIR}MOT20/"
# cd "${DATADIR}MOT20/"
# wget https://motchallenge.net/data/MOT20.zip
# unzip MOT20.zip
# mv MOT20/train .
# mv MOT20/test .
# rm -d MOT20.zip MOT20
# rsync -ar --info=progress2 /home/chipping/repos/lahm-track/mot-gallery-agent/tools/split_seqs.py .
# python split_seqs.py

# Download detections
cd $DETSDIR
gdown -q 1JlNKD1uFPXfs5mEYswsoa4AVfP0Hafyw
unzip -q FairMOT.zip
rm FairMOT.zip

# Check file structure
echo "Data file structure:"
find $SCRATCH -maxdepth 3

# Run links
cd /home/$USER/repos/lahm-track/mot-gallery-agent/
rm -d /home/$USER/repos/lahm-track/mot-gallery-agent/motgym/datasets
rm -d /home/$USER/repos/lahm-track/mot-gallery-agent/motgym/detections
./tools/datasets_symbolic_link.sh $(realpath $DATADIR)
./tools/detections_symbolic_link.sh $(realpath $DETSDIR)
find /home/$USER/repos/lahm-track/mot-gallery-agent/motgym/ -maxdepth 1

# Run script
echo 'Starting Training'
python /train/sequential/fairmot_seq_ppo_mot17_train_half.py $RESULTSDIR 2>&1 > /dev/null

# Move results to persistent store
rsync -ar --info=progress2 $RESULTSDIR /home/$USER/train-results/$UNIQUEID

date