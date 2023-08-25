
// Copyright 2020 OpenHW Group
// Copyright 2020 Datum Technology Corporation
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://solderpad.org/licenses/
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//



// This file specifies all interfaces used by the CV32E40S test bench (uvmt_cv32e40s_tb).
// Most interfaces support tasks to allow control by the ENV or test cases.

`ifndef __UVMT_CV32E40S_TB_IFS_SV__
`define __UVMT_CV32E40S_TB_IFS_SV__


/**
 * clocks and reset
 */
interface uvmt_cv32e40s_clk_gen_if_t (output logic core_clock, output logic core_reset_n);

   import uvm_pkg::*;

   bit       start_clk               = 0;
   // TODO: get the uvme_cv32e40s_* values from random ENV CFG members.
   realtime  core_clock_period       = 1500ps; // uvme_cv32e40s_clk_period * 1ps;
   realtime  reset_deassert_duration = 7400ps; // uvme_cv32e40s_reset_deassert_duarion * 1ps;
   realtime  reset_assert_duration   = 7400ps; // uvme_cv32e40s_reset_assert_duarion * 1ps;

   /**
    * Generates clock and reset signals.
    * If reset_n comes up de-asserted (1'b1), wait a bit, then assert, then de-assert
    * Otherwise, leave reset asserted, wait a bit, then de-assert.
    */
   initial begin
      core_clock   = 0; // uvme_cv32e40s_clk_initial_value;
      core_reset_n = 0; // uvme_cv32e40s_reset_initial_value;
      wait (start_clk);
      fork
         forever begin
            #(core_clock_period/2) core_clock = ~core_clock;
         end
         begin
           if (core_reset_n == 1'b1) #(reset_deassert_duration);
           core_reset_n = 1'b0;
           #(reset_assert_duration);
           core_reset_n = 1'b1;
         end
      join_none
   end

   /**
    * Sets clock period in ps.
    */
   function void set_clk_period ( real clk_period );
      core_clock_period = clk_period * 1ps;
   endfunction : set_clk_period

   /** Triggers the generation of clk. */
   function void start();
      start_clk = 1;
      `uvm_info("CLK_GEN_IF", "uvmt_cv32e40s_clk_gen_if_t.start() called", UVM_NONE)
   endfunction : start

endinterface : uvmt_cv32e40s_clk_gen_if_t

/**
 * Status information generated by the Virtual Peripherals in the DUT WRAPPER memory.
 */
interface uvmt_cv32e40s_vp_status_if_t (
                                  output bit        tests_passed,
                                  output bit        tests_failed,
                                  output bit        exit_valid,
                                  output bit [31:0] exit_value
                                 );

  import uvm_pkg::*;

  // TODO: X/Z checks

endinterface : uvmt_cv32e40s_vp_status_if_t



/**
 * Core status signals.
 */
interface uvmt_cv32e40s_core_status_if_t (
                                    input  wire        core_busy,
                                    input  logic       sec_lvl
                                   );

  import uvm_pkg::*;

endinterface : uvmt_cv32e40s_core_status_if_t


// Interface to debug assertions and covergroups
interface uvmt_cv32e40s_debug_cov_assert_if_t
    import cv32e40s_pkg::*;
    import cv32e40s_rvfi_pkg::*;
    (
    input  clk_i,
    input  rst_ni,

    // External interrupt interface
    input  [31:0] irq_i,
    input         irq_ack_o,
    input  [9:0]  irq_id_o,
    input  [31:0] mie_q,

    input         ex_stage_csr_en,
    input         ex_valid,
    input  [31:0] ex_stage_instr_rdata_i,
    input  [31:0] ex_stage_pc,

    input              wb_stage_instr_valid_i,
    input  [31:0]      wb_stage_instr_rdata_i,
    input  [31:0]      wb_stage_pc, // Program counter in writeback
    input              wb_illegal,
    input              wb_valid,
    input              wb_err,
    input mpu_status_e wb_mpu_status,

    input         id_valid,
    input wire ctrl_state_e  ctrl_fsm_cs,            // Controller FSM states with debug_req
    input         illegal_insn_i,
    input         sys_en_i,
    input         sys_ecall_insn_i,

    // Core signals
    input  [31:0] boot_addr_i,

    // Debug signals
    input         debug_req_i, // From controller
    input         ctrl_fsm_async_debug_allowed,
    input         debug_havereset,
    input         debug_running,
    input         debug_halted,
    input  [31:0] debug_pc_o,
    input         debug_pc_valid_o,

    input         pending_sync_debug, // From controller
    input         pending_async_debug, // From controller
    input         pending_nmi, // From controller
    input         nmi_allowed, // From controller
    input         debug_mode_q, // From controller
    input         debug_mode_if, // From controller
    input         ctrl_halt_ex, // From controller
    input  [31:0] dcsr_q, // From controller
    input  [31:0] dpc_q, // From cs regs
    input  [31:0] dpc_n,
    input  [31:0] dm_halt_addr_i,
    input  [31:0] dm_exception_addr_i,

    input  [31:0] mcause_q,
    input  [31:0] mtvec,
    input  [31:0] mepc_q,
    input  [31:0] tdata1,
    input  [31:0] tdata2,
    input  trigger_match_in_wb,
    input  etrigger_in_wb,

    // Counter related input from cs_registers
    input  [31:0] mcountinhibit_q,
    input  [63:0] mcycle,
    input  [63:0] minstret,
    input  inst_ret,

    // WFI Interface
    input  core_sleep_o,

    input  sys_fence_insn_i,

    input  csr_access,
    input  cv32e40s_pkg::csr_opcode_e csr_op,
    input  [11:0] csr_addr,
    input  csr_we_int,

    output logic is_wfi,
    output logic dpc_will_hit,
    output logic addr_match,
    output logic is_ebreak,
    output logic is_cebreak,
    output logic is_dret,
    output logic is_mulhsu,
    output logic [31:0] pending_enabled_irq,
    input  pc_set,
    input  branch_in_ex
);

  clocking mon_cb @(posedge clk_i);
    input #1step

    irq_i,
    irq_ack_o,
    irq_id_o,
    mie_q,

    wb_stage_instr_valid_i,
    wb_stage_instr_rdata_i,
    wb_valid,

    ctrl_fsm_cs,
    illegal_insn_i,
    sys_en_i,
    sys_ecall_insn_i,
    boot_addr_i,
    debug_req_i,
    debug_mode_q,
    dcsr_q,
    dpc_q,
    dpc_n,
    dm_halt_addr_i,
    dm_exception_addr_i,
    mcause_q,
    mtvec,
    mepc_q,
    tdata1,
    tdata2,
    pending_sync_debug,
    trigger_match_in_wb,
    etrigger_in_wb,
    sys_fence_insn_i,
    mcountinhibit_q,
    mcycle,
    minstret,
    inst_ret,

    core_sleep_o,
    csr_access,
    csr_op,
    csr_addr,
    is_wfi,
    dpc_will_hit,
    addr_match,
    is_ebreak,
    is_cebreak,
    is_dret,
    is_mulhsu,
    pending_enabled_irq,
    pc_set,
    branch_in_ex;
  endclocking : mon_cb

endinterface : uvmt_cv32e40s_debug_cov_assert_if_t

interface uvmt_cv32e40s_support_logic_module_i_if_t
   import cv32e40s_pkg::*;
   import cv32e40s_rvfi_pkg::*;
   import uvmt_cv32e40s_base_test_pkg::*;
   (

   /* obi bus protocol signal information:
   ---------------------------------------
   - The obi protocol between alignmentbuffer (ab) and instructoin (i) interface (i) mpu (m) is refered to as abiim
   - The obi protocol between LSU (l) mpu (m) and LSU (l) is refered to as lml
   - The obi protocol between LSU (l) respons (r) filter (f) and OBI (o) data (d) interface (i) is refered to as lrfodi
   */

   input logic clk,
   input logic rst_n,
// file change in 40s sendt to 40x
// 40S // 40S // 40S // 40S
   //Decoder:
   input logic [31:0] if_instr,
   input logic [31:0] id_instr,
   input logic [31:0] ex_instr,
   input logic [31:0] wb_instr,

   //Controller fsm control signals output
   input ctrl_fsm_t ctrl_fsm_o,

   input logic fetch_enable,
   input logic debug_req_i,
   input logic irq_ack,
   input logic wb_valid,
   input logic [31:0] wb_tselect,
   input logic [31:0] wb_tdata1,
   input logic [31:0] wb_tdata2,
   input logic [31:0] tdata1_array[CORE_PARAM_DBG_NUM_TRIGGERS+1],
   input logic [31:0] tdata2_array[CORE_PARAM_DBG_NUM_TRIGGERS+1],

   //Obi signals:

   //Data bus inputs
   input logic data_bus_rvalid,
   input logic data_bus_gnt,
   input logic data_bus_gntpar,
   input logic data_bus_req,

   //Instr bus inputs
   input logic instr_bus_rvalid,
   input logic instr_bus_gnt,
   input logic instr_bus_gntpar,
   input logic instr_bus_req,

   //Abiim bus inputs
   input logic abiim_bus_rvalid,
   input logic abiim_bus_gnt,
   input logic abiim_bus_req,

   //Lml bus inputs
   input logic lml_bus_rvalid,
   input logic lml_bus_gnt,
   input logic lml_bus_req,

   //Instr bus inputs
   input logic lrfodi_bus_rvalid,
   input logic lrfodi_bus_gnt,
   input logic lrfodi_bus_req,

   //Obi request information
   input logic req_is_store,
   input logic req_instr_integrity,
   input logic req_data_integrity,
   input logic [31:0] instr_req_pc

   );

   modport driver_mp (
     input  clk,
      rst_n,

      if_instr,
      id_instr,
      ex_instr,
      wb_instr,

      tdata1_array,
      tdata2_array,

      ctrl_fsm_o,

      fetch_enable,
      debug_req_i,
      irq_ack,
      wb_valid,
      wb_tselect,
      wb_tdata1,
      wb_tdata2,

      data_bus_rvalid,
      data_bus_gnt,
      data_bus_gntpar,
      data_bus_req,

      instr_bus_rvalid,
      instr_bus_gnt,
      instr_bus_gntpar,
      instr_bus_req,

      abiim_bus_rvalid,
      abiim_bus_gnt,
      abiim_bus_req,

      lml_bus_rvalid,
      lml_bus_gnt,
      lml_bus_req,

      lrfodi_bus_rvalid,
      lrfodi_bus_gnt,
      lrfodi_bus_req,

      req_is_store,
      req_instr_integrity,
      req_data_integrity,
      instr_req_pc
   );

endinterface : uvmt_cv32e40s_support_logic_module_i_if_t


interface uvmt_cv32e40s_support_logic_module_o_if_t;
   import cv32e40s_pkg::*;
   import cv32e40s_rvfi_pkg::*;
   import uvmt_cv32e40s_base_test_pkg::*;
   import isa_decoder_pkg::*;

   //Decoder:
   asm_t asm_if;
   asm_t asm_id;
   asm_t asm_ex;
   asm_t asm_wb;
   asm_t asm_rvfi;

   // Indicates that a new obi data req arrives after an exception is triggered.
   // Used to verify exception timing with multiop instruction
   logic req_after_exception;
   logic [CORE_PARAM_DBG_NUM_TRIGGERS:0] trigger_match_mem;
   logic [CORE_PARAM_DBG_NUM_TRIGGERS:0] trigger_match_execute;
   logic [CORE_PARAM_DBG_NUM_TRIGGERS:0] trigger_match_exception;
   logic [CORE_PARAM_DBG_NUM_TRIGGERS:0] is_trigger_match;


   // support logic signals for the obi bus protocol:

   // continued address and respons phase indicators, indicates address and respons phases
   // of more than one cycle
   logic data_bus_addr_ph_cont;
   logic data_bus_resp_ph_cont;

   logic instr_bus_addr_ph_cont;
   logic instr_bus_resp_ph_cont;

   logic abiim_bus_addr_ph_cont;
   logic alignment_buff_resp_ph_cont;

   logic lml_bus_addr_ph_cont;
   logic lsu_resp_ph_cont;

   logic lrfodi_bus_addr_ph_cont;
   logic lrfodi_bus_resp_ph_cont;

   // address phase counter, used to verify no response phase preceedes an address phase
   integer data_bus_v_addr_ph_cnt;
   integer instr_bus_v_addr_ph_cnt;
   integer alignment_buff_addr_ph_cnt;
   integer lsu_addr_ph_cnt;
   //integer lrfodi_bus_v_addr_ph_cnt; TODO: remove?

   // Counter for ack'ed irqs
   logic [31:0] cnt_irq_ack;
   logic [31:0] cnt_rvfi_irqs;

   //Signals stating whether the request for the current response had the attribute value or not
   logic req_was_store;
   logic instr_req_had_integrity;
   logic data_req_had_integrity;
   logic gntpar_error_in_response_instr;
   logic gntpar_error_in_response_data;
   logic [31:0] instr_resp_pc;

   // indicates that the current rvfi_valid instruction is the first in a debug handler
   logic first_debug_ins;

   // this signal indicates core startup
   logic first_fetch;

   // signal indicates that a debug_req has been observed whithin
   // a timeframe where the core could oboserve it
   logic recorded_dbg_req;

   modport master_mp (
      output asm_if,
         asm_id,
         asm_ex,
         asm_wb,
         asm_rvfi,

         req_after_exception,
         trigger_match_mem,
         trigger_match_execute,
         trigger_match_exception,
         is_trigger_match,

         data_bus_addr_ph_cont,
         data_bus_resp_ph_cont,
         data_bus_v_addr_ph_cnt,

         instr_bus_addr_ph_cont,
         instr_bus_resp_ph_cont,
         instr_bus_v_addr_ph_cnt,

         abiim_bus_addr_ph_cont,
         alignment_buff_resp_ph_cont,
         alignment_buff_addr_ph_cnt,

         lml_bus_addr_ph_cont,
         lsu_resp_ph_cont,
         lsu_addr_ph_cnt,

         lrfodi_bus_addr_ph_cont,
         lrfodi_bus_resp_ph_cont,
         //lrfodi_bus_v_addr_ph_cnt, TODO: remove?

         cnt_irq_ack,
         cnt_rvfi_irqs,

         req_was_store,
         instr_req_had_integrity,
         data_req_had_integrity,
         gntpar_error_in_response_instr,
         gntpar_error_in_response_data,
         instr_resp_pc,
         first_debug_ins,
         first_fetch,
         recorded_dbg_req
   );

   modport slave_mp (
      input asm_if,
         asm_id,
         asm_ex,
         asm_wb,
         asm_rvfi,

         req_after_exception,
         trigger_match_mem,
         trigger_match_execute,
         trigger_match_exception,
         is_trigger_match,

         data_bus_addr_ph_cont,
         data_bus_resp_ph_cont,
         data_bus_v_addr_ph_cnt,

         instr_bus_addr_ph_cont,
         instr_bus_resp_ph_cont,
         instr_bus_v_addr_ph_cnt,

         abiim_bus_addr_ph_cont,
         alignment_buff_resp_ph_cont,
         alignment_buff_addr_ph_cnt,

         lml_bus_addr_ph_cont,
         lsu_resp_ph_cont,
         lsu_addr_ph_cnt,

         lrfodi_bus_addr_ph_cont,
         lrfodi_bus_resp_ph_cont,

         cnt_irq_ack,
         cnt_rvfi_irqs,

         req_was_store,
         instr_req_had_integrity,
         data_req_had_integrity,
         gntpar_error_in_response_instr,
         gntpar_error_in_response_data,
         instr_resp_pc,
         first_debug_ins,
         first_fetch,
         recorded_dbg_req
   );

endinterface : uvmt_cv32e40s_support_logic_module_o_if_t



`endif // __UVMT_CV32E40S_TB_IFS_SV__
