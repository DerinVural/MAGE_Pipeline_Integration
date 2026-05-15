module TopModule (
    input  logic clk,
    input  logic in,
    input  logic reset,
    output logic [7:0] out_byte,
    output logic done
);

    // State Definitions
    localparam S_IDLE      = 3'b000;
    localparam S_START     = 3'b001;
    localparam S_DATA      = 3'b010;
    localparam S_STOP_CHECK= 3'b011;
    localparam S_ERROR_WAIT= 3'b100;

    // State and Counter Registers
    logic [2:0] state;
    logic [2:0] state_next;
    logic [2:0] bit_count;
    logic [7:0] rx_byte;

    // Output Registers (Synchronous storage for outputs)
    logic [7:0] out_byte_r;
    logic done_r;

    // --- Sequential Logic (State, Counter, Data Register) ---
    always @(posedge clk)
    begin
        if (reset)
        begin
            state <= S_IDLE;
            bit_count <= 3'b000;
            rx_byte <= 8'h00;
            out_byte_r <= 8'h00;
            done_r <= 1'b0;
        end
        else
        begin
            state <= state_next;
            
            // Data Accumulation (LSB First: in is B_i, lands at bit position i)
            if (state == S_DATA)
            begin
                rx_byte <= rx_byte | (in << bit_count);
            end

            // Counter Update
            if (state == S_DATA && bit_count < 7) begin
                bit_count <= bit_count + 1;
            end else if (state == S_STOP_CHECK) begin
                // Check if transition happened
                if (in == 1'b1) begin
                    // Success: Byte received, reset counter and transition out
                    bit_count <= 3'b000;
                    // Store the byte value on success
                    out_byte_r <= rx_byte;
                end else begin
                    // Failure: Stop bit was 0, reset counter to start checking from next bit
                    bit_count <= 3'b000;
                end
            end else if (state == S_ERROR_WAIT && in == 1'b1) begin
                // Recovery found (saw a 1), reset counter to look for start bit
                bit_count <= 3'b000;
            end else begin
                // Hold count otherwise (e.g., staying in S_DATA or S_ERROR_WAIT)
                bit_count <= bit_count;
            end

            // Done pulse assertion (Asserted only on the cycle AFTER successful stop check)
            if (state == S_STOP_CHECK && in == 1'b1 && state_next == S_IDLE)
            begin
                done_r <= 1'b1;
            end
            else
            begin
                done_r <= 1'b0;
            end
        end
    end

    // --- Combinational Logic (Next State and Outputs) ---
    always @(*)
    begin
        state_next = state;
        // Default assignments for outputs (driven by registers)
        out_byte = out_byte_r;
        done = done_r;

        case (state)
            S_IDLE:
                // Idle: Wait for Start Bit (0). Protocol idle is 1.
                if (in == 1'b0) begin
                    state_next = S_START;
                end
                else begin
                    state_next = S_IDLE;
                end

            S_START:
                // Start bit (0) received. Move to first data bit (bit_count starts at 0).
                state_next = S_DATA;

            S_DATA:
                // Check if 8 bits have been received (bit_count reaches 7 means 8 bits processed 0 through 7).
                if (bit_count == 7) begin
                    state_next = S_STOP_CHECK;
                end
                else begin
                    state_next = S_DATA;
                end

            S_STOP_CHECK:
                // Check stop bit (must be 1).
                if (in == 1'b1) begin
                    // Success: Byte complete. Transition back to Idle.
                    state_next = S_IDLE;
                end
                else begin
                    // Failure: Stop bit is 0. Enter error wait state.
                    state_next = S_ERROR_WAIT;
                end

            S_ERROR_WAIT:
                // Waiting for a stop bit (1) to re-synchronize.
                if (in == 1'b1) begin
                    // Found a 1, revert to IDLE to await a proper start sequence.
                    state_next = S_IDLE;
                end
                else begin
                    state_next = S_ERROR_WAIT;
                end
        endcase
    end

endmodule