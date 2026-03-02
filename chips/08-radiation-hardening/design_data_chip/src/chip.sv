module chip #(
    parameter int IN_BYTES  = 7,
    parameter int OUT_BYTES = 6
)(
    input wire clk,
    input wire rst_n,

    input wire in_valid,
    output wire in_ready,
    input  wire [7:0] in_data,

    output reg out_valid,
    input wire out_ready,
    output reg [7:0] out_data
);

    reg [7:0] in_buf [0:IN_BYTES-1];
    reg [$clog2(IN_BYTES):0] in_idx;

    wire signed [7:0] BplusX = $signed(in_buf[0]);
    wire signed [7:0] BminX  = $signed(in_buf[1]);
    wire signed [7:0] BplusY = $signed(in_buf[2]);
    wire signed [7:0] BminY  = $signed(in_buf[3]);
    wire signed [7:0] BplusZ = $signed(in_buf[4]);
    wire signed [7:0] BminZ  = $signed(in_buf[5]);
    wire [7:0] crc_in = in_buf[6];

    wire [8*6-1:0] sensor_flat =
        { in_buf[5], in_buf[4], in_buf[3], in_buf[2], in_buf[1], in_buf[0] };

    wire signed [15:0] omegaPsi;
    wire signed [15:0] omegaTheta;
    wire tmr_mismatch;
    wire tmr_uncorrectable;

    wire rst = ~rst_n;

    wire fire = out_valid && out_ready;

    tmr u_tmr (
        .clk(clk),
        .rst(rst),
        .BplusX(BplusX),
        .BminX(BminX),
        .BplusY(BplusY),
        .BminY(BminY),
        .BplusZ(BplusZ),
        .BminZ(BminZ),
        .omegaPsi(omegaPsi),
        .omegaTheta(omegaTheta),
        .tmr_mismatch(tmr_mismatch),
        .tmr_uncorrectable(tmr_uncorrectable)
    );

    reg crc1_start;
    wire crc1_done;
    wire [7:0] crc1_out;

    crc_controller #(.N(6)) u_crc1 (
        .clk(clk),
        .rst_n(rst_n),
        .start(crc1_start),
        .bytes_flat(sensor_flat),
        .done(crc1_done),
        .crc_out(crc1_out)
    );

    reg crc2_start;
    wire crc2_done;
    wire [7:0] crc2_out;

    wire [7:0] psi_hi = omegaPsi[15:8];
    wire [7:0] psi_lo = omegaPsi[7:0];
    wire [7:0] th_hi  = omegaTheta[15:8];
    wire [7:0] th_lo  = omegaTheta[7:0];

    wire [8*4-1:0] out_flat = { th_lo, th_hi, psi_lo, psi_hi };

    crc_controller #(.N(4)) u_crc2 (
        .clk(clk),
        .rst_n(rst_n),
        .start(crc2_start),
        .bytes_flat(out_flat),
        .done(crc2_done),
        .crc_out(crc2_out)
    );

    reg [7:0] out_buf [0:OUT_BYTES-1];
    reg [$clog2(OUT_BYTES):0] out_idx;

    reg crc_ok;
    reg error_crc;

    wire error_voter = tmr_mismatch;
    wire error_uncorrectable = tmr_uncorrectable;

    wire [7:0] flags_byte = {
        4'b0000,
        error_uncorrectable,
        error_voter,
        error_crc,
        crc_ok
    };

    typedef enum logic [3:0] {
        S_RECV       = 4'd0,
        S_CRC1       = 4'd1,
        S_CRC1_WAIT  = 4'd2,
        S_CHECK      = 4'd3,
        S_TMR_WAIT   = 4'd4,
        S_CRC2_PREP  = 4'd5,
        S_CRC2_START = 4'd6,
        S_CRC2_WAIT  = 4'd9,
        S_CRC2       = 4'd7,
        S_CRC2_LATCH = 4'd10,
        S_SEND       = 4'd8
    } state_t;

    state_t state;

    assign in_ready = (state == S_RECV);

    reg [3:0] wait_cnt;

    integer k;

    always_ff @(posedge clk) begin
    if (!rst_n) begin
        state <= S_RECV;
        in_idx <= 0;

        crc1_start <= 0;
        crc2_start <= 0;

        crc_ok <= 0;
        error_crc <= 0;

        out_valid <= 0;
        out_data <= 8'h00;
        out_idx <= 0;

        wait_cnt <= 0;

        for (k = 0; k < IN_BYTES; k = k + 1)  in_buf[k]  <= 8'h00;
        for (k = 0; k < OUT_BYTES; k = k + 1) out_buf[k] <= 8'h00;

    end else begin
        crc1_start <= 0;
        crc2_start <= 0;

        if (state != S_SEND) begin
            out_valid <= 0;
            out_idx <= 0;
        end

        `ifdef DEBUG
            $display("[%0t] STATE = %0d", $time, state);
        `endif

        case (state)
                S_RECV: begin  
                    crc_ok    <= 0;
                    error_crc <= 0;

                    if (in_valid && in_ready) begin
                        in_buf[in_idx] <= in_data;

                        if (in_idx == IN_BYTES-1) begin
                            in_idx <= 0;
                            crc1_start <= 1;
                            state <= S_CRC1;
                        end else begin
                            in_idx <= in_idx + 1;
                        end
                    end
                end

                S_CRC1: begin
                    if (crc1_done) begin
                        state <= S_CRC1_WAIT;
                    end
                end

                S_CRC1_WAIT: begin
                    // 1 Takt warten bis crc_out stabil ist
                    state <= S_CHECK;
                end

                S_CHECK: begin
                    if (crc1_out == crc_in) begin
                        crc_ok <= 1;
                        error_crc <= 0;
                        wait_cnt <= 0;
                        state <= S_TMR_WAIT;
                    end else begin
                        crc_ok    <= 0;
                        error_crc <= 1;
                        out_buf[0] <= 8'h00;
                        out_buf[1] <= 8'h00;
                        out_buf[2] <= 8'h00;
                        out_buf[3] <= 8'h00;
                        out_buf[4] <= 8'h00;
                        out_buf[5] <= {
                            4'b0000,
                            error_uncorrectable,
                            error_voter,
                            1'b1,  // error_crc
                            1'b0   // crc_ok
                        };
                        state      <= S_SEND;
                    end
                end

                S_TMR_WAIT: begin
                    if (wait_cnt == 4) begin
                        state <= S_CRC2_PREP;
                    end else begin
                        wait_cnt <= wait_cnt + 1;
                    end
                end

                S_CRC2_PREP: begin
                    // 1 Takt warten damit omega stabil sind
                    state <= S_CRC2_START;
                end

                S_CRC2_START: begin
                    crc2_start <= 1;
                    state <= S_CRC2_WAIT;
                end

                S_CRC2_WAIT: begin
                    // 1 Takt warten, damit crc_out wirklich 0 ist
                    state <= S_CRC2;
                end

                S_CRC2: begin
                    `ifdef DEBUG
                        $display("[%0t] CRC2 = %0d", $time, crc2_out);
                    `endif
                    if (crc2_done) begin
                        `ifdef DEBUG
                            $display("[%0t] CRC2_OUT = %0d", $time, crc2_out);
                        `endif
                        // done heißt: letztes Byte wurde gerade eingespeist
                        // CRC_OUT ist erst nächster Takt final
                        state <= S_CRC2_LATCH;
                    end
                end

                S_CRC2_LATCH: begin
                    // jetzt ist crc2_out final
                    out_buf[0] <= psi_hi;
                    out_buf[1] <= psi_lo;
                    out_buf[2] <= th_hi;
                    out_buf[3] <= th_lo;
                    out_buf[4] <= crc2_out;
                    out_buf[5] <= flags_byte;
                    state <= S_SEND;
                end

                S_SEND: begin
                    out_valid <= 1;
                    out_data  <= out_buf[out_idx];

                    if (fire) begin
                        if (out_idx == OUT_BYTES-1) begin
                            out_valid <= 0;
                            out_idx <= 0;
                            state <= S_RECV;
                        end else begin
                            out_idx <= out_idx + 1;
                        end
                    end
                end

                default: begin
                    state <= S_RECV;
                end
            endcase
        end
    end

endmodule
