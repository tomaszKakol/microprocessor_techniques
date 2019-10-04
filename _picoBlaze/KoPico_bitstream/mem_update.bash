#!/bin/bash
# PicoBlaze code bitstream replacer
# modified by k.m. 2012.03.23
# Arguments: -b bit_file_name -m mem_file_name -r ram_module_name [optional] -p [optional]

usage() {
	cat << EOF

  usage: $0 -b BIT_NAME -m MEM_NAME [-r RAM_MODULE_NAME -p]

  This script replace picoBlaze program in bitstream file and load it into FPGA using Impact.

  OPTIONS:
    -b	File containing bitstream
    -m	File containing translated picoBlaze code
    -r	RAM module name (default='ram_1024_x_18')
    -d	Exchange data memory (RAM name is now ram_2048_x_9)
    -p	Program FPGA
    -h	Show this message

  Examples:
    $0 -b ../my_design.bit -m my_psm.mem -p
      Replace bitstream '../my_design.bit' with translated code 'my_psm.mem' and program FPGA

    $0 -b ../my_design.bit -p
      Program FPGA using '../my_design.bit' without changing it.

    $0 -b ../my_design.bit -m my_psm.mem
      Replace bitstream '../my_design.bit' with translated code 'my_psm.mem'.

EOF
}

BIT_NAME=
MEM_NAME=
RAM_NAME=ram_1024_x_18
DO_IMPACT=
DATA_MEM=

while getopts "b:m:r:dph" OPTION
do
	case $OPTION in
		b)
			BIT_NAME=$OPTARG
			BIT_FILE=$(basename "$BIT_NAME")
			BIT_DIR=$(dirname "$BIT_NAME")
			NCD_NAME=${BIT_NAME%.bit}.ncd
			OLD_BIT_NAME=${BIT_NAME%.bit}_old.bit
			
			echo "Bit file path+name='$BIT_NAME'"
			echo "Bit file name='$BIT_FILE'"
			echo "Bit file dir='$BIT_DIR'"
			echo "Ncd file path+name='$NCD_NAME'"
			echo "Old bit file path+name='$OLD_BIT_NAME'"
			;;
		m)
			MEM_NAME=$OPTARG
			TMP_MEM_NAME=${MEM_NAME%.mem}_tmp.mem
			echo $MEM_NAME
			echo $TMP_MEM_NAME
			;;
		d)
			RAM_NAME=ram_2048_x_9
			DATA_MEM=t
			;;
		r)
			RAM_NAME=$OPTARG
			;;
		p)
			DO_IMPACT=t
			IMPACT_FILE="$BIT_DIR"/__impact.cmd
			TMP_IMPACT_FILE="$BIT_DIR"/impact.cmd
			echo "Impact script path+name='$IMPACT_FILE'"
			;;
		h)
			usage
			exit
			;;
		?)
			usage
			exit 1
			;;
	esac
done

MOD_OK=
PROG_OK=
if [ -n "$BIT_NAME" ]; then
	if ! [ -e $BIT_NAME ]; then
		echo ERR: File "$BIT_NAME'" does not exist!
		exit 1
	else
		if [ -n "$MEM_NAME" ] && [ -n "$RAM_NAME" ]; then
			if ! [ -e $NCD_NAME ]; then
				echo ERR: File "'$NCD_NAME'" does not exist!
				exit 1
			elif ! [ -e $MEM_NAME ]; then
				echo ERR: File "'$MEM_NAME'" does not exist!
				exit 1
			else
				MOD_OK=t
			fi
		fi
		if [ -n "$DO_IMPACT" ]; then
			if ! [ -e $IMPACT_FILE ]; then
				echo ERR: File '$IMPACT_FILE' does not exist!
				exit 1
			else
				PROG_OK=t
			fi
		fi
	fi
fi

if [ -z $MOD_OK ] && [ -z $PROG_OK ]; then
  usage
  exit 1
else
	#PATH=$PATH:/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64
	#PATH=$PATH:/drives/g/Xilinx/12.4/ISE_DS/ISE/bin/nt
	PATH=$PATH:/drives/c/Xilinx/12.2/ISE_DS/ISE/bin/nt64  #14.7
	#export LD_PRELOAD=/opt/Xilinx/usb-driver/libusb-driver.so:$LD_PRELOAD


	if [ -n "$MOD_OK" ]; then
		cp $MEM_NAME $TMP_MEM_NAME
		cp $BIT_NAME $OLD_BIT_NAME
		
		sed -i -r -e '1!s/@[0-9ABCDEF]+  //g' -e 's/ 000/ /g' -e 's/^000//g' $TMP_MEM_NAME

		if [ -n "$DATA_MEM" ]; then
			./bitUpdate.bash $RAM_NAME $NCD_NAME $MEM_NAME $BIT_NAME data
		else
			./bitUpdate.bash $RAM_NAME $NCD_NAME $TMP_MEM_NAME $BIT_NAME prog
		fi

		rm $TMP_MEM_NAME
		
	fi

	if [ -n "$PROG_OK" ]; then
		cd $BIT_DIR
		sed "s/BIT_NAME.bit/$BIT_FILE/" __impact.cmd > impact.cmd
		if [ -e impact.cmd ]; then
			impact -batch impact.cmd
		else
			echo ERR: File '$TMP_IMPACT_FILE' does not exist!
			exit 1
		fi
	fi
fi


#cd ..
#impact -batch impact_sh
