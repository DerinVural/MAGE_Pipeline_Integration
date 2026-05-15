module TopModule (
    input clk,
    input aresetn,
    input x,
    output logic z
);

    // Define states
    localparam S0 = 2'b00;
    localparam S1 = 2'b01;
    localparam S2 = 2'b10;

    // Current and next state signals
    logic [1:0] state, next_state;

    // Combinational logic for next state
    always @(*) begin
        case (state)
            S0: begin
                if (x) next_state = S1;
                else next_state = S0;
            end
            S1: begin
                if (x) next_state = S1;
                else next_state = S2;
            end
            S2: begin
                if (x) next_state = S1;
                else next_state = S0;
            end
            default: next_state = S0;
        endcase
    end

    // Mealy output logic
    assign z = (state == S2 && x == 1'b1) ? 1'b1 : 1'b0;

    // Sequential logic for state register
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn)
            state <= S0;
        else
            state <= next_state;
    end

endmodule