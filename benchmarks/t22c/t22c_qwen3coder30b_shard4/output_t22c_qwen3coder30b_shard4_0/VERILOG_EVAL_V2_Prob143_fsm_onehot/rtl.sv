module TopModule (
    input  in,
    input  [9:0] state,
    output [9:0] next_state,
    output out1,
    output out2
);

    always @(*) begin
        // Initialize outputs
        next_state = 10'b0;
        out1 = 1'b0;
        out2 = 1'b0;
        
        // Determine next state and outputs based on current state and input
        case (state)
            // S0
            10'b0000000001: begin
                if (in == 1'b0) next_state = 10'b0000000001; // S0 --0--> S0
                else next_state = 10'b0000000010; // S0 --1--> S1
            end
            // S1
            10'b0000000010: begin
                if (in == 1'b0) next_state = 10'b0000000001; // S1 --0--> S0
                else next_state = 10'b0000000100; // S1 --1--> S2
            end
            // S2
            10'b0000000100: begin
                if (in == 1'b0) next_state = 10'b0000000001; // S2 --0--> S0
                else next_state = 10'b0000001000; // S2 --1--> S3
            end
            // S3
            10'b0000001000: begin
                if (in == 1'b0) next_state = 10'b0000000001; // S3 --0--> S0
                else next_state = 10'b0000010000; // S3 --1--> S4
            end
            // S4
            10'b0000010000: begin
                if (in == 1'b0) next_state = 10'b0000000001; // S4 --0--> S0
                else next_state = 10'b0000100000; // S4 --1--> S5
            end
            // S5
            10'b0000100000: begin
                if (in == 1'b0) next_state = 10'b0100000000; // S5 --0--> S8
                else next_state = 10'b0001000000; // S5 --1--> S6
            end
            // S6
            10'b0001000000: begin
                if (in == 1'b0) next_state = 10'b1000000000; // S6 --0--> S9
                else next_state = 10'b0010000000; // S6 --1--> S7
            end
            // S7
            10'b0010000000: begin
                if (in == 1'b0) next_state = 10'b0000000001; // S7 --0--> S0
                else next_state = 10'b0010000000; // S7 --1--> S7
                out1 = 1'b0;
                out2 = 1'b1;
            end
            // S8
            10'b0100000000: begin
                if (in == 1'b0) next_state = 10'b0000000001; // S8 --0--> S0
                else next_state = 10'b0000000010; // S8 --1--> S1
                out1 = 1'b1;
                out2 = 1'b0;
            end
            // S9
            10'b1000000000: begin
                if (in == 1'b0) next_state = 10'b0000000001; // S9 --0--> S0
                else next_state = 10'b0000000010; // S9 --1--> S1
                out1 = 1'b1;
                out2 = 1'b1;
            end
            // Default case: no transition
            default:;
        endcase
    end

endmodule