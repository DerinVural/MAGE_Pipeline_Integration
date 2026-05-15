`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Assuming RefModule and stimulus_gen are defined elsewhere or kept as is.
// Keeping stimulus_gen as provided in the golden testbench for functional fidelity.
module stimulus_gen (
	input clk,
	output reg [15:0] d, output reg [1:0] byteena,
	output reg resetn,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	input tb_match
);
	reg reset;
	assign resetn = ~reset;

// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	

	task reset_test(input async=0);
		bit arfail, srfail, datafail;
		
		@(posedge clk);
		@(posedge clk) reset <= 0;
		repeat(3) @(posedge clk);
		
		@(negedge clk) begin datafail = !tb_match ; reset <= 1; end
		@(posedge clk) arfail = !tb_match;
		@(posedge clk) begin
		srfail = !tb_match;
		reset <= 0;
		end
		if (srfail)
			s$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
			s$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
		// Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
		// a functionality error than the reset being implemented asynchronously.
		endtask

	
	initial begin
		reset <= 1;
		byteena <= 2'b11;
		d <= 16'habcd;
		@(posedge clk);
		wavedrom_start("Synchronous active-low reset");
		reset_test(0);
		repeat(2) @(posedge clk);
		wavedrom_stop();
		@(posedge clk);
		
		
		byteena <= 2'b11;
		d <= $random;
		@(posedge clk);
		@(negedge clk);
		wavedrom_start("DFF with byte enables");
		repeat(10) @(posedge clk) begin
		d <= $random;
		byteena <= byteena + 1;
		end
		wavedrom_stop();
		
		repeat(400) @(posedge clk, negedge clk) begin
		byteena[0] <= ($random & 3) != 0;
		byteena[1] <= ($random & 3) != 0;
		d <= $random;
		end
		#1 $finish;
	end
	endmodule

// Placeholder for RefModule, assuming it exists and has the necessary interface
module RefModule (
    input clk,
    input resetn,
    input [1:0] byteena,
    input [15:0] d,
    output logic [15:0] q
);
    // Dummy implementation for compilation
    assign q = d;
endmodule

// DUT Module as per specification
module TopModule (
    input clk,
    input resetn,
    input [1:0] byteena,
    input [15:0] d,
    output logic [15:0] q
);
	reg [15:0] registers [0:15];

	always @(posedge clk)
	begin
		restn <= 1'b0;
	if (!resetn) begin
		for (int i = 0; i < 16; i++) begin
			registers[i] <= 16'h0000;
		end
	end
	else begin
		// Byte enable logic
		if (byteena[1]) begin // Upper byte enable
			registers[0] <= {d[15:8], registers[0][7:0]};
			registers[1] <= {d[15:8], registers[1][7:0]};
			// ... and so on for all 16 registers using the upper byte
			// Simplified for demonstration, assuming the intent is to load d[15:8] into high bytes.
			// Since the spec implies 16 DFFs and byteena controls *which byte* of the 16 registers is written,
			// we interpret this as controlling the upper/lower byte of *all* 16 registers simultaneously based on the input D.
			// For strict compliance with the DFF count and byte enable usage:
			// We assume the 16 DFFs are conceptually grouped into 8 high-byte registers and 8 low-byte registers.
			// Given the simplicity of the input structure, we will implement the write logic to reflect byte enabling on the output Q.
			// Since Q is 16 bits, it likely represents one register value.
			// Reinterpreting: Q is the output of a single register set, controlled by byteena.
			
			// If Q represents one 16-bit register (DFFs 0-15), then byteena[1] controls d[15:8] write, byteena[0] controls d[7:0] write.
			// This implies we are writing to a single 16-bit register.
			registers[0] <= (byteena[1] ? {d[15:8], registers[0][7:0]} : registers[0])
			             | (byteena[0] ? {registers[0][15:8], d[7:0]} : registers[0]);
			
		// Since the spec says 