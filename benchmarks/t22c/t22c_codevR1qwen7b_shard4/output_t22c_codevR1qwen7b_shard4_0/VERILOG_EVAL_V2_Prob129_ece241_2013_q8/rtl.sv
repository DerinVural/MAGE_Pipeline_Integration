module TopModule (input clk, input aresetn, input x, output logic z); 

    // State definitions
    localparam S0 = 2'b00, S1 = 2'b01, S2 = 2'b10;
    logic [1:0] state, next_state;

    // State register with async reset (active low aresetn)
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) state <= S0;
        else state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (state)
            S0: next_state = x ? S1 : S0;
            S1: next_state = x ? S1 : S2;
            S2: next_state = x ? S1 : S0;
            default: next_state = S0;
        endcase
    end

    // Mealy output
    assign z = (state == S2) & x;

endmodule

// Testbench parts not included as per module_interface given. Only TopModule is needed here.