module TopModule(
    input  logic clk,
    input  logic resetn,
    input  logic in,
    output logic out
);

    // Internal registers for the four D-flip-flops
    logic q0;
    logic q1;
    logic q2;
    logic q3;

    // Sequential logic: 4-stage shift register
    always @(posedge clk) begin
        if (!resetn) begin
            // Synchronous active-low reset
            q0 <= 1'b0;
            q1 <= 1'b0;
            q2 <= 1'b0;
            q3 <= 1'b0;
        end else begin
            // Shift operation
            q0 <= in;
            q1 <= q0;
            q2 <= q1;
            q3 <= q2;
        end
    end

    // Output assignment
    assign out = q3;

endmodule