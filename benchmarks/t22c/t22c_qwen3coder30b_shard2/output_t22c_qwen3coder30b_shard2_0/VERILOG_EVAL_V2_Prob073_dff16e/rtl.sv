module TopModule (
    input clk,
    input resetn,
    input [1:0] byteena,
    input [15:0] d,
    output [15:0] q
);

    // Internal 16-bit register to store the data
    logic [15:0] reg_q;

    // Sequential logic for registering the data
    always @(posedge clk) begin
        if (!resetn) begin
            reg_q <= 16'b0;
        end else begin
            // Update upper byte if byteena[1] is high
            if (byteena[1])
                reg_q[15:8] <= d[15:8];
            
            // Update lower byte if byteena[0] is high
            if (byteena[0])
                reg_q[7:0] <= d[7:0];
        end
    end

    // Output assignment
    assign q = reg_q;

endmodule