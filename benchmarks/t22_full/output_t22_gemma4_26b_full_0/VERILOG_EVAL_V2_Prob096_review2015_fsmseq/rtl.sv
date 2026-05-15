module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic data,
    output logic start_shifting
);

    // State encoding
    localparam logic [2:0] S_IDLE   = 3'b000;
    localparam logic [2:0] S_1     = 3'b001;
    localparam logic [2:0] S_11    = 3'b010;
    localparam logic [2:0] S_110   = 3'b011;
    localparam logic [2:0] S_FOUND = 3'b100;

    // State registers
    logic [2:0] current_state;
    logic [2:0] next_state;

    // Sequential logic for state transition
    always @(posedge clk) begin
        if (reset) begin
            current_state <= S_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        next_state = current_state;
        case (current_state)
            S_IDLE:
                if (data == 1'b1) 
                    next_state = S_1;
                else 
                    next_state = S_IDLE;
            
            S_1:
                if (data == 1'b1) 
                    next_state = S_11;
                else 
                    next_state = S_IDLE;
            
            S_11:
                if (data == 1'b0) 
                    next_state = S_110;
                else 
                    next_state = S_11;
            
            S_110:
                if (data == 1'b1) 
                    next_state = S_FOUND;
                else 
                    next_state = S_IDLE;
            
            S_FOUND:
                next_state = S_FOUND;
            
            default:
                next_state = S_IDLE;
        endcase
    end

    // Output logic
    always @(*) begin
        if (current_state == S_FOUND) begin
            start_shifting = 1'b1;
        end else begin
            start_shifting = 1'b0;
        end
    end

endmodule