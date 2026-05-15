module TopModule(
    input logic clk,
    input logic a,
    input logic b,
    input logic sel_b1,
    input logic sel_b2,
    output logic out_assign,
    output logic out_always
);

    logic mux_select;

    assign mux_select = sel_b1 && sel_b2;

    assign out_assign = mux_select ? b : a;

    always @(*) begin
        out_always = mux_select ? b : a;
    end

endmodule