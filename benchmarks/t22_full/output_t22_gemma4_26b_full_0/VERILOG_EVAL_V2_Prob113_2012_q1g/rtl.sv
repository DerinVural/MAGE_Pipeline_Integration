module TopModule(
    input  logic [3:0] x,
    output logic f
);

    always @(*) begin
        case (x) 
            // Mapping: x[3]x[2] are rows, x[1]x[0] are columns
            // x[3]x[2] x[1]x[0] | f
            4'b00_00: f = 1'b1;
            4'b00_01: f = 1'b0;
            4'b00_11: f = 1'b0;
            4'b00_10: f = 1'b1;
            
            4'b01_00: f = 1'b0;
            4'b01_01: f = 1'b0;
            4'b01_11: f = 1'b0;
            4'b01_10: f = 1'b0;
            
            4'b11_00: f = 1'b1;
            4'b11_01: f = 1'b1;
            4'b11_11: f = 1'b1;
            4'b11_10: f = 1'b0;
            
            4'b10_00: f = 1'b1;
            4'b10_01: f = 1'b1;
            4'b10_11: f = 1'b0;
            4'b10_10: f = 1'b1;
            
            default: f = 1'b0;
        endcase
    end

endmodule