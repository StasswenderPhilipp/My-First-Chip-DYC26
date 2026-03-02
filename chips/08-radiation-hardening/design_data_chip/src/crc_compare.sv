module crc_compare #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] crc_a,
    input wire [WIDTH-1:0] crc_b,
    output reg crc_equal
);

    always @(posedge clk) begin
        if (!rst_n)
            crc_equal <= 1'b0;
        else
            crc_equal <= (crc_a == crc_b);
    end

endmodule
