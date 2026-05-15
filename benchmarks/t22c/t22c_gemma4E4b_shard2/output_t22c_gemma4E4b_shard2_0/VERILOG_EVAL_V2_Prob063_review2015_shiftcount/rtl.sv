module TopModule (
    input  logic clk,
    input  logic shift_ena,
    input  logic count_ena,
    input  logic data,
    output logic [3:0] q
);

    // Internal register to hold the state (the 4-bit shift register)
    logic [3:0] q_reg;

    // Initialize the register to a known state (e.g., all zeros) since no reset is specified
    initial begin
        q_reg = 4'b0000;
    end

    // Sequential logic clocked on the positive edge of clk
    always @(posedge clk) begin
        if (shift_ena) begin
            // Shift operation: Data enters MSB (bit 3), existing bits shift down.
            // q_reg = {data, q_reg[3:1]}; 
            // Wait, if data is the new MSB, the old MSB (q_reg[3]) is pushed out.
            // Example: {q3, q2, q1, q0} -> new MSB is data -> {data, q3, q2, q1}
            q_reg <= {data, q_reg[3:1]};
        end else if (count_ena) begin
            // Count operation: Decrement by one
            q_reg <= q_reg - 1'b1;
        end else begin
            // Hold state
            q_reg <= q_reg;
        end
    end

    // Assign the internal register value to the output port
    assign q = q_reg;

endmodule