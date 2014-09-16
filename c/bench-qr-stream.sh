#!/bin/sh

stream_array_size=60000000
tsqr_rows="32768"
tsqr_cols="512"

physical_cores=$((`cat /proc/cpuinfo | grep -i processor | wc -l` / 2))

# turn off THP
if [[ -e /sys/kernel/mm/transparent_hugepage/enabled ]]; then
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
  sleep 5
fi

# make once
make

# run stream once
wget http://www.cs.virginia.edu/stream/FTP/Code/stream.c
gcc -O -fopenmp -D_OPENMP  -DSTREAM_ARRAY_SIZE=$stream_array_size stream.c -o stream 
OMP_NUM_THREADS=1 ./stream >stream-`date "+%Y%m%d-%H:%M:%S"`.log

# now run dgeqrf
for rows in $tsqr_rows
do
  for cols in $tsqr_cols
  do
    bash ./run-c-qr.sh $rows $cols $physical_cores >c-qr-`date "+%Y%m%d-%H:%M:%S"`.log
  done
done
