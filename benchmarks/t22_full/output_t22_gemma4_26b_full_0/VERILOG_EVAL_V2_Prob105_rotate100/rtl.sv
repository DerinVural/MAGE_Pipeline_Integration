module TopModule(
    input  logic       clk,
    input  logic       load,
    input  logic [1:0] ena,
    input  logic [99:0] data,
    output logic [99:0] q
);

    // Initialize q to zero to avoid X in simulation
    initial begin
        q = 100'b0;
    end

    // Sequential logic for rotator
    always @(posedge clk) begin
        if (load) begin
            // Synchronous load
            q <= data;
        end else begin
            case (ena)
                2'b01: begin
                    // Rotate Right: bit 0 becomes bit 99, others shift right
                    q <= {q[0], q[99:1]};
                end
                2'b10: begin
                    // Rotate Left: bit 99 becomes bit 0, others shift left
                    q <= {q[98:0], q[99]};
                end
                default: begin
                    // 2'b00 and 2'b11: do nothing
                    q <= q;
                end
            endcase
        end
    end

endmodule