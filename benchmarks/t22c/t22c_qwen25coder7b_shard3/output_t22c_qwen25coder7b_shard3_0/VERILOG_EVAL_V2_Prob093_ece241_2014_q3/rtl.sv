module TopModule (
    input  logic  c,
    input  logic  d,
    output logic [3:0] mux_in
);

    logic [1:0] mux_in_0;
    logic [1:0] mux_in_1;

    assign mux_in_0 = 2'b00;
    assign mux_in_1 = 2'b11;

    assign mux_in[0] = c ? mux_in_1[0] : mux_in_0[0];
    assign mux_in[1] = c ? mux_in_1[1] : mux_in_0[1];
    assign mux_in[2] = c ? mux_in_1[1] : mux_in_0[1];
    assign mux_in[3] = c ? mux_in_1[1] : mux_in_0[1];

endmodule