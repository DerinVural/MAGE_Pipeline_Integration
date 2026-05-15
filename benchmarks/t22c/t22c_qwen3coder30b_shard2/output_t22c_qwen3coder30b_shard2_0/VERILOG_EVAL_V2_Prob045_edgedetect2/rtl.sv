module TopModule (
    input clk,
    input [7:0] in,
    output logic [7:0] anyedge
);

    // Register to store previous input values
    logic [7:0] prev_in;
    
    // Edge detection signal
    logic [7:0] edges;
    
    // Sequential logic to store previous input
    always @(posedge clk) begin
        prev_in <= in;
    end

    // Combinational logic to detect edges
    always @(*) begin
        edges = in ^ prev_in;
    end

    // Output is asserted one cycle after edge is detected
    always @(posedge clk) begin
        anyedge <= edges;
    end

endmodule