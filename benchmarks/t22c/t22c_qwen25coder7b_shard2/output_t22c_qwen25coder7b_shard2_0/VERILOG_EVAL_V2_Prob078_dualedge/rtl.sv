module TopModule (
    input logic clk,
    input logic d,
    output logic q
);

    // Registers to store the previous clock values
    logic q_prev;
    logic q_curr;

    // Reset handling
    initial begin
        q_prev = 0;
        q_curr = 0;
    end

    // Sequential logic to handle dual-edge triggering
    always @(posedge clk or negedge clk) begin
        if (clk) begin
            // Rising edge handling
            q_curr = d;
            q_prev = d;
        end else begin
            // Falling edge handling
            q_curr = q_prev;
        end
    end

    // Assign the current value to the output
    assign q = q_curr;

endmodule