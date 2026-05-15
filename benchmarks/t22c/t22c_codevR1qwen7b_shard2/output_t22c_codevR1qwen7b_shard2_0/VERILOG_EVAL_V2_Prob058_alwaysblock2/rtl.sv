module TopModule (clk, a, b, out_assign, out_always_comb, out_always_ff);
input clk;
input a;
input b;
output logic out_assign;
output logic out_always_comb;
output logic out_always_ff;

// Combinational XOR using assign
assign out_assign = a ^ b;

// Combinational XOR using always block
always @(*) begin
    out_always_comb = a ^ b;
end

// Sequential XOR (flip-flop), initialized to 0 and updated on clock edge
initial begin
    out_always_ff = 0;
end

always @(posedge clk) begin
    out_always_ff <= a ^ b;
end

endmodule