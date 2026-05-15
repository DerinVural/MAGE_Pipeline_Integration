module TopModule (
    input  logic clk,
    input  logic reset,
    output logic shift_ena
);

    // State Encoding (5 states: 0 to 4, requires 3 bits)
    localparam STATE_IDLE = 3'b000;
    localparam STATE_ENABLE_1 = 3'b001;
    localparam STATE_ENABLE_2 = 3'b010;
    localparam STATE_ENABLE_3 = 3'b011;
    localparam STATE_ENABLE_4 = 3'b100;

    // State registers
    logic [2:0] state;
    logic [2:0] state_next;

    // Initialize state to Idle upon simulation start (Requirement 3)
    initial begin
        state = STATE_IDLE;
    end

    // 1. Sequential Logic: State Register Update
    always @(posedge clk)
    begin
        if (reset)
        begin
            // Synchronous reset forces the start of the 4-cycle sequence
            state <= STATE_ENABLE_1;
        end
        else
        begin
            state <= state_next;
        end
    end

    // 2. Combinational Logic: Next State Determination
    always @(*)
    begin
        state_next = state;

        if (reset)
        begin
            // Reset logic handled in the sequential block, but good practice to cover here
            state_next = STATE_ENABLE_1;
        end
        else begin
            case (state)
                STATE_IDLE: 
                    // Remain idle if reset is low
                    state_next = STATE_IDLE;
                STATE_ENABLE_1: 
                    state_next = STATE_ENABLE_2;
                STATE_ENABLE_2: 
                    state_next = STATE_ENABLE_3;
                STATE_ENABLE_3: 
                    state_next = STATE_ENABLE_4;
                STATE_ENABLE_4: 
                    // After 4 cycles, return to idle state
                    state_next = STATE_IDLE;
                default: 
                    state_next = STATE_IDLE;
            endcase
        end
    end

    // 3. Output Logic: Determine shift_ena
    // shift_ena is asserted for 4 cycles (States 1, 2, 3, 4)
    assign shift_ena = (state == STATE_ENABLE_1) || 
                       (state == STATE_ENABLE_2) || 
                       (state == STATE_ENABLE_3) || 
                       (state == STATE_ENABLE_4);

endmodule