module TopModule (
    input  logic clk,
    input  logic [7:0] in,
    output logic [7:0] pedge
);

    // Internal registers to store the previous input values for edge detection
    logic [7:0] in_prev;

    // Internal signal to hold the detected edge (0->1) in the current cycle
    logic [7:0] edge_detect;

    // 1. Register the input value to track previous state
    always @(posedge clk)
    begin
        in_prev <= in;
    end

    // 2. Combinational logic to detect the positive edge (0 -> 1)
    // Transition occurs when current bit is 1 AND previous bit was 0
    always @(*)
    begin
        edge_detect = in & (~in_prev);
    end

    // 3. Register the edge detection signal to meet the requirement: 
    // The output bit should be set the cycle *after* a 0 to 1 transition occurs.
    // This requires one more pipeline stage (registering the edge_detect signal).
    always @(posedge clk)
    begin
        // The output pedge asserts on the cycle FOLLOWING the detection cycle
        pedge <= edge_detect;
    end

    // Initialization of registers to known values
    initial begin
        in_prev = 8'b0;
        pedge = 8'b0;
    end

endmodule