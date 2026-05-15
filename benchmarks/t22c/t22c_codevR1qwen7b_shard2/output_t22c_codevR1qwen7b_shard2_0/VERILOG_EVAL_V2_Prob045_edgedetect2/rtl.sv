module TopModule (input logic clk, input logic [7:0] in, output logic [7:0] anyedge);

    // Registers to store previous values
    logic [7:0] in1, in2;

    // Sequential logic to update registers on clock edge
    always @(posedge clk) begin
        in1 <= in;
        in2 <= in1;
    end

    // Combinational logic to detect any edge (change between current and previous clock cycle)
    assign anyedge = in ^ in1;

endmodule