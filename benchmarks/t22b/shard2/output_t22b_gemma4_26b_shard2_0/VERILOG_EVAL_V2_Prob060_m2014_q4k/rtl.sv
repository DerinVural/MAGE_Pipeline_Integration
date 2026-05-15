module TopModule (
    input  logic clk,
    input  logic resetn,
    input  logic in,
    output logic out
);

    // Internal registers for the 4-stage shift register
    logic q1;
    logic q2;
    logic q3;
    logic q4;

    // Initialize registers to a known value to avoid X in simulation
    initial begin
        q1 = 1'b0;
        q2 = 1'b0;
        q3 = 1'b0;
        q4 = 1'b0;
    end

    // Sequential logic: 4-stage shift register with synchronous active-low reset
    always @(posedge clk) begin
        if (!resetn) begin
            q1 <= 1'b0;
            q2 <= 1'b0;
            q3 <= 1'b0;
            q4 <= 1'b0;
        end else begin
            q1 <= in;
            q2 <= q1;
            q3 <= q2;
            q4 <= q3;
        end
    end

    // Output assignment
    assign out = q4;

endmodule