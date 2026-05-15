module TopModule (
    input [15:0] scancode,
    output logic left,
    output logic down,
    output logic right,
    output logic up
);

    always @(*) begin
        case (scancode)
            16'hE06B: begin
                left  = 1'b1;
                down  = 1'b0;
                right = 1'b0;
                up    = 1'b0;
            end
            16'hE072: begin
                left  = 1'b0;
                down  = 1'b1;
                right = 1'b0;
                up    = 1'b0;
            end
            16'hE074: begin
                left  = 1'b0;
                down  = 1'b0;
                right = 1'b1;
                up    = 1'b0;
            end
            16'hE075: begin
                left  = 1'b0;
                down  = 1'b0;
                right = 1'b0;
                up    = 1'b1;
            end
            default: begin
                left  = 1'b0;
                down  = 1'b0;
                right = 1'b0;
                up    = 1'b0;
            end
        endcase
    end

endmodule