module tb();
logic a;
logic b;
logic c;
logic d;
logic q_ref;
logic q_dut;
wire tb_match;
wire tb_mismatch;
top_module1 top_module1 (
	.a,
	.b,
	.c,
	.d,
	.q(q_dut) );
RefModule good1 (
	.a,
	.b,
	.c,
	.d,
	.q(q_ref) );
initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, tb_mismatch ,a,b,c,d,q_ref,q_dut );
end
assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
always @(posedge clk, negedge clk) begin
	if (!tb_match) begin
		$display("Mismatch detected at time %t", $time);
		$display("Input: %b, Output: %b, Expected: %b", a, q_dut, q_ref);
	end
end
endmodule