module calculator (
    input wire clk,
    input wire rst,

    input wire signed [7:0] BplusX,
    input wire signed [7:0] BminX,
    input wire signed [7:0] BplusY,
    input wire signed [7:0] BminY,
    input wire signed [7:0] BplusZ,
    input wire signed [7:0] BminZ,

    output reg signed [15:0] omegaPsi,
    output reg signed [15:0] omegaTheta
);

    // abs for signed 9-bit
    function automatic [8:0] abs9(input signed [8:0] v);
        abs9 = v[8] ? -v : v;
    endfunction

    // msb index of a 10-bit unsigned value (0..9). If v==0 -> 0.
    function automatic [3:0] msb10(input [9:0] v);
        integer j;
        begin
            msb10 = 0;
            for (j = 0; j < 10; j = j + 1) begin
                if (v[j]) msb10 = j;
            end
        end
    endfunction


    reg signed  [8:0] dx, dy, dz;
    reg signed  [8:0] dx_t, dy_t, dz_t;
    reg         [9:0] sum_mag;
    reg         [9:0] sum_t;
    reg         [3:0] sh;
    reg         [3:0] sh_t;

    always_ff @(posedge clk) begin
        if (rst) begin
            dx <= 0; dy <= 0; dz <= 0;
            sum_mag <= 0; sh <= 0;
            omegaPsi <= 0; omegaTheta <= 0;
        end else begin
            // compute aligned "this-cycle" values (blocking)
            dx_t  = BplusX - BminX;
            dy_t  = BplusY - BminY;
            dz_t  = BplusZ - BminZ;
            sum_t = abs9(dx_t) + abs9(dy_t) + abs9(dz_t);
            sh_t  = (sum_t == 0) ? 0 : msb10(sum_t);

            // keep your original registers updated (nonblocking)
            dx      <= dx_t;
            dy      <= dy_t;
            dz      <= dz_t;
            sum_mag <= sum_t;
            sh      <= sh_t;

            // use the temps for output so numerator/denom are from same sample
            if (sum_t == 0) begin
                omegaPsi   <= 0;
                omegaTheta <= 0;
            end else begin
                omegaPsi   <= ($signed(dy_t)  <<< 8) >>> sh_t;
                omegaTheta <= ($signed(-dz_t) <<< 8) >>> sh_t;
            end
        end
    end

endmodule
