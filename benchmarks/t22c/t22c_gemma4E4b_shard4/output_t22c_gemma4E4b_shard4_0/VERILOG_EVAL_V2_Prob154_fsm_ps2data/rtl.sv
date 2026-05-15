module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic [7:0] in,
    output logic [23:0] out_bytes,
    output logic done
);

    // State Definition
    localparam STATE_SEARCH = 2'b00;
    localparam STATE_BYTE2 = 2'b01;
    localparam STATE_BYTE3 = 2'b10;
    localparam STATE_COMPLETE = 2'b11;

    // State Registers
    logic [1:0] current_state; 
    logic [1:0] next_state;

    // Data Registers
    logic [7:0] byte1_reg; // First byte (MSB of output_bytes)
    logic [7:0] byte2_reg; // Second byte
    logic [7:0] byte3_reg; // Third byte (LSB of output_bytes)

    // Internal wire for output packing
    logic [23:0] packed_output;

    // Initialization Block (For non-reset initial values)
    initial begin
        // Initialize registers to known safe values
        byte1_reg = 8'h00;
        byte2_reg = 8'h00;
        byte3_reg = 8'h00;
        current_state = STATE_SEARCH;
    end

    // 1. State Register Logic (Sequential)
    always @(posedge clk)
    begin
        if (reset)
        begin
            current_state <= STATE_SEARCH;
        end
        else
        begin
            current_state <= next_state;
        end
    end

    // 2. Data Register Logic (Sequential - Capturing data)
    // Capture logic depends on the state transition
    always @(posedge clk)
    begin
        if (reset)
        begin
            byte1_reg <= 8'h00;
            byte2_reg <= 8'h00;
            byte3_reg <= 8'h00;
        end
        else begin
            case (current_state)
                STATE_SEARCH: begin
                    // Byte 1 is captured when transitioning from SEARCH
                    if (next_state == STATE_BYTE2) begin
                        byte1_reg <= in;
                    end
                end
                STATE_BYTE2: begin
                    // Byte 2 is captured when transitioning from BYTE2
                    if (next_state == STATE_BYTE3) begin
                        byte2_reg <= in;
                    end
                end
                STATE_BYTE3: begin
                    // Byte 3 is captured when transitioning from BYTE3
                    if (next_state == STATE_COMPLETE) begin
                        byte3_reg <= in;
                    end
                end
                STATE_COMPLETE: begin
                    // Hold data while complete, but prepare for next search
                    // Data remains valid until the next state change resets it implicitly
                end
            endcase
        end
    end

    // 3. Next State Logic (Combinational)
    always @(*)
    begin
        next_state = current_state;

        case (current_state)
            STATE_SEARCH:
                // Look for start byte (in[3] == 1)
                if (in[3] == 1'b1) begin
                    next_state = STATE_BYTE2;
                end
                else begin
                    next_state = STATE_SEARCH;
                end

            STATE_BYTE2:
                // Move to next stage
                next_state = STATE_BYTE3;

            STATE_BYTE3:
                // Move to completion state
                next_state = STATE_COMPLETE;

            STATE_COMPLETE:
                // Message complete, reset to search state for next packet
                next_state = STATE_SEARCH;
        endcase
    end

    // 4. Output Logic (Combinational)
    // Pack the bytes: Byte1 (MSB) | Byte2 | Byte3 (LSB)
    assign packed_output = {byte1_reg, byte2_reg, byte3_reg};

    // Determine done signal
    // Done is asserted in the cycle immediately AFTER Byte 3 is received (i.e., when in STATE_COMPLETE)
    assign done = (current_state == STATE_COMPLETE);

    // Assign final output
    assign out_bytes = packed_output;

endmodule