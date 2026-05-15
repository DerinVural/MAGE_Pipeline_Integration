module TopModule (
    input  logic       clk,
    input  logic [7:0] in,
    output logic [7:0] pedge
);

    // Register to store the delayed input signal
    logic [7:0] in_d1;

    // Initialize register to avoid unknown state in simulation
    initial begin
        in_d1 = 8'b0;
    end

    // Sequential logic: Delay the input by one clock cycle
    always @(posedge clk) begin
        in_d1 <= in;
    end

    // Combinational logic: Detect 0 to 1 transition
    // pedge is 1 where current bit is 1 and previous bit was 0
    always @(*) begin
        pedge = in & ~in_d1;
    end

endmodule