module TopModule (
    input clk,
    input load,
    input [1:0] ena,
    input [99:0] data,
    output [99:0] q
);

    logic [99:0] reg_q;

    always @(posedge clk) begin
        if (load) begin
            reg_q <= data;
        end else begin
            case (ena)
                2'b01: begin // Right rotate
                    reg_q <= {reg_q[0], reg_q[99:1]};
                end
                2'b10: begin // Left rotate
                    reg_q <= {reg_q[98:0], reg_q[99]};
                end
                default: begin // No rotation
                    // Do nothing, keep current value
                end
            endcase
        end
    end

    assign q = reg_q;

endmodule