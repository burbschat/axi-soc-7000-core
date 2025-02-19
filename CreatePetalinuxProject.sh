#!/bin/sh

# Set default values
# ...

while getopts p:n:h:x:l:d:t:r:s:f: flag
do
    case "${flag}" in
        p) path=${OPTARG};;
        n) name=${OPTARG};;
        h) hwType=${OPTARG};;
        x) xsa=${OPTARG};;
        l) numLane=${OPTARG};;
        d) numDest=${OPTARG};;
        t) dmaTxBuffCount=${OPTARG};;
        r) dmaRxBuffCount=${OPTARG};;
        s) dmaBuffSize=${OPTARG};;
    esac
done

# Check if the version is 2022 or newer
UBUNTU_VERSION=$(lsb_release -rs | cut -d'.' -f1)
if [[ "$UBUNTU_VERSION" -lt 22 ]]; then
   echo "Error: This script requires Ubuntu 2022 or newer."
   exit 1
fi

# Check the petalinux version
EXPECTED_VERSION="2024.2"
if ! awk -v current="$PETALINUX_VER" -v expected="$EXPECTED_VERSION" \
   'BEGIN {exit !(current == expected)}'; then
   echo "Error: PETALINUX_VER is not set to $EXPECTED_VERSION"
   exit 1
fi

##############################################################################

axi_soc_ultra_plus_core=$(dirname $(readlink -f $0))
aes_stream_drivers=$(realpath $axi_soc_ultra_plus_core/../aes-stream-drivers)
hwDir=$axi_soc_ultra_plus_core/hardware/$hwType
imageDump=${xsa%.*}.petalinux.tar.gz

# Check if the dts directory exists
if [ ! -d "$hwDir" ]
then
   echo "hwDir=$hwDir does NOT exist"
   exit 1
fi

echo "Build Output Path: $path";
echo "Project Name: $name";
echo "Hardware Type: $hwType";
echo "XSA File Path: $xsa";
echo "Image File Path: $imageDump";
echo "Number of DMA lanes: $numLane";
echo "Number of DEST per lane: $numDest";
echo "Number of DMA TX Buffers: $dmaTxBuffCount";
echo "Number of DMA RX Buffers: $dmaRxBuffCount";
echo "DMA Buffer Size: $dmaBuffSize Bytes";
echo "Include RFDC utility: $rfdc";
echo "$axi_soc_ultra_plus_core"
echo "$aes_stream_drivers"

##############################################################################

# Remove existing project if it already exists
cd $path
rm -rf $name

# Create the project
petalinux-create project --template zynqMP --name $name
cd $name
