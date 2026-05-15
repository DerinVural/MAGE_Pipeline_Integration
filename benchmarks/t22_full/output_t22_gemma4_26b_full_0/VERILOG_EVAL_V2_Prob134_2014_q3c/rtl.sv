module TopModule(
    input  logic       clk,
    input  logic       x,
    input  logic [2:0] y,
    output logic       Y0,
    output logic       z
);

    // The input 'y' is described as the present state in the table description.
    // However, the interface has 'y' as an input and the FSM needs to transition.
    // Usually, an FSM has an internal state register. 
    // Given the table structure, 'y' in the table is the current state.
    // The prompt says: 'The module should implement the output logic and next state logic for an FSM'.
    // Since 'y' is an input, it represents the current state being fed into the logic.
    // But a standard FSM has a state register. 
    // Let's look at the interface: input y (3 bits). 
    // This implies 'y' is the current state.
    // If 'y' is an input, the FSM logic is essentially a combinational block that calculates 
    // the next state based on 'y' and 'x'.
    // But 'next state logic' for an FSM usually implies a register.
    // Let's assume 'y' is the current state input, and we must output Y0 (the LSB of the next state) and z.
    // Wait, if 'y' is an input, where does the state update? 
    // If the module is an FSM, it should probably have an internal state register, 
    // but the interface provided is fixed. 
    // Let's re-read: 'input y (3 bits)'. If 'y' is the present state, the FSM logic is 
    // combinational: input (x, y) -> output (next_state_lsb, z).
    // However, 'next state logic' for an FSM usually implies a sequential element.
    // Let's look at the table again. It maps (Present state, x) -> (Next state, z).
    // If 'y' is the present state input, then Y0 is the LSB of the next state calculated from 'y' and 'x'.

    logic [2:0] next_state;

    // Combinational logic for Next State and Output z
    always @(*) begin
        next_state = y; // Default
        z = 1'b0;
        
        case (y) 
            3'b000: begin
                if (x == 1'b0) next_state = 3'b000;
                else           next_state = 3'b001;
            end
            3'b001: begin
                if (x == 1'b0) next_state = 3'b001;
                else           next_state = 3'b100;
            end
            3'b010: begin
                if (x == 1'b0) next_state = 3'b010;
                else           next_state = 3'b001;
            end
            3'b011: begin
                next_state = (x == 1'b0) ? 3'b001 : 3'b010;
                z = 1'b1;
            end
            3'b100: begin
                next_state = (x == 1'b0) ? 3'b011 : 3'b100;
                z = 1'b1;
            end
            default: begin
                next_state = y;
                z = 1'b0;
            end
        endcase
    end

    // The specification says: "The module should implement the output logic and next state logic for an FSM".
    // It also says: "Note that the output Y0 is Y[0] of the next state signal".
    // Since 'y' is an input, we treat it as the present state.
    // To make it an actual FSM, there would usually be a register, but the interface 
    // dictates 'y' is an input. In many hardware description tasks, 
    // if the state is an input, we are designing the logic that computes the next state.
    
    assign Y0 = next_state[0];

endmodule