#!/bin/bash

SCRIPT_DIR_PATH="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PROJECT_PATH="${SCRIPT_DIR_PATH}/../.."

file=""

function show_help
{
    echo "Usage: $0 -f <file>"
    echo
    echo "This script performs DRAGON read bandwidth benchmark."
    echo "Make sure that the <file> size is greater than or equal to <size-in-GiB>."
}

OPTIND=1	# Reset in case getopts has been used previously in the shell.

while getopts "h?f:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    f)  file=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

if [ ! -f "${file}" ] ; then
    echo "Error: <file> does not exist."
    echo
    show_help
    exit 1
fi

for rh_type in "agg" "norm" "dis"
do
    for size_in_gib in 1 2 4 8 16 32 64
    do
        ${PROJECT_PATH}/scripts/drop-caches
        sleep 5
        echo "==> benchmark,size_in_gib,mode,readahead: read-bw,${size_in_gib},page-cache,${rh_type}"
        (set -x; DRAGON_DIRECT_NUM_GROUPS=0 DRAGON_READAHEAD_TYPE=${rh_type} ./bin/read-bw ${file} ${size_in_gib} 0 )
        echo "========================="
    done
done

for size_in_gib in 1 2 4 8 16 32 64
do
    ${PROJECT_PATH}/scripts/drop-caches
    sleep 5
    echo "==> benchmark,size_in_gib,mode: read-bw,${size_in_gib},direct"
    (set -x; DRAGON_DIRECT_NUM_GROUPS=1 ./bin/read-bw ${file} ${size_in_gib} 1 )
    echo "========================="
done
