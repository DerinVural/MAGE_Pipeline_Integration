module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic in,
    output logic done
);

    // State Definitions using localparam
    localparam [1:0] S_IDLE = 2'b00;
    localparam [1:0] S_DATA = 2'b01;
    localparam [1:0] S_WAIT_STOP = 2'b10;
    localparam [1:0] S_WAIT_INVALID_STOP = 2'b11;

    // State Registers and Logic
    logic [1:0] current_state;
    logic [1:0] next_state;
    logic [3:0] bit_count;

    // Internal signals
    logic done_pulse;

    // Initialization Block (Setting known values at time zero)
    initial begin
        current_state = S_IDLE;
        bit_count = 4'd0;
        done_pulse = 1'b0;
    end

    // Sequential Logic (State and Counter Registers)
    always @(posedge clk)
    begin
        if (reset)
        begin
            current_state <= S_IDLE;
            bit_count <= 4'd0;
            done_pulse <= 1'b0;
        end
        else
        begin
            current_state <= next_state;
            
            // Counter logic
            if (next_state == S_DATA && current_state == S_DATA) begin
                // Increment only if we are still within the 8 data bits
                if (bit_count < 4'd8) begin
                    bit_count <= bit_count + 1;
                end
            end else if (next_state == S_DATA && current_state == S_IDLE && in == 1'b0) begin
                // Transition from IDLE to DATA means we received the start bit (0), count starts at 1
                bit_count <= 4'd1;
            end else begin
                // Reset counter if we transition out of the S_DATA phase
                if (next_state != S_DATA) begin
                    bit_count <= 4'd0;
                end
            end
            
            // Done pulse logic: Assert high only on the cycle the transition from WAIT_STOP to IDLE occurs
            if (current_state == S_WAIT_STOP && in == 1'b1 && next_state == S_IDLE)
            begin
                done_pulse <= 1'b1; // Pulse done high for one cycle
            end else begin
                done_pulse <= 1'b0;
            end
        end
    end

    // Combinational Logic (Next State Determination)
    always @(*)
    begin
        next_state = current_state;
        
        case (current_state)
            S_IDLE:
            begin
                // Idle state expects input=1. Detect start bit (0).
                if (in == 1'b0) begin
                    next_state = S_DATA;
                end
            end

            S_DATA:
            begin
                // Data bits are received sequentially up to 8 bits
                if (bit_count < 4'd8) begin
                    // Stay in data receiving state
                    next_state = S_DATA;
                end else begin
                    // 8 data bits received, check stop bit (must be 1)
                    if (in == 1'b1) begin
                        next_state = S_WAIT_STOP; // Potential success
                    end else begin
                        // Stop bit failed (is 0). Wait until a stop bit (1) is seen.
                        next_state = S_WAIT_INVALID_STOP;
                    end
                end
            end

            S_WAIT_STOP:
            begin
                // Must see stop bit (1) to confirm success
                if (in == 1'b1) begin
                    next_state = S_IDLE; // Success! Go back to idle
                end else begin
                    // Stop bit was 0. Protocol violation. Wait for next valid stop bit.
                    next_state = S_WAIT_INVALID_STOP;
                end
            end

            S_WAIT_INVALID_STOP:
            begin
                // Protocol violation occurred (Stop bit was 0). Wait until a stop bit (1) is seen
                if (in == 1'b1) begin
                    next_state = S_IDLE; // Found a stop bit, sequence reset, go idle
                end else begin
                    // Still waiting for the stop bit (1)
                    next_state = S_WAIT_INVALID_STOP;
                end
            end
        endcase
    end

    // Output Logic (Combinational)
    always @(*)
    begin
        done = done_pulse;
    end

endmodule