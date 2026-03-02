module crc8_stream #(
    parameter POLY = 8'h07
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire valid,
    input wire [7:0] byte_in,
    output reg [7:0] crc_out
);

    integer i;
    reg [7:0] temp;

    always @(posedge clk) begin
        if (!rst_n) begin
            crc_out <= 8'h00;
        end
        else if (start) begin
            crc_out <= 8'h00;
        end
        else if (valid) begin
            temp = crc_out ^ byte_in;

            for (i = 0; i < 8; i = i + 1) begin
                if (temp[7])
                    temp = (temp << 1) ^ POLY;
                else
                    temp = (temp << 1);
            end

            crc_out <= temp;
        end
    end

endmodule
