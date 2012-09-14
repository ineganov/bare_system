#===========================================================#
#    Basic JTAG-related functions. These are generic.
#===========================================================#

proc jtag_open {} {
	set hw_name [lindex [get_hardware_names] 0]
	set dv_name [lindex [get_device_names -hardware_name $hw_name] 0]
	puts "Opening device <$hw_name>:<$dv_name>"
	open_device -device_name $dv_name -hardware_name $hw_name
	device_lock -timeout 1000
	}

proc jtag_close {} {
	device_unlock
	close_device
	}

proc jtag_cmd {c} {
	device_virtual_ir_shift -instance_index 0 -ir_value $c
	}

proc jtag_hex {d len} {
	device_virtual_dr_shift -instance_index 0 -dr_value $d -length $len -value_in_hex
	}

proc jtag_hex_32 {d} {
	device_virtual_dr_shift -instance_index 0 -dr_value $d -length 32 -value_in_hex -no_captured_dr_value
	}

proc jtag_bin {d len} {
	device_virtual_dr_shift -instance_index 0 -dr_value $d -length $len
	}

#===========================================================#
#    Instruction generation
#===========================================================#
proc inst_store {data_reg ref_reg offset} { 
	if {[expr {($data_reg < 32) && ($ref_reg < 32)}]} {
		set st [scan "ac000000" "%x"]
		set st [expr {$st | ($data_reg << 16)}]
		set st [expr {$st | ($ref_reg << 21)}]
		set st [expr {$st | ($offset & 65535)}]
		return [format "%08X" $st] }
	puts "ERROR: Register number > 31!"
	}

proc inst_load {data_reg ref_reg offset} {
	if {[expr {($data_reg < 32) && ($ref_reg < 32)}]} {
		set st [scan "8c000000" "%x"]
		set st [expr {$st | ($data_reg << 16)}]
		set st [expr {$st | ($ref_reg << 21)}]
		set st [expr {$st | ($offset & 65535)}]
		return [format "%08X" $st] }
	puts "ERROR: Register number > 31!"
	}

proc inst_lui {reg_num immed} {
	if {$reg_num < 32} {
		set i [scan "3C000000" "%x"]
		set imm [scan $immed "%x"]
		set i [expr {$i | ($reg_num << 16)}]
		set i [expr {$i | ($imm & 65535)}]
		return [format "%08X" $i] }
	puts "ERROR: Register number > 31!"
	}

proc inst_ori {reg_num immed} {
	if {$reg_num < 32} {
		set i [scan "34000000" "%x"]
		set imm [scan $immed "%x"]
		set i [expr {$i | ($reg_num << 21)}]
		set i [expr {$i | ($reg_num << 16)}]
		set i [expr {$i | ($imm & 65535)}]
		return [format "%08X" $i] }
	puts "ERROR: Register number > 31!"
	}

proc inst_jump {addr} {
	set i [scan "08000000" "%x"]
	set i [expr {$i | ($addr >> 2)}]
	return [format "%08X" $i]
	}
	
proc inst_nop {} {return "00000000"}

#===========================================================#
#    CPU-specific JTAG functions
#===========================================================#

proc cpu_reset {} { #simple CPU reset
	jtag_cmd 1
	jtag_bin 100 3
	jtag_bin 000 3
	}

proc cpu_resetp {} { #Reset CPU, leave it paused
	jtag_cmd 1
	jtag_bin 110 3
	jtag_bin 010 3
	}

proc cpu_trace {{n 1}} { 
	jtag_cmd 1
	jtag_bin 010 3	
	
	jtag_cmd 3
	for {set i 0} {$i < $n} {incr i} {
		set str [jtag_hex 0000000000000000 64]
		set addr [string range $str 0 7]
		set inst [string range $str 8 15]
		puts "   $addr: $inst ($i)" 
		}
	}

proc cpu_ftrace {{n 1}} { 
	jtag_cmd 3
	for {set i 0} {$i < $n} {incr i} {
		jtag_hex 0000000000000000 64 }}

proc cpu_show_reg {} {
	set reg_names [list {$zz} {$at} {$v0} {$v1} \
						{$a0} {$a1} {$a2} {$a3} \
						{$t0} {$t1} {$t2} {$t3} \
						{$t4} {$t5} {$t6} {$t7} \
						{$s0} {$s1} {$s2} {$s3} \
						{$s4} {$s5} {$s6} {$s7} \
						{$t8} {$t9} {$k0} {$k1} \
						{$gp} {$sp} {$fp} {$ra}] 

	jtag_cmd 1
	set initial_mode [jtag_bin 011 3]

	jtag_cmd 2
	set ret_addr [jtag_hex [inst_nop] 32]

	for {set i 0} {$i < 32} {incr i} {
		jtag_cmd 2

		jtag_hex_32 [inst_store $i 0 0]
		jtag_hex_32 [inst_nop]
		jtag_hex_32 [inst_nop]
	
		jtag_cmd 4
		set ans [jtag_hex 00000000 32]
		puts [format " %s/r%02d --> %s" [lindex $reg_names $i] $i $ans]
		}
	puts "Ret addr: $ret_addr"

	jtag_cmd 2
	jtag_hex_32 [inst_jump [scan $ret_addr "%x"]]
	jtag_hex_32 [inst_nop]

	jtag_cmd 1
	jtag_bin $initial_mode 3

	jtag_cmd 2
	return 
	}

proc cpu_step {{n 1}} {
	cpu_trace $n
	cpu_show_reg
	return
	}

proc upload_segment {fname segment_offset} { #the offset is 2 higher bytes!!
	set infile [open $fname r]
	set i 0

	jtag_cmd 1
	jtag_bin 011 3

	jtag_cmd 2
	jtag_hex [inst_lui 2 $segment_offset] 32
	
	while { [gets $infile line] >= 0 } {
		if {$line eq "00000000"} {
			jtag_hex_32 [inst_store 0 2 $i]
			} else {
			set hi [string range $line 0 3]
			set lo [string range $line 4 7]
			jtag_hex_32 [inst_lui 1 $hi]
			jtag_hex_32 [inst_ori 1 $lo]
			jtag_hex_32 [inst_store 1 2 $i] 			
			}
		set i [expr {$i + 4}]
		}

	close $infile
	return
	}

proc upload_code {{fname "program.txt"}} {
	upload_segment $fname "4000"
	}

proc upload_data {{fname "data.txt"}} {
	upload_segment $fname "8000"
	}

proc upload {} {
	upload_code
	upload_data
	cpu_reset
	puts "Done"
	}