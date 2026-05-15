module TopModule (
    input  d,
    input  done_counting,
    input  ack,
    input  [9:0] state,
    output B3_next,
    output S_next,
    output S1_next,
    output Count_next,
    output Wait_next,
    output done,
    output counting,
    output shift_ena
);

    // Define state constants in one-hot encoding
    localparam S     = 10'b0000000001;
    localparam S1    = 10'b0000000010;
    localparam S11   = 10'b0000000100;
    localparam S110  = 10'b0000001000;
    localparam B0    = 10'b0000010000;
    localparam B1    = 10'b0000100000;
    localparam B2    = 10'b0001000000;
    localparam B3    = 10'b0010000000;
    localparam Count = 10'b0100000000;
    localparam Wait  = 10'b1000000000;

    // Next state signals
    logic B3_next_logic;
    logic S_next_logic;
    logic S1_next_logic;
    logic S11_next_logic;
    logic S110_next_logic;
    logic B0_next_logic;
    logic B1_next_logic;
    logic B2_next_logic;
    logic Count_next_logic;
    logic Wait_next_logic;

    // Output signals
    logic done_logic;
    logic counting_logic;
    logic shift_ena_logic;

    // Combinational logic for next states
    always @(*) begin
        // Initialize all next state signals to 0
        B3_next_logic = 1'b0;
        S_next_logic = 1'b0;
        S1_next_logic = 1'b0;
        S11_next_logic = 1'b0;
        S110_next_logic = 1'b0;
        B0_next_logic = 1'b0;
        B1_next_logic = 1'b0;
        B2_next_logic = 1'b0;
        Count_next_logic = 1'b0;
        Wait_next_logic = 1'b0;

        // Determine next state based on current state and inputs
        case (state)
            S: begin
                if (d == 1'b0) begin
                    S_next_logic = 1'b1;
                end else begin
                    S1_next_logic = 1'b1;
                end
            end
            S1: begin
                if (d == 1'b0) begin
                    S_next_logic = 1'b1;
                end else begin
                    S11_next_logic = 1'b1;
                end
            end
            S11: begin
                if (d == 1'b0) begin
                    S110_next_logic = 1'b1;
                end else begin
                    S11_next_logic = 1'b1;
                end
            end
            S110: begin
                if (d == 1'b0) begin
                    S_next_logic = 1'b1;
                end else begin
                    B0_next_logic = 1'b1;
                end
            end
            B0: begin
                B1_next_logic = 1'b1;
            end
            B1: begin
                B2_next_logic = 1'b1;
            end
            B2: begin
                B3_next_logic = 1'b1;
            end
            B3: begin
                Count_next_logic = 1'b1;
            end
            Count: begin
                if (done_counting == 1'b0) begin
                    Count_next_logic = 1'b1;
                end else begin
                    Wait_next_logic = 1'b1;
                end
            end
            Wait: begin
                if (ack == 1'b0) begin
                    Wait_next_logic = 1'b1;
                end else begin
                    S_next_logic = 1'b1;
                end
            end
            default: begin
                // Default case: no change
                // When in an undefined state, no state transition
                ;
            end
        endcase
    end

    // Combinational logic for outputs
    always @(*) begin
        // Initialize all output signals to 0
        done_logic = 1'b0;
        counting_logic = 1'b0;
        shift_ena_logic = 1'b0;

        // Determine outputs based on current state
        case (state)
            B0:
                shift_ena_logic = 1'b1;
            B1:
                shift_ena_logic = 1'b1;
            B2:
                shift_ena_logic = 1'b1;
            B3:
                shift_ena_logic = 1'b1;
            Count:
                counting_logic = 1'b1;
            Wait:
                done_logic = 1'b1;
            default:
                // No output in default state
                ;
        endcase
    end

    // Assign outputs
    assign B3_next = B3_next_logic;
    assign S_next = S_next_logic;
    assign S1_next = S1_next_logic;
    assign Count_next = Count_next_logic;
    assign Wait_next = Wait_next_logic;
    assign done = done_logic;
    assign counting = counting_logic;
    assign shift_ena = shift_ena_logic;

endmodule