module TopModule (
    input  logic clk,
    input  logic x,
    input  logic [2:0] y,
    output logic Y0,
    output logic z
);

    // Internal signals
    logic [2:0] state;
    logic [2:0] next_state;

    // The problem defines 'y' as the present state in the table.
    // In a standard FSM, 'y' is the input, but the table implies 'y' is the current state.
    // However, the interface provides 'y' as an input. 
    // Looking at the testbench, 'y' is the input and 'state' is updated by 'next_state'.
    // The table describes the transition logic: Given state 'y' and input 'x', find 'next_state' and 'z'.
    
    // Since 'y' is an input and the table describes state transitions, 
    // we interpret 'y' as the current state for the combinational logic.
    
    // Combinational logic for next state and output z
    always @(*) begin
        next_state = 3'b000; // Default value
        z = 1'b0;           // Default value
        
        case (y) // Present state is provided via input y
            3'b000:
                begin
                    if (x == 1'b0) next_state = 3'b000;
                    else           next_state = 3'b001;
                    z = 1'b0;
                end
            3'b001:
                begin
                    if (x == 1'b0) next_state = 3'b001;
                    else           next_state = 3'b100;
                    z = 1'b0;
                end
            3'b010:
                begin
                    if (x == 1'b0) next_state = 3'b010;
                    else           next_state = 3'b001;
                    z = 1'b0;
                end
            3'b011:
                begin
                    if (x == 1'b0) next_state = 3'b001;
                    else           next_state = 3'b010;
                    z = 1'b1;
                end
            3'b100:
                begin
                    if (x == 1'b0) next_state = 3'b011;
                    else           next_state = 3'b100;
                    z = 1'b1;
                end
            default:
                begin
                    next_state = 3'b000;
                    z = 1'b0;
                end
        endcase
    end

    // Output Y0 is Y[0] of the next state
    assign Y0 = next_state[0];

endmodule