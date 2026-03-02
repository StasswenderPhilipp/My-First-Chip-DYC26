module crc_controller #(
    parameter int N = 6
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [8*N-1:0] bytes_flat,

    output reg done,
    output wire [7:0] crc_out
);

    logic crc_start, crc_valid;
    logic [7:0] crc_byte;
    logic [$clog2(N):0] idx;
    logic busy;

    crc8_stream u_crc (
        .clk (clk),
        .rst_n (rst_n),
        .start (crc_start),
        .valid (crc_valid),
        .byte_in (crc_byte),
        .crc_out (crc_out)
    );

    function automatic [7:0] get_byte(input int k);
        get_byte = bytes_flat[8*k +: 8];
    endfunction

    `ifdef DEBUG
    always_ff @(posedge clk) begin
        if (crc_start) begin
            $display("CRC START");
        end
        if (crc_valid) begin
            $display("CRC BYTE[%0d] = %0d (0x%02h)", idx, crc_byte, crc_byte);
        end
    end
    `endif

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            crc_start <= 1'b0;
            crc_valid <= 1'b0;
            crc_byte <= 8'd0;
            idx <= '0;
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            crc_start <= 1'b0;
            crc_valid <= 1'b0;
            done <= 1'b0;

            if (start && !busy) begin
                busy <= 1'b1;
                idx <= '0;
                crc_start <= 1'b1;
            end
            else if (busy) begin
                crc_valid <= 1'b1;
                crc_byte <= get_byte(idx);

                if (idx == N-1) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end

                idx <= idx + 1'b1;
            end
        end
    end

endmodule
