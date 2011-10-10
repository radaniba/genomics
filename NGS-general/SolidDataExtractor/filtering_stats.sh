#!/bin/sh
#
# filtering_stats.sh: calculate stats for preprocess filtering
#
# Usage: filtering_stats.sh <csfasta> <stats_file>
#
# Counts number of reads in original csfasta file and filtered
# file <csfasta>_T_F3.csfasta, and reports numbers plus the
# difference (= number filtered) and percentage filtered.
#
# Appends a tab-delimited line with this information to the
# specified <stats_file>
#
# Import function libraries
if [ -f functions.sh ] ; then
    # Import local copies
    . functions.sh
    . lock.sh
else
    # Import versions in share
    `dirname $0`/../../share/functions.sh
    `dirname $0`/../../share/lock.sh
fi
#
# Local functions
#
# difference(): difference between two numbers
function difference() {
    echo "scale=10; $1 - $2" | bc -l
}
#
# percent(): express one number as percentage of another
function percent() {
    echo "scale=10; ${1}/${2}*100" | bc -l | cut -c1-5
}
#
# Main script
#
# Inputs
csfasta=$1
stats_file=$2
#
base_csfasta=`basename $1`
filtered_csfasta=$(rootname $1)_T_F3.csfasta
#
# Check filtered file exists
if [ ! -f "${filtered_csfasta}" ] ; then
    echo `basename $0`: ${filtered_csfasta}: not found
    exit 1
fi
#
# Get numbers of reads
n_reads_primary=`grep -c "^>" ${csfasta}`
n_reads_filter=`grep -c "^>" ${filtered_csfasta}`
#
# Get stats
n_filtered=$(difference ${n_reads_primary} ${n_reads_filter})
percent_filtered=$(percent ${n_filtered} ${n_reads_primary})
#
echo "--------------------------------------------------------"
echo Comparing numbers of primary and filtered reads
echo "--------------------------------------------------------"
echo ${csfasta}$'\t'${n_reads_primary}
echo ${filtered_csfasta}$'\t'${n_reads_filter}
echo Number filtered$'\t'${n_filtered}
echo % filtered$'\t'${percent_filtered}
#
# Write to file
wait_for_lock ${stats_file} 30
if [ $? == 1 ] ; then
    if [ ! -f ${stats_file} ] ; then
	# Create new stats file and write header
	echo "#File"$'\t'"Reads"$'\t'"Reads after filter"$'\t'"Difference"$'\t'"% Filtered" > ${stats_file}
    fi
    # Write to stats file
    echo ${base_csfasta}$'\t'${n_reads_primary}$'\t'${n_reads_filter}$'\t'${n_filtered}$'\t'${percent_filtered} >> ${stats_file}
    # Release lock
    unlock_file ${stats_file}
else
    echo Unable to get lock on ${stats_file}
fi
##
#