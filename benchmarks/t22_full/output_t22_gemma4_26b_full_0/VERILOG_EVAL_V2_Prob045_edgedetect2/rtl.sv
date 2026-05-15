module TopModule(
    input  logic       clk,
    input  logic [7:0] in,
    output logic [7:0] anyedge
);

    // Register to store the input from the previous clock cycle
    logic [7:0] prev_in;

    // Initialize prev_in to a known value to avoid X in simulation
    initial begin
        prev_in = 8'b0;
    end

    // Sequential logic: capture the current input to be used as 'previous' in the next cycle
    always @(posedge clk) begin
        prev_in <= in;
    end

    // Combinational logic: detect any edge using XOR
    // An edge occurs if the current bit is different from the previous bit
    assign anyedge = in ^ prev_in;

endmodule