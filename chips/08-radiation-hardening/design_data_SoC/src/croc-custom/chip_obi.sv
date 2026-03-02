module chip_obi
  import user_pkg::*;
  import croc_pkg::*;
#(
  parameter int unsigned IN_BYTES  = 7,
  parameter int unsigned OUT_BYTES = 6
)(
  input  logic         clk_i,
  input  logic         rst_ni,
  input  logic         testmode_i,

  input  sbr_obi_req_t obi_req_i,
  output sbr_obi_rsp_t obi_rsp_o
);

  localparam int unsigned IN_BASE  = 32'h08;
  localparam int unsigned OUT_BASE = IN_BASE + IN_BYTES * 4;

  //=============================================================================
  // Registers / Buffers
  //=============================================================================
  logic [7:0] in_buffer  [0:IN_BYTES-1];
  logic [7:0] out_buffer [0:OUT_BYTES-1];

  logic start_processing;
  logic output_ready;

  //=============================================================================
  // Chip Instance
  //=============================================================================
  logic       chip_in_valid;
  logic       chip_in_ready;
  logic [7:0] chip_in_data;

  logic       chip_out_valid;
  logic       chip_out_ready;
  logic [7:0] chip_out_data;

  chip #(
    .IN_BYTES  ( IN_BYTES  ),
    .OUT_BYTES ( OUT_BYTES )
  ) i_chip (
    .clk       ( clk_i          ),
    .rst_n     ( rst_ni         ),
    .in_valid  ( chip_in_valid  ),
    .in_ready  ( chip_in_ready  ),
    .in_data   ( chip_in_data   ),
    .out_valid ( chip_out_valid ),
    .out_ready ( chip_out_ready ),
    .out_data  ( chip_out_data  )
  );

  //=============================================================================
  // Input FSM: Feed buffered bytes into chip
  //=============================================================================
  logic [$clog2(IN_BYTES)-1:0] in_count;

  typedef enum logic [1:0] { IN_IDLE, IN_STREAMING } in_state_t;
  in_state_t in_state;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      in_state      <= IN_IDLE;
      in_count      <= '0;
      chip_in_valid <= 1'b0;
      chip_in_data  <= 8'h00;
    end else begin
      case (in_state)
        IN_IDLE: begin
          chip_in_valid <= 1'b0;
          in_count      <= '0;
          if (start_processing) begin
            in_state      <= IN_STREAMING;
            chip_in_data  <= in_buffer[0];
            chip_in_valid <= 1'b1;
          end
        end

        IN_STREAMING: begin
          if (chip_in_ready) begin
            if (in_count == IN_BYTES-1) begin
              in_state      <= IN_IDLE;
              chip_in_valid <= 1'b0;
            end else begin
              in_count     <= in_count + 1'b1;
              chip_in_data <= in_buffer[in_count + 1'b1];
            end
          end
        end

        default: in_state <= IN_IDLE;
      endcase
    end
  end

  //=============================================================================
  // Output FSM: Collect chip output bytes
  //   - ready registriert (1 Takt Pause nach jedem Byte, damit Chip out_data
  //     updaten kann)
  //   - capture nur auf out_fire
  //   - out_buffer wird bei start_processing gecleart
  //=============================================================================
  logic [$clog2(OUT_BYTES)-1:0] out_count;

  typedef enum logic [1:0] {
    OUT_IDLE,
    OUT_RECEIVING,
    OUT_READY
  } out_state_t;

  out_state_t out_state;
  logic out_ready_reg;

  assign chip_out_ready = out_ready_reg;
  wire out_fire = chip_out_valid && chip_out_ready;

  integer j;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      out_state     <= OUT_IDLE;
      out_count     <= '0;
      output_ready  <= 1'b0;
      out_ready_reg <= 1'b0;
      for (j = 0; j < OUT_BYTES; j = j + 1) out_buffer[j] <= 8'h00;
    end else begin

      if (start_processing) begin
        output_ready  <= 1'b0;
        out_state     <= OUT_IDLE;
        out_count     <= '0;
        out_ready_reg <= 1'b1;
        for (j = 0; j < OUT_BYTES; j = j + 1) out_buffer[j] <= 8'h00;
      end

      case (out_state)
        OUT_IDLE: begin
          output_ready  <= 1'b0;
          out_count     <= '0;
          out_ready_reg <= 1'b1;

          if (out_fire) begin
            out_buffer[0] <= chip_out_data;
            out_count     <= 'd1;
            out_state     <= OUT_RECEIVING;
            out_ready_reg <= 1'b0;
          end
        end

        OUT_RECEIVING: begin
          if (out_fire) begin
            out_buffer[out_count] <= chip_out_data;
            out_ready_reg <= 1'b0;  // 1 Takt Pause nach jedem Byte

            if (out_count == OUT_BYTES-1) begin
              out_state    <= OUT_READY;
              output_ready <= 1'b1;
            end else begin
              out_count <= out_count + 1'b1;
            end
          end else begin
            out_ready_reg <= 1'b1;
          end
        end

        OUT_READY: begin
          output_ready  <= 1'b1;
          out_ready_reg <= 1'b0;
        end

        default: out_state <= OUT_IDLE;
      endcase
    end
  end

  //=============================================================================
  // OBI Read-Mux (generisch aus Parametern)
  //=============================================================================
  logic [31:0] rdata;

  always_comb begin
    rdata = 32'hBADC0FFE;

    if (obi_req_i.a.addr[7:0] == 8'h00) begin
      rdata = {31'b0, output_ready};
    end else begin
      for (int i = 0; i < OUT_BYTES; i++) begin
        if (obi_req_i.a.addr[7:0] == 8'(OUT_BASE + i*4)) begin
          rdata = {24'b0, out_buffer[i]};
        end
      end
    end
  end

  //=============================================================================
  // OBI Write-Handler (generisch aus Parametern)
  //=============================================================================
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      start_processing <= 1'b0;
      for (int i = 0; i < IN_BYTES; i++) in_buffer[i] <= 8'h00;
    end else begin
      start_processing <= 1'b0;

      if (obi_req_i.req && obi_req_i.a.we) begin
        for (int i = 0; i < IN_BYTES; i++) begin
          if (obi_req_i.a.addr[7:0] == 8'(IN_BASE + i*4)) begin
            in_buffer[i] <= obi_req_i.a.wdata[7:0];

            // Letztes Byte = Auto-Trigger
            if (i == IN_BYTES-1) begin
              start_processing <= 1'b1;
            end
          end
        end
      end
    end
  end

  //=============================================================================
  // OBI Response
  //=============================================================================

  // Grant sofort (kombinatorisch) - wir akzeptieren immer sofort
  assign obi_rsp_o.gnt     = obi_req_i.req;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) obi_rsp_o.rvalid <= 1'b0;
    else         obi_rsp_o.rvalid <= obi_req_i.req;
  end

  assign obi_rsp_o.r.rdata = rdata;
  assign obi_rsp_o.r.err   = 1'b0;

endmodule