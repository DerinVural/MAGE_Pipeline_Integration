module TopModule (
    input  logic       clk,
    input  logic       shift_ena,
    input  logic       count_ena,
    input  logic       data,
    output logic [3:0] q
);

    // Initialize the register to a known value to avoid 'X' in simulation
    initial begin
        q = 4'b0000;
    end

    // Sequential logic for shift register and down counter
    always @(posedge clk) begin
        if (shift_ena) begin
            // Shift in data MSB first
            // data becomes q[3], q[3] becomes q[2], q[2] becomes q[1], q[1] becomes q[0]
            q <= {data, q[3:1]};
        end
        else if (count_ena) begin
            // Decrement the value
            q <= q - 1'b1;
        end
    end

endmodule