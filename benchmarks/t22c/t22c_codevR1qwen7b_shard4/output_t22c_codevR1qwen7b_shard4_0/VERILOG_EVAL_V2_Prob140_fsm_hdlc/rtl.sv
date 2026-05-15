module TopModule (input logic clk, input logic reset, input logic in, output logic disc, output logic flag, output logic err);

    // State definitions
    localparam [2:0] INIT = 3'b000,
                     ST1 = 3'b001,
                     ST2 = 3'b010,
                     ST3 = 3'b011,
                     ST4 = 3'b100,
                     ST5 = 3'b101,
                     ST6 = 3'b110;

    // State registers and next state
    logic [2:0] state, next_state;
    logic [2:0] prev_state;
    // Previous bits buffer (7 bits)
    logic [6:0] prev_bits;
    // Counter for consecutive ones (up to 6 ones)
    logic [2:0] ones_count;

    // Initialize registers with known values
    initial begin
        state = INIT;
        prev_bits = 7'b0;
        ones_count = 0;
    end

    // State transition and data path logic
    always @(posedge clk) begin
        if (reset) begin
            state <= INIT;
            prev_bits <= 7'b0;
            ones_count <= 0;
        end else begin
            // Update previous bits (shift left, append new in)
            prev_bits <= {prev_bits[5:0], in};
            // Update consecutive ones count
            if (in) begin
                ones_count <= (ones_count < 6) ? ones_count + 1 : 6;
            end else begin
                ones_count <= 0;
            end
        end
    end

    // Combinational logic for flags
    always @(*) begin
        // Default outputs
        disc = 0;
        flag = 0;
        err = 0;

        // Error if 7 or more ones
        if (ones_count >= 6) begin
            err = 1;
        end

        // Flag sequence check: 0 followed by six 1s and a 0 (prev_bits == 7'b01111110)
        if (prev_bits == 7'b01111110) begin
            flag = 1;
        end

        // Discard sequence check: 0 followed by five 1s and a 0 (prev_bits == 7'b0111110)
        if (prev_bits == 7'b0111110) begin
            disc = 1;
        end
    end

    // State machine logic
    always @(*) begin
        next_state = state;
        case (state)
            INIT: next_state = in ? ST1 : INIT;
            ST1: next_state = in ? ST2 : INIT;
            ST2: next_state = in ? ST3 : INIT;
            ST3: next_state = in ? ST4 : INIT;
            ST4: next_state = in ? ST5 : INIT;
            ST5: next_state = in ? ST6 : INIT;
            ST6: next_state = in ? ST6 : INIT;
            default: next_state = INIT;
        endcase
    end

    // Update state on clock edge
    always @(posedge clk) begin
        state <= next_state;
    end

endmodule