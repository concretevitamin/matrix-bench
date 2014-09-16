#!/bin/sh

batch_trials=4
max_num_batch=2
trial_sleep_time=120 # 2 minutes
tsqr_rows="32768"
tsqr_cols="512"

stream_array_size=60000000

physical_cores=$((`cat /proc/cpuinfo | grep -i processor | wc -l` / 2))

# turn off THP
if [[ -e /sys/kernel/mm/transparent_hugepage/enabled ]]; then
  echo "Turning off THP."
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
  sleep 5
fi

# make once
make

# compile stream once
if [ ! -f ./stream.c ]; then
  echo "Downloading and compiling STREAM."
  wget http://www.cs.virginia.edu/stream/FTP/Code/stream.c
  gcc -O -fopenmp -D_OPENMP  -DSTREAM_ARRAY_SIZE=$stream_array_size stream.c -o stream
fi

batch=-1
while true
do
  batch=$(($batch+1))
  if [[ $batch -eq $max_num_batch ]]; then
    echo "All $max_num_batch batches done, exiting."
    exit 0
  fi

  for i in `seq 1 $batch_trials`
  do
    echo "Running STREAM."
    # run stream
    OMP_NUM_THREADS=$physical_cores ./stream >stream-batch$batch-`date "+%Y%m%d-%H:%M:%S"`.log | tee

    # now run dgeqrf
    for rows in $tsqr_rows
    do
      for cols in $tsqr_cols
      do
          echo "Running c-qr with $rows rows, $cols cols for each of the $physical_cores parallel threads."
          bash ./run-c-qr.sh $rows $cols $physical_cores >c-qr-batch$batch-`date "+%Y%m%d-%H:%M:%S"`.log
      done
    done
  done
  
  echo "Waiting $trial_sleep_time seconds until next batch."
  sleep $trial_sleep_time
done
