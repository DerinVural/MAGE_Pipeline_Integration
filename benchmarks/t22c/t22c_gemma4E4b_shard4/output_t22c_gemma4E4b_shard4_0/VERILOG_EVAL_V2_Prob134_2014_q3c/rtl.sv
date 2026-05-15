module TopModule (
    input  logic clk,
    input  logic x,
    input  logic [2:0] y,
    output logic Y0,
    output logic z
);

    // State variables
    logic [2:0] current_state;
    logic [2:0] next_state;

    // Internal wires for next state logic
    logic next_Y0_wire;

    // Initialization: Initialize state to 000 (as no reset is specified)
    initial begin
        current_state = 3'b000;
    end

    // 1. Next State Logic and Output Z Logic (Combinational)
    always @(*)
    begin
        next_state = current_state;
        z = 1'b0;
        next_Y0_wire = current_state[0]; // Default Y0 to current state's LSB if not specified

        case (current_state) 
            3'b000: begin
                if (x == 0) next_state = 3'b000; else next_state = 3'b001;
                z = 1'b0;
            end
            3'b001: begin
                if (x == 0) next_state = 3'b001; else next_state = 3'b100;
                z = 1'b0;
            end
            3'b010: begin
                if (x == 0) next_state = 3'b010; else next_state = 3'b001;
                z = 1'b0;
            end
            3'b011: begin
                if (x == 0) next_state = 3'b001; else next_state = 3'b010;
                z = 1'b1;
            end
            3'b100: begin
                if (x == 0) next_state = 3'b011; else next_state = 3'b100;
                z = 1'b1;
            end
            // Default/Unspecified states: Hold state (safe default for synthesis)
            default: begin
                next_state = current_state; 
                z = 1'b0; // Default Z for undefined states
            end
        endcase
    end

    // 2. State Register Update (Sequential)
    always @(posedge clk)
    begin
        current_state <= next_state;
    end

    // 3. Output Assignments
    // Y0 is the LSB of the next state signal Y[2:0]
    assign Y0 = next_state[0];
    
endmodule