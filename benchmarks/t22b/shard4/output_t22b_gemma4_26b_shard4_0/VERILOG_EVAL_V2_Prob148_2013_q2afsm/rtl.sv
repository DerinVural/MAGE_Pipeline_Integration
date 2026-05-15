module TopModule (
    input  logic        clk,
    input  logic        resetn,
    input  logic [2:0]  r,
    output logic [2:0]  g
);

    // State encoding
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;
    localparam STATE_D = 2'b11;

    // State registers
    logic [1:0] state;
    logic [1:0] state_next;

    // Initialize state to avoid X in simulation
    initial begin
        state = STATE_A;
    end

    // Sequential logic: State Flip-Flops
    always @(posedge clk) begin
        if (!resetn) begin
            state <= STATE_A;
        end else begin
            state <= state_next;
        end
    end

    // Combinational logic: Next State Logic
    always @(*) begin
        state_next = state;
        case (state)
            STATE_A:
                if (r[0])
                    state_next = STATE_B;
                else if (r[1])
                    state_next = STATE_C;
                else if (r[2])
                    state_next = STATE_D;
                else
                    state_next = STATE_A;
            
            STATE_B:
                if (r[0])
                    state_next = STATE_B;
                else
                    state_next = STATE_A;
            
            STATE_C:
                if (r[1])
                    state_next = STATE_C;
                else
                    state_next = STATE_A;
            
            STATE_D:
                if (r[2])
                    state_next = STATE_D;
                else
                    state_next = STATE_A;
            
            default:
                state_next = STATE_A;
        endcase
    end

    // Combinational logic: Output Logic
    always @(*) begin
        g = 3'b000;
        case (state)
            STATE_B:
                g[0] = 1'b1;
            STATE_C:
                g[1] = 1'b1;
            STATE_D:
                g[2] = 1'b1;
            default:
                g = 3'b000;
        endcase
    end

endmodule