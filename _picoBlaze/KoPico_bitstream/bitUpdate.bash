#!/bin/bash
# A.Greensted

# PicoBlaze Bit file update script

# Assumptions
# 1) The instance name and location appear on the same line
# 2) The location string will always start with RAMB16

# Stages

# Check the required commands are available
for CMD in awk xdl data2mem; do
	type $CMD &> /dev/null
	if [ $? != "0" ]; then
		echo "The command '$CMD' is required and is not in your path"
		exit 1
	fi
done

usage()
{
cat >&2 <<EOF
usage: bitUpdate.sh <rom_name> <ncd_file> <mem_file> <bit_file> <mem_type>

<rom_name> : The Instance name of the PicoBlaze Program RAM
<ncd_file> : The ncd file of the top level system
<mem_file> : The assembled program in mem file format
<bit_file> : The system bit level file to adjust
<mem_type> : prog -- program memory RAMB18, 18-bits, addr 0:3FF
           : data -- data memory    RAMB16, 8-bits,  addr 0:7FF

On success, 'download.bit' is generated, the original bitfile is not altered
EOF
}

# Check and extract Parameters
if [ $# != 5 ]; then
	usage
	exit 1
fi

# Extract Parameters
ROM_NAME=$1
NCD_FILE=$2
MEM_FILE=$3
BIT_FILE=$4
MEM_TYPE=$5

# Check file exist
for F in "$NCD_FILE" "$MEM_FILE" "$BIT_FILE"; do
	if [ ! -e $F ]; then
		echo "File $F does not exist"
		exit 1
	fi
done

# Extract the file base (removes path and .ncd extension)
NAME=$(basename $NCD_FILE .ncd)

if [ "$NAME" = "$XDL_FILE" ]; then
	echo "Could not extract xdl filename"
	exit 1
fi;

# Construct filenames for XDL and BMM files
XDL_FILE="$NAME.xdl"
BMM_FILE="$NAME.bmm"

# Output Parameters
echo "ROM name: $ROM_NAME"
echo "NCD file: $NCD_FILE"
echo "XDL file: $XDL_FILE"
echo "MEM file: $MEM_FILE"
echo "BIT file: $BIT_FILE"

# STAGE 1
# Generate xdl file from ncd

xdl -ncd2xdl $NCD_FILE


# STAGE 2
# Extrate instance and location

AWK_OUT=$(awk -v rom="$ROM_NAME" '{
	if ($1 == "inst" && $2 ~ rom ) {
		print $2, $5;
	}
}' $XDL_FILE 2>/dev/null)

if [ $? != "0" ]; then
	echo "AWK Error"
	exit 1
fi

if [ "$AWK_OUT" = "" ]; then
	echo "Could not find instance"
	exit 1
fi

echo "AWK output=$AWK_OUT"

set -- $AWK_OUT
INSTANCE=${1:1}				# Strip first character (should be a quote)
INSTANCE=${INSTANCE%?}		# Strip last character (should be a quote)
INSTANCE_PREFIX=${2:0}
LOCATION=${2:7}				# Strip of the first 6 characters (should be RAMB16 prefix)

INSTANCE_PREFIX=$(echo "$INSTANCE_PREFIX" | cut -d_ -f 1)

echo "Found instance: $INSTANCE, location: $LOCATION with prefix: $INSTANCE_PREFIX"

LOCATIONX=$(echo "$LOCATION" | cut -dY -f 1)
LOCATIONY=$(echo "$LOCATION" | cut -dY -f 2)
V5_LOCATIONY=$(($LOCATIONY * 2))
V5_LOCATION=$LOCATIONX"Y"$V5_LOCATIONY

echo "For Virtex-5 location $LOCATION corrected to $V5_LOCATION"

# STAGE 3
# Create BMM file
if [ "$MEM_TYPE" = "data" ]; then

	#Data memory BMM
	cat >$BMM_FILE <<EOF
ADDRESS_SPACE myTag RAMB16 INDEX_ADDRESSING [0x00000000:0x000007FF]
	BUS_BLOCK
		$INSTANCE [7:0] PLACED = $V5_LOCATION;
	END_BUS_BLOCK;
END_ADDRESS_SPACE;
EOF

echo "BMM exchanged, MEM_TYPE=data, file=$BMM_FILE"

else

	#Program memory BMM
	cat >$BMM_FILE <<EOF
ADDRESS_SPACE myTag RAMB18 INDEX_ADDRESSING [0x00000000:0x000003FF]
	BUS_BLOCK
		$INSTANCE [17:0] PLACED = $V5_LOCATION;
	END_BUS_BLOCK;
END_ADDRESS_SPACE;
EOF

echo "BMM exchanged, MEM_TYPE=prog, file=$BMM_FILE"

fi

# Stage 4
# Create bitstream

data2mem -bm $BMM_FILE -bd $MEM_FILE -bt $BIT_FILE -o b download.bit
mv download.bit $BIT_FILE

echo "Bitstream created"
