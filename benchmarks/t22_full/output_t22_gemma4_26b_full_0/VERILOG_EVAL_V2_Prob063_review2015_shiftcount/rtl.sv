module TopModule(
    input  logic       clk,
    input  logic       shift_ena,
    input  logic       count_ena,
    input  logic       data,
    output logic [3:0] q
);

    // Initialize register to 0 to avoid X in simulation
    initial begin
        q = 4'b0000;
    end

    // Sequential logic for shift register and down counter
    always @(posedge clk) begin
        if (shift_ena) begin
            // Shift in MSB first: 
            // New data goes to q[3], old q[3] to q[2], etc.
            q <= {data, q[3:1]};
        end
        else if (count_ena) begin
            // Decrement the current value
            q <= q - 1'b1;
        end
    end

endmodule