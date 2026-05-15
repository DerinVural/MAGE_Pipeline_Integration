module TopModule(
    input  logic       clk,
    input  logic [7:0] in,
    output logic [7:0] pedge
);

    // Register to store the previous state of the input
    logic [7:0] prev_in;

    // Initialize prev_in to avoid starting with X
    initial begin
        prev_in = 8'b0;
    end

    // Sequential logic to update the previous state
    always @(posedge clk) begin
        prev_in <= in;
    end

    // Combinational logic to detect 0 -> 1 transition
    // pedge is high when current bit is 1 and previous bit was 0
    assign pedge = in & (~prev_in);

endmodule