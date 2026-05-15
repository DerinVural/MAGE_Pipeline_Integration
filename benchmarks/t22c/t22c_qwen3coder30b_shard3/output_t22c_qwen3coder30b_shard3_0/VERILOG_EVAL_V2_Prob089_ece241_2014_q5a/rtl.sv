module TopModule(
    input logic clk,
    input logic areset,
    input logic x,
    output logic z
);

    // Define states for the Moore FSM
    localparam IDLE   = 2'b00;
    localparam PROCESS = 2'b01;
    localparam OUTPUT = 2'b10;
    
    // Current and next state registers
    logic [1:0] state, next_state;
    
    // Register to store the result
    logic result;
    
    // Sequential logic for state and result
    always @(posedge clk or posedge areset) begin
        if (areset)
            state <= IDLE;
        else
            state <= next_state;
        
        if (areset)
            result <= 1'b0;
        else if (state == PROCESS && x == 1'b1)
            result <= 1'b1;
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (x == 1'b1)
                    next_state = PROCESS;
                else
                    next_state = IDLE;
            end
            PROCESS: begin
                if (x == 1'b1)
                    next_state = PROCESS;
                else
                    next_state = OUTPUT;
            end
            OUTPUT: begin
                next_state = IDLE;
            end
            default:
                next_state = IDLE;
        endcase
    end
    
    // Output logic for the Moore machine
    always @(*) begin
        case (state)
            IDLE: z = 1'b0;
            PROCESS: z = 1'b0;
            OUTPUT: z = result;
            default: z = 1'b0;
        endcase
    end
    
endmodule