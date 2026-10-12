# CVA6 project root
if [ -n "$BASH_VERSION" ]; then
  SCRIPT_PATH="$BASH_SOURCE[0]"
elif [ -n "$ZSH_VERSION" ]; then
  SCRIPT_PATH="${(%):-%N}"
else
  echo "Error: Non recognized shell."
  return
fi
export ROOT_PROJECT=$(readlink -f $(dirname "${SCRIPT_PATH}")/../..)

export RTL_PATH="$ROOT_PROJECT/"
export TB_PATH="$ROOT_PROJECT/verif/tb/core"
export TESTS_PATH="$ROOT_PROJECT/verif/tests"

# RISCV-DV & COREV-DV
export RISCV_DV_ROOT="$ROOT_PROJECT/verif/sim/dv"
export CVA6_DV_ROOT="$ROOT_PROJECT/verif/env/corev-dv"

# [dungpc] Original: bail out when RISCV is not set.
#if [ -z "$RISCV" ]; then
#  echo "Error: RISCV variable undefined."
#  return
#fi
# [dungpc] Default to the xPack GCC 14.2.0 toolchain on hw-station-4
# (GCC >= 11 is required by cva6.py; the lowRISC toolchain is only GCC 10.2).
if [ -z "$RISCV" ]; then
  export RISCV=/home/dungpc/riscv-tools/xpack-riscv-none-elf-gcc-14.2.0-3
fi
if [ ! -d "$RISCV/bin" ]; then
  echo "Error: RISCV=$RISCV has no bin/ directory."
  return
fi
# Set RISCV toolchain-related variables
export LIBRARY_PATH="$RISCV/lib"
export LD_LIBRARY_PATH="$RISCV/lib:$LD_LIBRARY_PATH"
export C_INCLUDE_PATH="$RISCV/include"
export CPLUS_INCLUDE_PATH="$RISCV/include"

# Auto-detect RISC-V tool name prefix if not explicitly given.
if [ -z "$CV_SW_PREFIX" ]; then
    export CV_SW_PREFIX="$(ls -1 $RISCV/bin/riscv* | head -n 1 | rev | cut -d '/' -f 1 | cut -d '-' -f 2- | rev)-"
fi
# Default to auto-detected CC name if not explicitly given.
# [dungpc] Original (kept a stale RISCV_CC left in the shell, e.g. the lowRISC GCC 10.2):
#if [ -z "$RISCV_CC" ]; then
#    export RISCV_CC="$RISCV/bin/${CV_SW_PREFIX}gcc"
#fi
# [dungpc] Always derive CC/OBJCOPY from $RISCV so they match the toolchain above.
export RISCV_CC="$RISCV/bin/${CV_SW_PREFIX}gcc"
export RISCV_GCC="$RISCV_CC"
# Default to auto-detected OBJCOPY name if not explicitly given.
#if [ -z "$RISCV_OBJCOPY" ]; then
#    export RISCV_OBJCOPY="$RISCV/bin/${CV_SW_PREFIX}objcopy"
#fi
export RISCV_OBJCOPY="$RISCV/bin/${CV_SW_PREFIX}objcopy"

# Set verilator and spike related variables
if [ -z "$VERILATOR_INSTALL_DIR" ]; then
    export VERILATOR_INSTALL_DIR="$ROOT_PROJECT"/tools/verilator
fi

if [ -z "$SPIKE_SRC_DIR" -o "$SPIKE_INSTALL_DIR" = "__local__" ]; then
  export SPIKE_SRC_DIR="$ROOT_PROJECT"/verif/core-v-verif/vendor/riscv/riscv-isa-sim
fi

# [dungpc] Keep the original: the repo-local spike (tools/spike) has the libriscv.so/libfesvr.so
# that VCS needs via -sv_lib. ~/tools/spike-cosim only has libriscv.a, which fails to load.
if [ -z "$SPIKE_INSTALL_DIR" -o "$SPIKE_INSTALL_DIR" = "__local__" ]; then
    export SPIKE_INSTALL_DIR="$ROOT_PROJECT"/tools/spike
fi

export SPIKE_PATH="$SPIKE_INSTALL_DIR"/bin

# Update the PATH to add all the tools
export PATH="$VERILATOR_INSTALL_DIR/bin:$RISCV/bin:$PATH"
