##########################################################################
# RUN_SPARC.sh     SPARC submit script                                   #
#                                                                        #
# FILE CREATED ON: 2024FEB21                                             #
# LAST EDITED: 2024FEB21                                                 #
#                                                                        #
# This script assumes that you have built SPARC with intel	         #
#                                                                        #
# SPARC_DIR should reflect the location of your SPARC binary             #
#                                                                        #
# change the name of the sparc binary as needed                          #
#                                                                        #
# change h_rt (run-time), h_data (memory/core) as needed                 #
#                                                                        #
# remove exclusive and/or highp as needed                                #
#                                                                        #
# N.B.: only use highp if sponsor has contributed nodes otherwise the    #
#       job will NEVER start                                             #  
#                                                                        #
# change the number after dc* to change the number of parallel workers   #
#                                                                        #
# make sure that this script is executable before submitting:            #
# run: chmod u+x RUN_SPARC.sh                                            #
#                                                                        #
# submit your sparc job with:                                            #
# qsub RUN_SPARC.sh                                                      #
#                                                                        #
##########################################################################
#!/bin/bash

#Settings:
#$ -N SPARC_run
#$ -l h_rt=24:00:00
#$ -l h_data=4G
##$ -l highp
##$ -l exclusive
#$ -pe dc* 4
#$ -cwd

#Output files:
#$ -o joblog.$JOB_ID
#$ -e err.$JOB_ID

#Email notification:
#$ -m bea


# echo job info on joblog:
echo "Job $JOB_ID started on:   " `hostname -s`
echo "Job $JOB_ID started on:   " `date `
echo "Job $JOB_ID will run on:"
cat $PE_HOSTFILE
echo " "


# load the job environment
. /u/local/Modules/default/init/modules.sh
module load intel/2023.1.0
module li
. /u/local/bin/set_qrsh_env.sh
# SPARC_DIR=/u/home/a/agangan2/SPARC/SPARC/lib
SPARC_DIR=/u/home/a/agangan2/SPARC-energy/SPARC-energy/lib
# SPARC_DIR=/u/home/a/agangan2/SPARC-energy/SPARC-energy-initdens/lib
# set up simulation files
# run sparc
/usr/bin/time -v mpirun -np 32 $SPARC_DIR/sparc -name sim


# echo tags on joblog file
echo "Job $JOB_ID ended on:   " `hostname -s`
echo "Job $JOB_ID ended on:   " `date `
echo " "
##########################################################
