//------------------------------------------------------------------------------
// Copyright (c) 2026 FPT Telecom. All rights reserved.
//
// Direct CVA6-to-AXI bridge for cacheless FU3 configurations.
//
// The bridge intentionally contains no tag/data arrays, refill machinery,
// cache controller, write buffer, or cache-maintenance state.  Instruction
// fetches and data loads use one serialized AXI read channel.  Data stores are
// acknowledged only after the AXI write response so a younger load cannot
// pass a store in the absence of cache/write-buffer forwarding.
//------------------------------------------------------------------------------

module cva6_nocache_subsystem
  import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type icache_areq_t = logic,
    parameter type icache_arsp_t = logic,
    parameter type icache_dreq_t = logic,
    parameter type icache_drsp_t = logic,
    parameter type dcache_req_i_t = logic,
    parameter type dcache_req_o_t = logic,
    parameter int unsigned NumPorts = 4,
    parameter type noc_req_t = logic,
    parameter type noc_resp_t = logic
) (
    input  logic clk_i,
    input  logic rst_ni,

    input  logic         icache_flush_i,
    output logic         icache_miss_o,
    input  icache_areq_t icache_areq_i,
    output icache_arsp_t icache_areq_o,
    input  icache_dreq_t icache_dreq_i,
    output icache_drsp_t icache_dreq_o,

    input  logic                         dcache_flush_i,
    output logic                         dcache_flush_ack_o,
    output logic                         dcache_miss_o,
    input  amo_req_t                     dcache_amo_req_i,
    output amo_resp_t                    dcache_amo_resp_o,
    input  dcache_req_i_t [NumPorts-1:0] dcache_req_ports_i,
    output dcache_req_o_t [NumPorts-1:0] dcache_req_ports_o,
    output logic                         wbuffer_empty_o,
    output logic                         wbuffer_not_ni_o,

    output noc_req_t  noc_req_o,
    input  noc_resp_t noc_resp_i
);

  localparam int unsigned PortSelWidth = (NumPorts > 1) ? $clog2(NumPorts) : 1;
  typedef logic [PortSelWidth-1:0] port_sel_t;

  typedef enum logic [2:0] {
    RD_IDLE,
    RD_IF_TRANSLATE,
    RD_IF_ADDRESS,
    RD_IF_DATA,
    RD_D_TAG,
    RD_D_ADDRESS,
    RD_D_DATA
  } read_state_t;

  typedef enum logic [1:0] {
    WR_IDLE,
    WR_SEND,
    WR_RESPONSE
  } write_state_t;

  read_state_t  read_state_q, read_state_d;
  write_state_t write_state_q, write_state_d;

  logic [CVA6Cfg.VLEN-1:0]        if_vaddr_q, if_vaddr_d;
  logic [CVA6Cfg.AxiAddrWidth-1:0] read_addr_q, read_addr_d;
  logic [1:0]                       read_size_q, read_size_d;
  logic [CVA6Cfg.DcacheIdWidth-1:0] read_id_q, read_id_d;
  port_sel_t                        read_port_q, read_port_d;
  logic [CVA6Cfg.DCACHE_INDEX_WIDTH-1:0] read_index_q, read_index_d;
  logic if_killed_q, if_killed_d;

  logic [CVA6Cfg.AxiAddrWidth-1:0] write_addr_q, write_addr_d;
  logic [CVA6Cfg.XLEN-1:0]         write_data_q, write_data_d;
  logic [(CVA6Cfg.XLEN/8)-1:0]     write_be_q, write_be_d;
  logic [1:0]                       write_size_q, write_size_d;
  port_sel_t                        write_port_q, write_port_d;
  logic write_aw_done_q, write_aw_done_d;
  logic write_w_done_q, write_w_done_d;

  logic data_write_request;
  logic data_read_request;
  logic data_read_active;
  noc_req_t noc_read_req, noc_write_req;
  dcache_req_o_t [NumPorts-1:0] dcache_read_rsp;
  logic [NumPorts-1:0] dcache_write_gnt;

  always_comb begin : find_data_requests
    data_write_request = 1'b0;
    data_read_request  = 1'b0;
    for (int unsigned p = 0; p < NumPorts; p++) begin
      if (dcache_req_ports_i[p].data_req && dcache_req_ports_i[p].data_we) begin
        data_write_request = 1'b1;
      end
      if (dcache_req_ports_i[p].data_req && !dcache_req_ports_i[p].data_we) begin
        data_read_request = 1'b1;
      end
    end
  end

  assign data_read_active = read_state_q inside {RD_D_TAG, RD_D_ADDRESS, RD_D_DATA};

  always_comb begin : read_channel_comb
    logic found_read;
    logic read_error;

    read_state_d = read_state_q;
    if_vaddr_d   = if_vaddr_q;
    read_addr_d  = read_addr_q;
    read_size_d  = read_size_q;
    read_id_d    = read_id_q;
    read_port_d  = read_port_q;
    read_index_d = read_index_q;
    if_killed_d  = if_killed_q | icache_dreq_i.kill_s2 | icache_flush_i;

    icache_areq_o = '0;
    icache_dreq_o = '0;
    icache_dreq_o.vaddr = if_vaddr_q;
    icache_miss_o = 1'b0;

    for (int unsigned p = 0; p < NumPorts; p++) begin
      dcache_read_rsp[p] = '0;
    end
    dcache_miss_o = 1'b0;

    noc_read_req = '0;
    noc_read_req.ar.id     = '0;
    noc_read_req.ar.addr   = read_addr_q;
    noc_read_req.ar.len    = '0;
    noc_read_req.ar.size   = axi_pkg::size_t'(read_size_q);
    noc_read_req.ar.burst  = axi_pkg::BURST_INCR;
    noc_read_req.ar.lock   = 1'b0;
    noc_read_req.ar.cache  = '0;
    noc_read_req.ar.prot   = '0;
    noc_read_req.ar.qos    = '0;
    noc_read_req.ar.region = '0;
    noc_read_req.ar.user   = '0;

    read_error = noc_resp_i.r.resp inside {axi_pkg::RESP_SLVERR, axi_pkg::RESP_DECERR};

    unique case (read_state_q)
      RD_IDLE: begin
        if_killed_d = 1'b0;

        // Data writes have priority over data reads.  A pending load has
        // priority over fetch so a continuously requesting frontend cannot
        // starve LSU traffic.
        if ((write_state_q == WR_IDLE) && !data_write_request && data_read_request) begin
          found_read = 1'b0;
          for (int unsigned p = 0; p < NumPorts; p++) begin
            if (!found_read && dcache_req_ports_i[p].data_req &&
                !dcache_req_ports_i[p].data_we) begin
              found_read = 1'b1;
              read_port_d  = port_sel_t'(p);
              read_index_d = dcache_req_ports_i[p].address_index;
              read_size_d  = dcache_req_ports_i[p].data_size;
              read_id_d    = dcache_req_ports_i[p].data_id;
              dcache_read_rsp[p].data_gnt = 1'b1;
              read_state_d = RD_D_TAG;
            end
          end
        end else begin
          // Do not advertise a handshake for a request that is being killed.
          // The frontend advances its NPC whenever ready is high; asserting
          // ready together with kill_s1 would otherwise skip the redirect
          // target on the next cycle.
          icache_dreq_o.ready = !icache_dreq_i.kill_s1;
          if (icache_dreq_i.req && icache_dreq_o.ready) begin
            if_vaddr_d  = icache_dreq_i.vaddr;
            // kill_s2 belongs to the request already in stage 2.  A branch
            // prediction can present its target as a new stage-1 request in
            // that same cycle, so carrying kill_s2 into this new request
            // would drop the target and skip one fetch word.
            if_killed_d = 1'b0;
            read_state_d = RD_IF_TRANSLATE;
          end
        end
      end

      RD_IF_TRANSLATE: begin
        icache_areq_o.fetch_req   = 1'b1;
        icache_areq_o.fetch_vaddr =
            (if_vaddr_q >> CVA6Cfg.FETCH_ALIGN_BITS) << CVA6Cfg.FETCH_ALIGN_BITS;

        if (icache_areq_i.fetch_valid) begin
          if (icache_areq_i.fetch_exception.valid) begin
            if (!if_killed_d) begin
              icache_dreq_o.valid = 1'b1;
              icache_dreq_o.ex    = icache_areq_i.fetch_exception;
            end
            read_state_d = RD_IDLE;
          end else if (if_killed_d) begin
            read_state_d = RD_IDLE;
          end else begin
            read_addr_d = icache_areq_i.fetch_paddr[CVA6Cfg.AxiAddrWidth-1:0];
            read_size_d = 2'($clog2(CVA6Cfg.FETCH_WIDTH / 8));
            read_state_d = RD_IF_ADDRESS;
          end
        end
      end

      RD_IF_ADDRESS: begin
        noc_read_req.ar_valid = 1'b1;
        noc_read_req.ar.id    = CVA6Cfg.AxiIdWidth'(0);
        noc_read_req.ar.prot  = 3'b100;
        if (noc_resp_i.ar_ready) begin
          read_state_d = RD_IF_DATA;
          icache_miss_o = 1'b1;
        end
      end

      RD_IF_DATA: begin
        noc_read_req.r_ready = 1'b1;
        if (noc_resp_i.r_valid) begin
          if (!if_killed_d) begin
            icache_dreq_o.valid = 1'b1;
            icache_dreq_o.data  = noc_resp_i.r.data[CVA6Cfg.FETCH_WIDTH-1:0];
            icache_dreq_o.user  = CVA6Cfg.FETCH_USER_EN ?
                noc_resp_i.r.user[CVA6Cfg.FETCH_USER_WIDTH-1:0] : '0;
            if (read_error) begin
              icache_dreq_o.ex.valid = 1'b1;
              icache_dreq_o.ex.cause = riscv::INSTR_ACCESS_FAULT;
            end
          end
          read_state_d = RD_IDLE;
        end
      end

      RD_D_TAG: begin
        // Loads are virtually indexed when granted.  CVA6 supplies the
        // translated physical tag in the following SEND_TAG cycle.
        //
        // The load unit kills a granted request instead of sending its tag
        // when the load must not reach memory yet: a non-idempotent (device)
        // load that is not at commit time, a flush, or an exception. Like
        // the upstream cache controllers, drop it without any AXI access and
        // close the transaction towards the port. Issuing the read here would
        // perform speculative/repeated reads of side-effecting registers.
        if (dcache_req_ports_i[read_port_q].kill_req) begin
          dcache_read_rsp[read_port_q].data_rvalid = 1'b1;
          dcache_read_rsp[read_port_q].data_rid    = read_id_q;
          read_state_d = RD_IDLE;
        end else if (dcache_req_ports_i[read_port_q].tag_valid) begin
          read_addr_d = CVA6Cfg.AxiAddrWidth'({
              dcache_req_ports_i[read_port_q].address_tag, read_index_q
          });
          read_state_d = RD_D_ADDRESS;
        end
      end

      RD_D_ADDRESS: begin
        noc_read_req.ar_valid = 1'b1;
        noc_read_req.ar.id    = CVA6Cfg.AxiIdWidth'(1);
        if (noc_resp_i.ar_ready) begin
          read_state_d = RD_D_DATA;
          dcache_miss_o = 1'b1;
        end
      end

      RD_D_DATA: begin
        noc_read_req.r_ready = 1'b1;
        if (noc_resp_i.r_valid) begin
          dcache_read_rsp[read_port_q].data_rvalid = 1'b1;
          dcache_read_rsp[read_port_q].data_rid    = read_id_q;
          dcache_read_rsp[read_port_q].data_rdata  =
              noc_resp_i.r.data[CVA6Cfg.XLEN-1:0];
          dcache_read_rsp[read_port_q].data_ruser  = CVA6Cfg.DATA_USER_EN ?
              noc_resp_i.r.user[CVA6Cfg.DCACHE_USER_WIDTH-1:0] : '0;
          dcache_read_rsp[read_port_q].data_error  = read_error;
          read_state_d = RD_IDLE;
        end
      end

      default: read_state_d = RD_IDLE;
    endcase
  end

  always_comb begin : write_channel_comb
    logic found_write;
    logic aw_accept;
    logic w_accept;

    write_state_d   = write_state_q;
    write_addr_d    = write_addr_q;
    write_data_d    = write_data_q;
    write_be_d      = write_be_q;
    write_size_d    = write_size_q;
    write_port_d    = write_port_q;
    write_aw_done_d = write_aw_done_q;
    write_w_done_d  = write_w_done_q;

    noc_write_req = '0;
    dcache_write_gnt = '0;
    noc_write_req.aw.id     = CVA6Cfg.AxiIdWidth'(2);
    noc_write_req.aw.addr   = write_addr_q;
    noc_write_req.aw.len    = '0;
    noc_write_req.aw.size   = axi_pkg::size_t'(write_size_q);
    noc_write_req.aw.burst  = axi_pkg::BURST_INCR;
    noc_write_req.aw.lock   = 1'b0;
    noc_write_req.aw.cache  = '0;
    noc_write_req.aw.prot   = '0;
    noc_write_req.aw.qos    = '0;
    noc_write_req.aw.region = '0;
    noc_write_req.aw.atop   = '0;
    noc_write_req.aw.user   = '0;
    noc_write_req.w.data    = write_data_q;
    noc_write_req.w.strb    = write_be_q;
    noc_write_req.w.last    = 1'b1;
    noc_write_req.w.user    = '0;

    aw_accept = 1'b0;
    w_accept  = 1'b0;

    unique case (write_state_q)
      WR_IDLE: begin
        write_aw_done_d = 1'b0;
        write_w_done_d  = 1'b0;
        if (!data_read_active) begin
          found_write = 1'b0;
          for (int unsigned p = 0; p < NumPorts; p++) begin
            if (!found_write && dcache_req_ports_i[p].data_req &&
                dcache_req_ports_i[p].data_we) begin
              found_write = 1'b1;
              write_port_d = port_sel_t'(p);
              write_addr_d = CVA6Cfg.AxiAddrWidth'({
                  dcache_req_ports_i[p].address_tag,
                  dcache_req_ports_i[p].address_index
              });
              write_data_d = dcache_req_ports_i[p].data_wdata;
              write_be_d   = dcache_req_ports_i[p].data_be;
              write_size_d = dcache_req_ports_i[p].data_size;
              write_state_d = WR_SEND;
            end
          end
        end
      end

      WR_SEND: begin
        noc_write_req.aw_valid = !write_aw_done_q;
        noc_write_req.w_valid  = !write_w_done_q;
        aw_accept = !write_aw_done_q && noc_resp_i.aw_ready;
        w_accept  = !write_w_done_q && noc_resp_i.w_ready;
        write_aw_done_d = write_aw_done_q | aw_accept;
        write_w_done_d  = write_w_done_q | w_accept;
        if ((write_aw_done_q | aw_accept) && (write_w_done_q | w_accept)) begin
          write_state_d = WR_RESPONSE;
        end
      end

      WR_RESPONSE: begin
        noc_write_req.b_ready = 1'b1;
        if (noc_resp_i.b_valid) begin
          // Normal stores have no architectural response channel in this
          // CVA6 interface.  Completion (including an AXI error response) is
          // therefore represented by the grant, matching the legacy cache.
          dcache_write_gnt[write_port_q] = 1'b1;
          write_state_d = WR_IDLE;
        end
      end

      default: write_state_d = WR_IDLE;
    endcase
  end

  always_comb begin : combine_channels
    noc_req_o = noc_read_req;
    noc_req_o.aw       = noc_write_req.aw;
    noc_req_o.aw_valid = noc_write_req.aw_valid;
    noc_req_o.w        = noc_write_req.w;
    noc_req_o.w_valid  = noc_write_req.w_valid;
    noc_req_o.b_ready  = noc_write_req.b_ready;

    for (int unsigned p = 0; p < NumPorts; p++) begin
      dcache_req_ports_o[p] = dcache_read_rsp[p];
      dcache_req_ports_o[p].data_gnt =
          dcache_read_rsp[p].data_gnt | dcache_write_gnt[p];
    end
  end

  assign dcache_flush_ack_o = dcache_flush_i;
  assign dcache_amo_resp_o  = '0;
  assign wbuffer_empty_o    = (write_state_q == WR_IDLE);
  assign wbuffer_not_ni_o   = (write_state_q == WR_IDLE);

  always_ff @(posedge clk_i or negedge rst_ni) begin : state_registers
    if (!rst_ni) begin
      read_state_q    <= RD_IDLE;
      write_state_q   <= WR_IDLE;
      if_vaddr_q      <= '0;
      read_addr_q     <= '0;
      read_size_q     <= '0;
      read_id_q       <= '0;
      read_port_q     <= '0;
      read_index_q    <= '0;
      if_killed_q     <= 1'b0;
      write_addr_q    <= '0;
      write_data_q    <= '0;
      write_be_q      <= '0;
      write_size_q    <= '0;
      write_port_q    <= '0;
      write_aw_done_q <= 1'b0;
      write_w_done_q  <= 1'b0;
    end else begin
      read_state_q    <= read_state_d;
      write_state_q   <= write_state_d;
      if_vaddr_q      <= if_vaddr_d;
      read_addr_q     <= read_addr_d;
      read_size_q     <= read_size_d;
      read_id_q       <= read_id_d;
      read_port_q     <= read_port_d;
      read_index_q    <= read_index_d;
      if_killed_q     <= if_killed_d;
      write_addr_q    <= write_addr_d;
      write_data_q    <= write_data_d;
      write_be_q      <= write_be_d;
      write_size_q    <= write_size_d;
      write_port_q    <= write_port_d;
      write_aw_done_q <= write_aw_done_d;
      write_w_done_q  <= write_w_done_d;
    end
  end

  // pragma translate_off
  initial begin
    assert (CVA6Cfg.DCacheType == config_pkg::NOCACHE)
    else $fatal(1, "[nocache] bridge selected for a cached configuration");
    assert (CVA6Cfg.AxiDataWidth == CVA6Cfg.XLEN &&
            CVA6Cfg.FETCH_WIDTH == CVA6Cfg.AxiDataWidth)
    else $fatal(1, "[nocache] v1 requires equal 32-bit fetch/data/AXI widths");
    assert (!CVA6Cfg.RVA && !CVA6Cfg.MmuPresent && !CVA6Cfg.CvxifEn)
    else $fatal(1, "[nocache] v1 does not support AMO, MMU, or accelerator ports");
  end
  // pragma translate_on

endmodule
