module TopModule(clk, enable, S, A, B, C, Z);
    input clk;
    input enable;
    input S;
    input A;
    input B;
    input C;
    output logic Z;

    // 8-bit shift register
    logic [7:0] Q;

    // Shift register logic
    always @(posedge clk) begin
        if (enable) begin
            Q <= {Q[6:0], S}; // Shift left, S enters at LSB (Q[0] becomes new S, Q[1] shifts left...)
        end else begin
            Q <= Q; // Optional, can be omitted as it's the default
        end
    end

    // Combinational logic for mux
    always @(*) begin
        case({A, B, C})
            3'b000: Z = Q[0];
            3'b001: Z = Q[1];
            3'b010: Z = Q[2];
            3'b011: Z = Q[3];
            3'b100: Z = Q[4];
            3'b101: Z = Q[5];
            3'b110: Z = Q[6];
            3'b111: Z = Q[7];
            default: Z = 0; // Default case to avoid latch
        endcase
    end

endmodule