module TopModule (
    input  logic [7:0] in,
    output logic [2:0] pos
);

logic [2:0] i;
logic [2:0] pos_reg;
logic found_set_bit;

initial begin
    pos_reg = 7;
    found_set_bit = 0;
end

always @(*) begin
    pos_reg = 7;
    found_set_bit = 0;
    for (i = 0; i < 8; i++) begin
        if (in[i]) begin
            pos_reg = i;
            found_set_bit = 1;
        end
    end
end

assign pos = (found_set_bit) ? pos_reg : 7;

endmodule