module tmr (
    input  wire clk,
    input  wire rst,

    input  wire signed [7:0] BplusX,
    input  wire signed [7:0] BminX,
    input  wire signed [7:0] BplusY,
    input  wire signed [7:0] BminY,
    input  wire signed [7:0] BplusZ,
    input  wire signed [7:0] BminZ,

    output wire signed [15:0] omegaPsi,
    output wire signed [15:0] omegaTheta,

    output wire tmr_mismatch,
    output wire tmr_uncorrectable
);

    wire signed [15:0] psi0, psi1, psi2;
    wire signed [15:0] th0,  th1,  th2;

    calculator u_calc0 (
        .clk(clk), .rst(rst),
        .BplusX(BplusX), .BminX(BminX),
        .BplusY(BplusY), .BminY(BminY),
        .BplusZ(BplusZ), .BminZ(BminZ),
        .omegaPsi(psi0),
        .omegaTheta(th0)
    );

    calculator u_calc1 (
        .clk(clk), .rst(rst),
        .BplusX(BplusX), .BminX(BminX),
        .BplusY(BplusY), .BminY(BminY),
        .BplusZ(BplusZ), .BminZ(BminZ),
        .omegaPsi(psi1),
        .omegaTheta(th1)
    );

    calculator u_calc2 (
        .clk(clk), .rst(rst),
        .BplusX(BplusX), .BminX(BminX),
        .BplusY(BplusY), .BminY(BminY),
        .BplusZ(BplusZ), .BminZ(BminZ),
        .omegaPsi(psi2),
        .omegaTheta(th2)
    );

    assign omegaPsi   = (psi0 & psi1) | (psi0 & psi2) | (psi1 & psi2);
    assign omegaTheta = (th0  & th1 ) | (th0  & th2 ) | (th1  & th2 );

    wire diff_psi01 = (psi0 != psi1);
    wire diff_psi02 = (psi0 != psi2);
    wire diff_psi12 = (psi1 != psi2);

    wire diff_th01  = (th0 != th1);
    wire diff_th02  = (th0 != th2);
    wire diff_th12  = (th1 != th2);

    assign tmr_mismatch =
        (diff_psi01 | diff_psi02 | diff_psi12) |
        (diff_th01  | diff_th02  | diff_th12);

    wire uncor_psi = diff_psi01 & diff_psi02 & diff_psi12;
    wire uncor_th  = diff_th01  & diff_th02  & diff_th12;

    assign tmr_uncorrectable = uncor_psi | uncor_th;

endmodule
