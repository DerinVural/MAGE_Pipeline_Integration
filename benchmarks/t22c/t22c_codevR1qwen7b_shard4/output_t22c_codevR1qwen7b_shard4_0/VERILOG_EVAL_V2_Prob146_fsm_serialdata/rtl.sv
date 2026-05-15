module TopModule (input clk, input in, input reset, output [7:0] out_byte, output done);
    // States
    localparam IDLE = 0;
    localparam START = 1;
    localparam DATA = 2;
    localparam STOP = 3;
    localparam WAIT = 4;
    // State register
    logic [2:0] state = IDLE;
    // Data registers
    logic [2:0] bit_count = 0;
    logic [7:0] data_byte = 0;
    // Internal signals
    logic start_bit_detected = 0;
    logic stop_bit_valid = 0;
    // Synchronizer for in
    logic in_sync;
    reg in_meta;
    always @(posedge clk) begin
        in_meta <= in;
        in_sync <= in_meta;
    end
    // State transitions and data capture
    always @(posedge clk) begin
        if (!reset) begin
            state <= IDLE;
            bit_count <= 0;
            data_byte <= 0;
            // ... other inits if needed
        end else begin
            case (state)
                IDLE: begin
                    if (in_sync == 0) begin
                        state <= START;
                    end
                end
                START: begin
                    // Check start bit is 0
                    if (in_sync == 0) begin
                        state <= DATA;
                        bit_count <= 0;
                    end else begin
                        state <= IDLE; // Invalid start, retry
                    end
                end
                DATA: begin
                    if (bit_count < 7) begin
                        data_byte[bit_count] <= in_sync;
                        bit_count <= bit_count + 1;
                    end else begin
                        data_byte[bit_count] <= in_sync;
                        state <= STOP;
                    end
                end
                STOP: begin
                    if (in_sync == 1) begin
                        state <= WAIT;
                    end else begin
                        state <= WAIT; // Wait until stop bit is valid
                    end
                end
                WAIT: begin
                    if (in_sync == 1) begin
                        state <= IDLE;
                    end else begin
                        // Stay until stop bit found
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
    // Outputs
    assign done = (state == WAIT);
    assign out_byte = data_byte;
endmodule