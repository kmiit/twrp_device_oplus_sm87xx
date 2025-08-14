#=============================================================================
# Copyright (c) 2020-2024 Qualcomm Technologies, Inc.
# All Rights Reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.
#
# Copyright (c) 2009-2012, 2014-2019, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#=============================================================================

rev=`cat /sys/devices/soc0/revision`

# Configure RT parameters:
# Long running RT task detection is confined to consolidated builds.
# Set RT throttle runtime to 50ms more than long running RT
# task detection time.
# Set RT throttle period to 100ms more than RT throttle runtime.
long_running_rt_task_ms=1200
sched_rt_runtime_ms=`expr $long_running_rt_task_ms + 50`
sched_rt_runtime_us=`expr $sched_rt_runtime_ms \* 1000`
sched_rt_period_ms=`expr $sched_rt_runtime_ms + 100`
sched_rt_period_us=`expr $sched_rt_period_ms \* 1000`
echo $sched_rt_period_us > /proc/sys/kernel/sched_rt_period_us
echo $sched_rt_runtime_us > /proc/sys/kernel/sched_rt_runtime_us

if [ -d /proc/sys/walt ]; then
	# configure maximum frequency when CPUs are partially halted
	echo 2147483647 > /proc/sys/walt/sched_max_freq_partial_halt

	# Core control parameters for gold
	echo 4 > /sys/devices/system/cpu/cpu0/core_ctl/min_cpus
	echo 60 > /sys/devices/system/cpu/cpu0/core_ctl/busy_up_thres
	echo 30 > /sys/devices/system/cpu/cpu0/core_ctl/busy_down_thres
	echo 100 > /sys/devices/system/cpu/cpu0/core_ctl/offline_delay_ms
	echo 6 > /sys/devices/system/cpu/cpu0/core_ctl/task_thres
	echo 0 0 0 0 1 1 > /sys/devices/system/cpu/cpu0/core_ctl/not_preferred
	echo 0xFF > /sys/devices/system/cpu/cpu0/core_ctl/nrrun_cpu_mask
	echo 0x00 > /sys/devices/system/cpu/cpu0/core_ctl/nrrun_cpu_misfit_mask
	echo 0x00 > /sys/devices/system/cpu/cpu0/core_ctl/assist_cpu_mask
	echo 0x00 > /sys/devices/system/cpu/cpu0/core_ctl/assist_cpu_misfit_mask

	# Core control parameters for gold+
	echo 0 > /sys/devices/system/cpu/cpu6/core_ctl/min_cpus
	echo 60 > /sys/devices/system/cpu/cpu6/core_ctl/busy_up_thres
	echo 30 > /sys/devices/system/cpu/cpu6/core_ctl/busy_down_thres
	echo 100 > /sys/devices/system/cpu/cpu6/core_ctl/offline_delay_ms
	echo 2 > /sys/devices/system/cpu/cpu6/core_ctl/task_thres
	echo 0 0 > /sys/devices/system/cpu/cpu6/core_ctl/not_preferred
	echo 0xC0 > /sys/devices/system/cpu/cpu6/core_ctl/nrrun_cpu_mask
	echo 0x3F > /sys/devices/system/cpu/cpu6/core_ctl/nrrun_cpu_misfit_mask
	echo 0x00 > /sys/devices/system/cpu/cpu6/core_ctl/assist_cpu_mask
	echo 0x3F > /sys/devices/system/cpu/cpu6/core_ctl/assist_cpu_misfit_mask

	echo 1 > /sys/devices/system/cpu/cpu0/core_ctl/enable
	echo 1 > /sys/devices/system/cpu/cpu6/core_ctl/enable

	# Configure Single Boost Thread
	echo 0 > /proc/sys/walt/sched_sbt_delay_windows
	echo 0x00 > /proc/sys/walt/sched_sbt_pause_cpus

	# Setting b.L scheduler parameters
	echo 95 > /proc/sys/walt/sched_upmigrate
	echo 85 > /proc/sys/walt/sched_downmigrate

	# By setting group upmigrate/downmigrate to 0, colocation is disabled.
	echo 0 > /proc/sys/walt/sched_group_downmigrate
	echo 0 > /proc/sys/walt/sched_group_upmigrate
	echo 1 > /proc/sys/walt/sched_walt_rotate_big_tasks
	echo 400000000 > /proc/sys/walt/sched_coloc_downmigrate_ns
	echo 8500000 1000000 1000000 1000000 1000000 1000000 2000000 2000000 > /proc/sys/walt/sched_coloc_busy_hyst_cpu_ns
	echo 255 > /proc/sys/walt/sched_coloc_busy_hysteresis_enable_cpus
	echo 10 10 10 10 10 10 95 95 > /proc/sys/walt/sched_coloc_busy_hyst_cpu_busy_pct
	echo 8500000 1000000 1000000 1000000 1000000 1000000 2000000 2000000 > /proc/sys/walt/sched_util_busy_hyst_cpu_ns
	echo 255 > /proc/sys/walt/sched_util_busy_hysteresis_enable_cpus
	echo 30 30 30 30 30 30 15 15 > /proc/sys/walt/sched_util_busy_hyst_cpu_util
	echo 255 > /proc/sys/walt/sched_legacy_smart_freq_hysteresis_enable_cpus
	echo 8500000 4000000 4000000 4000000 4000000 4000000 2000000 2000000 > /proc/sys/walt/sched_legacy_smart_freq_hyst_cpu_ns
	echo 40 > /proc/sys/walt/sched_cluster_util_thres_pct
	echo 30 > /proc/sys/walt/sched_idle_enough
	echo 10 > /proc/sys/walt/sched_ed_boost

	#Set early upmigrate tunables
	sched_upmigrate=`cat /proc/sys/walt/sched_upmigrate`
	sched_downmigrate=`cat /proc/sys/walt/sched_downmigrate`
	sched_upmigrate=${sched_upmigrate:0:2}
	sched_downmigrate=${sched_downmigrate:0:2}
	gold_early_upmigrate=`expr \( 1024 \* 100 \) \/ $sched_upmigrate`
	gold_early_downmigrate=`expr \( 1024 \* 100 \) \/ $sched_downmigrate`
	echo $gold_early_downmigrate > /proc/sys/walt/sched_early_downmigrate
	echo $gold_early_upmigrate > /proc/sys/walt/sched_early_upmigrate

	# Enable Gold CPUs for pipeline
	echo 56 > /proc/sys/walt/sched_pipeline_cpus

	# set the threshold for low latency task boost feature which prioritize
	# binder activity tasks
	echo 325 > /proc/sys/walt/walt_low_latency_task_threshold

	# configure maximum frequency of large and medium cluster for
	# different smart freq ipc reasons
	echo 2400000 2400000 2700000 3000000 2147483647 > /proc/sys/walt/cluster0/smart_freq/ipc_freq_levels
	echo 3513600 3800000 4100000 4200000 2147483647 > /proc/sys/walt/cluster1/smart_freq/ipc_freq_levels

	# Turn off scheduler boost at the end
	echo 0 > /proc/sys/walt/sched_boost

	# configure input boost settings
	if [ $rev == "1.0" ] || [ $rev == "1.1" ]; then
		echo 864000 0 0 0 0 0 0 0 > /proc/sys/walt/input_boost/input_boost_freq
	else
		echo 864000 0 0 0 0 0 0 0 > /proc/sys/walt/input_boost/input_boost_freq
	fi
	echo 100 > /proc/sys/walt/input_boost/input_boost_ms

	echo "walt" > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
	echo "walt" > /sys/devices/system/cpu/cpufreq/policy6/scaling_governor

	echo 0 > /sys/devices/system/cpu/cpufreq/policy0/walt/down_rate_limit_us
	echo 0 > /sys/devices/system/cpu/cpufreq/policy0/walt/up_rate_limit_us
	echo 0 > /sys/devices/system/cpu/cpufreq/policy6/walt/down_rate_limit_us
	echo 0 > /sys/devices/system/cpu/cpufreq/policy6/walt/up_rate_limit_us

	echo 1 > /sys/devices/system/cpu/cpufreq/policy0/walt/pl
	echo 1 > /sys/devices/system/cpu/cpufreq/policy6/walt/pl

	if [ $rev == "1.0" ] || [ $rev == "1.1" ]; then
		echo 787200 > /sys/devices/system/cpu/cpufreq/policy0/walt/rtg_boost_freq
		echo 902400 > /sys/devices/system/cpu/cpufreq/policy6/walt/rtg_boost_freq
		echo 1344000 > /sys/devices/system/cpu/cpufreq/policy0/walt/hispeed_freq
		echo 2380800 > /sys/devices/system/cpu/cpufreq/policy6/walt/hispeed_freq
	else
		echo 787200 > /sys/devices/system/cpu/cpufreq/policy0/walt/rtg_boost_freq
		echo 902400 > /sys/devices/system/cpu/cpufreq/policy6/walt/rtg_boost_freq
		echo 1344000 > /sys/devices/system/cpu/cpufreq/policy0/walt/hispeed_freq
		echo 2380800 > /sys/devices/system/cpu/cpufreq/policy6/walt/hispeed_freq
	fi
        # Disable hispeed_freq while cur_freq < 748800 (fangqiurong@BSP.CPU, 2024/8/2)
        echo 748800 > /sys/devices/system/cpu/cpufreq/policy0/walt/hispeed_cond_freq
