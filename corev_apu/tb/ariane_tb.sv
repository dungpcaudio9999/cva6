// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 15/04/2017
// Description: Top level testbench module. Instantiates the top level DUT, configures
//              the virtual interfaces and starts the test passed by +UVM_TEST+


import ariane_pkg::*;
import uvm_pkg::*;

`include "uvm_macros.svh"
`include "rvfi_types.svh"

`define MAIN_MEM(P) dut.i_sram.gen_cut[0].i_tc_sram_wrapper.i_tc_sram.init_val[(``P``)]
`define USER_MEM(P) dut.i_sram.gen_cut[0].gen_mem_user.i_tc_sram_wrapper_user.i_tc_sram.init_val[(``P``)]
`ifdef CVA6_RTOS_MEM_MAP
// FU3 cv32a6_rtos: ROM (=ISRAM) and DSRAM are separate writable sram
// instances in ariane_testharness.sv (see `ifdef CVA6_RTOS_MEM_MAP` there),
// distinct from the DRAM array MAIN_MEM/USER_MEM above.
`define ROM_MEM(P) dut.i_rom_sram.gen_cut[0].i_tc_sram_wrapper.i_tc_sram.init_val[(``P``)]
`define DSRAM_MEM(P) dut.i_dsram.gen_cut[0].i_tc_sram_wrapper.i_tc_sram.init_val[(``P``)]
`endif

