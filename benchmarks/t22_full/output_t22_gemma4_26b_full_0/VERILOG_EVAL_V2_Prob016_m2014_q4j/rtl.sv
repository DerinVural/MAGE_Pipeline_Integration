module TopModule(
    input  logic [3:0] x,
    input  logic [3:0] y,
    output logic [4:0] sum
);

    logic [4:0] carry;
    integer i;

    always @(*) begin
        // Initialize carry[0] to 0
        carry[0] = 1'b0;
        
        // Calculate each bit of the sum and the carry chain
        for (i = 0; i < 4; i = i + 1) begin
            sum[i] = x[i] ^ y[i] ^ carry[i];
            carry[i+1] = (x[i] & y[i]) | (carry[i] & (x[i] ^ y[i]));
        end
        
        // The overflow/carry-out bit is the 5th bit of the sum
        sum[4] = carry[4];
    end

endmodule