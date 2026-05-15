module TopModule (
    input [2:0] vec,
    output [2:0] outv,
    output o2,
    output o1,
    output o0
);
    logic [2:0] outv_reg;
    logic o2_reg;
    logic o1_reg;
    logic o0_reg;

    always @(*) begin
        outv_reg = vec;
        o2_reg = vec[2];
        o1_reg = vec[1];
        o0_reg = vec[0];
    end

    assign outv = outv_reg;
    assign o2 = o2_reg;
    assign o1 = o1_reg;
    assign o0 = o0_reg;
endmodule