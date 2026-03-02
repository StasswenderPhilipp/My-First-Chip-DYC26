module top(
`ifdef USE_POWER_PINS
    inout wire IOVDD,
    inout wire IOVSS,
    inout wire VDD,
    inout wire VSS,
`endif
    inout wire clk_PAD,
    inout wire rst_n_PAD,
    inout wire in_valid_PAD,
    inout wire [7:0] in_data_PADs,
    output wire in_ready_PAD,
    output wire out_valid_PAD,
    inout wire out_ready_PAD,
    output wire [7:0] out_data_PADs
);

    logic clk;
    logic rst_n;

    logic in_valid;
    logic [7:0] in_data;
    logic in_ready;

    logic out_valid;
    logic out_ready;
    logic [7:0] out_data;

    // Power/ground pad instances
    generate
        for (genvar i = 0; i < 1; i++) begin : iovdd_pads
            (* keep *)
            sg13g2_IOPadIOVdd iovdd_pad(
`ifdef USE_POWER_PINS
                .iovdd(IOVDD),
                .iovss(IOVSS),
                .vdd(VDD),
                .vss(VSS)
`endif
            );
        end

        for (genvar i = 0; i < 1; i++) begin : iovss_pads
            (* keep *)
            sg13g2_IOPadIOVss iovss_pad(
`ifdef USE_POWER_PINS
                .iovdd(IOVDD),
                .iovss(IOVSS),
                .vdd(VDD),
                .vss(VSS)
`endif
            );
        end

        for (genvar i = 0; i < 1; i++) begin : vdd_pads
            (* keep *)
            sg13g2_IOPadVdd vdd_pad(
`ifdef USE_POWER_PINS
                .iovdd(IOVDD),
                .iovss(IOVSS),
                .vdd(VDD),
                .vss(VSS)
`endif
            );
        end

        for (genvar i = 0; i < 1; i++) begin : vss_pads
            (* keep *)
            sg13g2_IOPadVss vss_pad(
`ifdef USE_POWER_PINS
                .iovdd(IOVDD),
                .iovss(IOVSS),
                .vdd(VDD),
                .vss(VSS)
`endif
            );
        end
    endgenerate

    // Input pads
    sg13g2_IOPadIn clk_pad(
`ifdef USE_POWER_PINS
        .iovdd(IOVDD),
        .iovss(IOVSS),
        .vdd(VDD),
        .vss(VSS),
`endif
        .p2c(clk),
        .pad(clk_PAD)
    );

    sg13g2_IOPadIn rst_n_pad(
`ifdef USE_POWER_PINS
        .iovdd(IOVDD),
        .iovss(IOVSS),
        .vdd(VDD),
        .vss(VSS),
`endif
        .p2c(rst_n),
        .pad(rst_n_PAD)
    );

    sg13g2_IOPadIn in_valid_pad(
`ifdef USE_POWER_PINS
        .iovdd(IOVDD),
        .iovss(IOVSS),
        .vdd(VDD),
        .vss(VSS),
`endif
        .p2c(in_valid),
        .pad(in_valid_PAD)
    );

    generate
        for (genvar i = 0; i < 8; i++) begin : in_data_pads
            sg13g2_IOPadIn in_data_pad(
`ifdef USE_POWER_PINS
                .iovdd(IOVDD),
                .iovss(IOVSS),
                .vdd(VDD),
                .vss(VSS),
`endif
                .p2c(in_data[i]),
                .pad(in_data_PADs[i])
            );
        end
    endgenerate

    sg13g2_IOPadIn out_ready_pad(
`ifdef USE_POWER_PINS
        .iovdd(IOVDD),
        .iovss(IOVSS),
        .vdd(VDD),
        .vss(VSS),
`endif
        .p2c(out_ready),
        .pad(out_ready_PAD)
    );

    // Output pads
    sg13g2_IOPadOut30mA in_ready_pad(
`ifdef USE_POWER_PINS
        .vss(VSS),
        .vdd(VDD),
        .iovss(IOVSS),
        .iovdd(IOVDD),
`endif
        .c2p(in_ready),
        .pad(in_ready_PAD)
    );

    sg13g2_IOPadOut30mA out_valid_pad(
`ifdef USE_POWER_PINS
        .vss(VSS),
        .vdd(VDD),
        .iovss(IOVSS),
        .iovdd(IOVDD),
`endif
        .c2p(out_valid),
        .pad(out_valid_PAD)
    );

    generate
        for (genvar i = 0; i < 8; i++) begin : out_data_pads
            sg13g2_IOPadOut30mA out_data_pad(
`ifdef USE_POWER_PINS
                .vss(VSS),
                .vdd(VDD),
                .iovss(IOVSS),
                .iovdd(IOVDD),
`endif
                .c2p(out_data[i]),
                .pad(out_data_PADs[i])
            );
        end
    endgenerate

    chip u_chip(
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .in_data(in_data),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .out_data(out_data)
    );

endmodule
