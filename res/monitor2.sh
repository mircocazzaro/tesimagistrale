#!/bin/bash

pid=$1
output_file=$2

# Get the number of CPUs
num_cpus=$(nproc)

# Time interval in seconds (you can adjust the resolution here)
interval=1

trap 'echo "Monitor stopped"; exit' SIGINT SIGTERM

if [ -z "$pid" ] || [ -z "$output_file" ]; then
    echo "Usage: $0 <PID> <output_file>"
    exit 1
fi

exec > $output_file

while true; do
    # Capture CPU times at the start of the interval
    start_utime=$(cat /proc/$pid/stat | cut -d " " -f 14)
    start_stime=$(cat /proc/$pid/stat | cut -d " " -f 15)
    start_total=$(cat /proc/stat | grep '^cpu ' | awk '{print $2+$3+$4+$5+$6+$7+$8}')

    # Capture the initial RAM usage
    start_ram=$(grep VmRSS /proc/$pid/status | awk '{print $2}')

    sleep $interval

    # Capture CPU times at the end of the interval
    end_utime=$(cat /proc/$pid/stat | cut -d " " -f 14)
    end_stime=$(cat /proc/$pid/stat | cut -d " " -f 15)
    end_total=$(cat /proc/stat | grep '^cpu ' | awk '{print $2+$3+$4+$5+$6+$7+$8}')

    # Capture the end RAM usage
    end_ram=$(grep VmRSS /proc/$pid/status | awk '{print $2}')

    # Calculate the deltas for CPU
    delta_process=$(( (end_utime + end_stime) - (start_utime + start_stime) ))
    delta_total=$(( end_total - start_total ))

    # Calculate CPU usage as a percentage
    cpu_usage=$(awk "BEGIN {printf \"%.2f\", (${delta_process} / ${delta_total}) * 100 * ${num_cpus}}")

    # Calculate RAM usage change if needed
    ram_usage_change=$(( end_ram - start_ram ))

    echo "$(date +'%Y-%m-%d %H:%M:%S') CPU Usage: ${cpu_usage}% | RAM Usage Change: ${ram_usage_change} kB"

done