else
	echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
	echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy6/scaling_governor
	echo 1 > /proc/sys/kernel/sched_pelt_multiplier
fi

if [ $rev == "1.0" ] || [ $rev == "1.1" ]; then
	echo 537600 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
	echo 844800 > /sys/devices/system/cpu/cpufreq/policy6/scaling_min_freq
	echo "0:537600 6:844800" > /data/vendor/perfd/default_scaling_min_freq
else
	echo 537600 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
	echo 844800 > /sys/devices/system/cpu/cpufreq/policy6/scaling_min_freq
	echo "0:537600 6:844800" > /data/vendor/perfd/default_scaling_min_freq
fi

# Reset the RT boost, which is 1024 (max) by default.
echo 0 > /proc/sys/kernel/sched_util_clamp_min_rt_default

# cpuset parameters
echo 0-5 > /dev/cpuset/background/cpus
echo 0-5 > /dev/cpuset/system-background/cpus


# configure bus-dcvs
bus_dcvs="/sys/devices/system/cpu/bus_dcvs"

for device in $bus_dcvs/*
do
	cat $device/hw_min_freq > $device/boost_freq
done

for llccbw in $bus_dcvs/LLCC/*bwmon-llcc-*
do
	echo "5340 8132 9155 12298 14236 16265 18478" > $llccbw/mbps_zones
	echo 4 > $llccbw/sample_ms
	echo 80 > $llccbw/io_percent
	echo 70 > $llccbw/second_ab_scale
	echo 20 > $llccbw/hist_memory
	echo 5 > $llccbw/hyst_length
	echo 1 > $llccbw/idle_length
	echo 30 > $llccbw/down_thres
	echo 0 > $llccbw/guard_band_mbps
	echo 250 > $llccbw/up_scale
	echo 1600 > $llccbw/idle_mbps
	echo 806000 > $llccbw/max_freq
	echo 40 > $llccbw/window_ms
done

for llccbw in $bus_dcvs/LLCC/*bwmon-llcc-gold
do
	echo 120 > $llccbw/io_percent
	echo 180 > $llccbw/low_power_io_percent
	echo "1017600 1017600" > $llccbw/max_low_power_cluster_freqs
	echo 1211000 > $llccbw/sched_boost_freq
	echo 1 > $llccbw/use_sched_boost
done

for latfloor in $bus_dcvs/*/*latfloor
do
	echo 25000 > $latfloor/ipm_ceil
done

for qosgold in $bus_dcvs/DDRQOS/*gold
do
	echo 50 > $qosgold/ipm_ceil
done

for qosprime in $bus_dcvs/DDRQOS/*prime
do
	echo 100 > $qosprime/ipm_ceil
done

for ddrprime in $bus_dcvs/DDR/*prime
do
	echo 25 > $ddrprime/freq_scale_pct
	echo 1500 > $ddrprime/freq_scale_floor_mhz
	echo 2800 > $ddrprime/freq_scale_ceil_mhz
done

echo s2idle > /sys/power/mem_sleep
echo N > /sys/devices/system/cpu/qcom_lpm/parameters/sleep_disabled

echo 4 > /proc/sys/kernel/printk

# Change console log level as per console config property
console_config=`getprop persist.vendor.console.silent.config`
case "$console_config" in
	"1")
		echo "Enable console config to $console_config"
		echo 0 > /proc/sys/kernel/printk
	;;
	*)
		echo "Enable console config to $console_config"
	;;
esac

echo 1 > /proc/oplus_scheduler/sched_assist/silver_perf_core

setprop vendor.post_boot.parsed 1
