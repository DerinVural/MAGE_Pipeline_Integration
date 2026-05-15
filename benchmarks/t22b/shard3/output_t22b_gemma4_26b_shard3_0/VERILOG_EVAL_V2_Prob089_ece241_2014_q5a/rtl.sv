module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic x,
    output logic z
);

    // State encoding
    localparam logic [1:0] S_ZERO      = 2'b00;
    localparam logic [1:0] S_ONE       = 2'b01;
    localparam logic [1:0] S_INV_ZERO  = 2'b10;
    localparam logic [1:0] S_INV_ONE   = 2'b11;

    logic [1:0] state;
    logic [1:0] state_next;

    // Initialize state to prevent X
    initial begin
        state = S_ZERO;
    end

    // Sequential logic with asynchronous reset
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= S_ZERO;
        end else begin
            state <= state_next;
        end
    end

    // Next state combinational logic
    always @(*) begin
        state_next = state;
        case (state)
            S_ZERO:
                if (x == 1'b1) 
                    state_next = S_ONE;
                else 
                    state_next = S_ZERO;
            
            S_ONE:
                if (x == 1'b1) 
                    state_next = S_INV_ZERO;
                else 
                    state_next = S_INV_ONE;

            S_INV_ZERO:
                if (x == 1'b1) 
                    state_next = S_INV_ZERO;
                else 
                    state_next = S_INV_ONE;

            S_INV_ONE:
                if (x == 1'b1) 
                    state_next = S_INV_ZERO;
                else 
                    state_next = S_INV_ONE;
            
            default:
                state_next = S_ZERO;
        endcase
    end

    // Output combinational logic (Moore Machine: output depends only on state)
    always @(*) begin
        case (state)
            S_ZERO:
                z = 1'b0;
            S_ONE:
                z = 1'b1;
            S_INV_ZERO:
                z = 1'b0;
            S_INV_ONE:
                z = 1'b1;
            default:
                z = 1'b0;
        endcase
    end

endmodule