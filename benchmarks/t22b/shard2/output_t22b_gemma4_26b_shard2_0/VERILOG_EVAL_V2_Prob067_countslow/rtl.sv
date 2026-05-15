module TopModule (
    input  logic       clk,
    input  logic       reset,
    input  logic       slowena,
    output logic [3:0] q
);

    // Internal counter register
    logic [3:0] count;

    // Initialize counter to avoid X in simulation
    initial begin
        count = 4'd0;
    end

    // Sequential logic for the decade counter
    always @(posedge clk) begin
        if (reset) begin
            // Synchronous reset to 0
            count <= 4'd0;
        end else if (slowena) begin
            // Increment logic with wrap-around at 9
            if (count >= 4'd9) begin
                count <= 4'd0;
            end else begin
                count <= count + 4'd1;
            end
        end
        // If slowena is low, count remains the same (implicit latch-free behavior)
    end

    // Combinational logic to drive output
    always @(*) begin
        q = count;
    end

endmodule