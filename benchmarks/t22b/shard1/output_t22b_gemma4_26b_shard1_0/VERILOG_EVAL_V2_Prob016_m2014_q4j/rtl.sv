module TopModule (
    input  logic [3:0] x,
    input  logic [3:0] y,
    output logic [4:0] sum
);

    logic [4:0] carry;
    logic [3:0] s_bits;

    // Initialize carry bits
    assign carry[0] = 1'b0;

    // Ripple Carry Adder logic
    // Bit 0
    always @(*) begin
        s_bits[0] = x[0] ^ y[0] ^ carry[0];
        carry[1]   = (x[0] & y[0]) | (x[0] & carry[0]) | (y[0] & carry[0]);
    end

    // Bit 1
    always @(*) begin
        s_bits[1] = x[1] ^ y[1] ^ carry[1];
        carry[2]   = (x[1] & y[1]) | (x[1] & carry[1]) | (y[1] & carry[1]);
    end

    // Bit 2
    always @(*) begin
        s_bits[2] = x[2] ^ y[2] ^ carry[2];
        carry[3]   = (x[2] & y[2]) | (x[2] & carry[2]) | (y[2] & carry[2]);
    end

    // Bit 3
    always @(*) begin
        s_bits[3] = x[3] ^ y[3] ^ carry[3];
        carry[4]   = (x[3] & y[3]) | (x[3] & carry[3]) | (y[3] & carry[3]);
    end

    // Combine the bits into the 5-bit output
    // sum[4] is the final carry (overflow), sum[3:0] is the sum bits
    assign sum = {carry[4], s_bits};

endmodule