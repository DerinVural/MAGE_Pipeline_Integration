module TopModule (input in, input [3:0] state, output logic [3:0] next_state, output logic out);

localparam [3:0] STATE_A = 4'b0001;
localparam [3:0] STATE_B = 4'b0010;
localparam [3:0] STATE_C = 4'b0100;
localparam [3:0] STATE_D = 4'b1000;

// Combinational logic for next state and output
always @(*) begin
    case (state)
        STATE_A: begin
            next_state = (in == 0) ? STATE_A : STATE_B;
            out = 0;
        end
        STATE_B: begin
            next_state = (in == 0) ? STATE_C : STATE_B;
            out = 0;
        end
        STATE_C: begin
            next_state = (in == 0) ? STATE_D : STATE_C;
            out = 0;
        end
        STATE_D: begin
            next_state = (in == 0) ? STATE_C : STATE_B;
            out = 1;
        end
        default: begin
            next_state = STATE_A; // Handle undefined states by resetting to A
            out = 0;
        end
    endcase
end

endmodule