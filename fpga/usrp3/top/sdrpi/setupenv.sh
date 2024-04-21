#!/bin/bash

VIVADO_VER=2021.1
VIVADO_VER_FULL=2021.1_AR76780
DISPLAY_NAME="USRP-SDRPI"
REPO_BASE_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

declare -A PRODUCT_ID_MAP
PRODUCT_ID_MAP["SDRPI"]="zynq/xc7z020/clg400/-1"

# Set default part for simulation
export ARCH=zynq
export PART_ID="xc7z020/clg400/-1"

source $REPO_BASE_PATH/tools/scripts/setupenv_base.sh