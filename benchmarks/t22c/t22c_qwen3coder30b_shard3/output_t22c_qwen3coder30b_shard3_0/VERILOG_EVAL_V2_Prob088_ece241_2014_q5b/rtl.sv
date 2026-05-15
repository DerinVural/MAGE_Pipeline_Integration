module TopModule (
    input clk,
    input areset,
    input x,
    output logic z
);

    // State definitions
    logic state_A;
    logic state_B;
    
    // Next state signals
    logic next_state_A;
    logic next_state_B;
    
    // Sequential logic for state register
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state_A <= 1'b1;
            state_B <= 1'b0;
        end
        else begin
            state_A <= next_state_A;
            state_B <= next_state_B;
        end
    end
    
    // Next state logic
    always @(*) begin
        if (state_A) begin
            // In state A
            if (x) begin
                // x=1, transition to B
                next_state_A = 1'b0;
                next_state_B = 1'b1;
            end
            else begin
                // x=0, stay in A
                next_state_A = 1'b1;
                next_state_B = 1'b0;
            end
        end
        else begin
            // In state B
            if (x) begin
                // x=1, stay in B
                next_state_A = 1'b0;
                next_state_B = 1'b1;
            end
            else begin
                // x=0, stay in B
                next_state_A = 1'b0;
                next_state_B = 1'b1;
            end
        end
    end
    
    // Output logic using continuous assignment
    assign z = state_A ? x : ~x;
    
endmodule