`ifndef READ_ELF_T
`define READ_ELF_T
import "DPI-C" function void read_elf(input string filename);
import "DPI-C" function byte get_section(output longint address, output longint len);
import "DPI-C" context function void read_section_sv(input longint address, inout byte buffer[]);
`endif

module ariane_tb;

    // cva6 configuration
    localparam config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);

    // RVFI
    localparam type rvfi_instr_t = `RVFI_INSTR_T(CVA6Cfg);
    localparam type rvfi_csr_elmt_t = `RVFI_CSR_ELMT_T(CVA6Cfg);
    localparam type rvfi_csr_t = `RVFI_CSR_T(CVA6Cfg, rvfi_csr_elmt_t);

    // RVFI PROBES
    localparam type rvfi_probes_instr_t = `RVFI_PROBES_INSTR_T(CVA6Cfg);
    localparam type rvfi_probes_csr_t = `RVFI_PROBES_CSR_T(CVA6Cfg);
    localparam type rvfi_probes_t = struct packed {
        rvfi_probes_csr_t csr;
        rvfi_probes_instr_t instr;
    };

    static uvm_cmdline_processor uvcl = uvm_cmdline_processor::get_inst();

    localparam int unsigned CLOCK_PERIOD = 20ns;
    // toggle with RTC period
    localparam int unsigned RTC_CLOCK_PERIOD = 30.517us;
    localparam int unsigned TB_AXI_DATA_WIDTH = 64;
    localparam int unsigned AXI_BYTES = TB_AXI_DATA_WIDTH / 8;

    localparam NUM_WORDS = 2**18;
    logic clk_i;
    logic rst_ni;
    logic rtc_i;

    longint unsigned cycles;
    longint unsigned max_cycles;

    logic [31:0] exit_o;

    string binary = "";

    ariane_testharness #(
        .CVA6Cfg ( CVA6Cfg ),
        .AXI_DATA_WIDTH   ( TB_AXI_DATA_WIDTH ),
        //
        .NUM_WORDS         ( NUM_WORDS ),
        .InclSimDTM        ( 1'b1      ),
        .StallRandomOutput ( 1'b0      ),
        .StallRandomInput  ( 1'b0      )
    ) dut (
        .clk_i,
        .rst_ni,
        .rtc_i,
        .exit_o
    );

    // Clock process
    initial begin
        clk_i = 1'b0;
        rst_ni = 1'b0;
        repeat(8)
            #(CLOCK_PERIOD/2) clk_i = ~clk_i;
        rst_ni = 1'b1;
        forever begin
            #(CLOCK_PERIOD/2) clk_i = 1'b1;
            #(CLOCK_PERIOD/2) clk_i = 1'b0;

            if (cycles > max_cycles)
                $fatal(1, "Simulation reached maximum cycle count of %d", max_cycles);

            cycles++;
        end
    end

    initial if (!$value$plusargs("max_cycles=%d", max_cycles)) max_cycles = 64'hFFFF_FFFF_FFFF_FFFF;

`ifdef WAVE_DUMP
    // [dungpc] Scoped VPD dump (DVE): only the core (+ ISRAM), stops at +wave_stop=<ns> (default 20000).
    // Enable with +define+WAVE_DUMP and DEBUG=1 (-debug_access+all).
    longint unsigned wave_stop_ns;
    initial begin
        if (!$value$plusargs("wave_stop=%d", wave_stop_ns)) wave_stop_ns = 20000;
        $vcdplusfile("boot_smoke.vpd");
        $vcdpluson(0, ariane_tb.dut.i_ariane.i_cva6);
`ifdef CVA6_RTOS_MEM_MAP
        $vcdpluson(0, ariane_tb.dut.i_rom_sram);
`endif
        #(wave_stop_ns);
        $vcdplusoff;
    end
`endif

    initial begin
        forever begin
            rtc_i = 1'b0;
            #(RTC_CLOCK_PERIOD/2) rtc_i = 1'b1;
            #(RTC_CLOCK_PERIOD/2) rtc_i = 1'b0;
        end
    end

    initial begin
        forever begin

            wait (exit_o[0]);

            if ((exit_o >> 1)) begin
                `uvm_error( "Core Test",  $sformatf("*** FAILED *** (tohost = %0d)", (exit_o >> 1)))
            end else begin
                `uvm_info( "Core Test",  $sformatf("*** SUCCESS *** (tohost = %0d)", (exit_o >> 1)), UVM_LOW)
            end

            $finish();
        end
    end

    // for faster simulation we can directly preload the ELF
    // Note that we are loosing the capabilities to use risc-fesvr though
    initial begin
        automatic logic [AXI_BYTES-1:0][7:0] mem_row;
        longint address, load_address, last_load_address, len;
        byte buffer[];
        void'(uvcl.get_arg_value("+elf_file=", binary));

        if (binary != "") begin
            `uvm_info( "Core Test", $sformatf("Preloading ELF: %s", binary), UVM_LOW)

            read_elf(binary);
            // wait with preloading, otherwise randomization will overwrite the existing value
            wait(clk_i);

            last_load_address = 'hFFFFFFFF;
            // while there are more sections to process
            while (get_section(address, len)) begin
                automatic int num_words = (len + AXI_BYTES - 1) / AXI_BYTES;
                `uvm_info( "Core Test", $sformatf("Loading Address: %x, Length: %x", address, len), UVM_NONE)
                buffer = new [num_words * AXI_BYTES];
                read_section_sv(address, buffer);
                // preload memories
                for (int i = 0; i < num_words; i++) begin
                    mem_row = '0;
                    for (int j = 0; j < AXI_BYTES; j++) begin
                        mem_row[j] = buffer[i * AXI_BYTES + j];
                    end
                    load_address = (address[23:0] / AXI_BYTES) + i;
`ifdef CVA6_RTOS_MEM_MAP
                    if (address >= ariane_soc::ROMBase && address < (ariane_soc::ROMBase + ariane_soc::ROMLength)) begin
                        load_address = ((address - ariane_soc::ROMBase) / AXI_BYTES) + i;
                        if (load_address != last_load_address) begin
                            `ROM_MEM(load_address) = mem_row;
                            last_load_address = load_address;
                        end
                    end else if (address >= ariane_soc::DSRAMBase && address < (ariane_soc::DSRAMBase + ariane_soc::DSRAMLength)) begin
                        load_address = ((address - ariane_soc::DSRAMBase) / AXI_BYTES) + i;
                        if (load_address != last_load_address) begin
                            `DSRAM_MEM(load_address) = mem_row;
                            last_load_address = load_address;
                        end
                    end else if (load_address != last_load_address) begin
                        if (address[31:0] < 'h84000000) begin
                            `MAIN_MEM(load_address) = mem_row;
                        end else begin
                             `USER_MEM(load_address) = mem_row;
                        end
                        last_load_address = load_address;
                    end
`else
                    if (load_address != last_load_address) begin
                        if (address[31:0] < 'h84000000) begin
                            `MAIN_MEM(load_address) = mem_row;
                        end else begin
                             `USER_MEM(load_address) = mem_row;
                        end
                        last_load_address = load_address;
                    end else begin
                        `uvm_info( "Debug info", $sformatf(" Address: %x Already Loaded! ELF file might have less than 64 bits granularity on segments.", load_address), UVM_NONE)
                    end
`endif

                end
            end
        end
    end
endmodule
