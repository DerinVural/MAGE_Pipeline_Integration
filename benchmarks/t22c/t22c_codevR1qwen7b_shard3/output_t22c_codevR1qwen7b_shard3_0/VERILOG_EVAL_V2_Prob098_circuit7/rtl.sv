module TopModule (input clk, input a, output q);
    logic prev_a;
    logic current_state;
    // State definitions
    localparam S0 = 0, S1 = 1;

    // Initialize state and previous a
    initial begin
        prev_a = 0;
        current_state = S0;
    end

    // State transition and previous a update
    always @(posedge clk) begin
        prev_a <= a;
        case (current_state)
            S0: if (a) current_state <= S1; else current_state <= S0;
            S1: if (a) current_state <= S1; else current_state <= S0;
        endcase
    end

    // Output logic: q is 1 when both previous and current a are 1
    assign q = (prev_a & a);
endmodule