module TopModule (input logic clk, input logic reset, input logic [7:0] in, output logic [23:0] out_bytes, output logic done);

    // FSM states
    localparam IDLE = 2'b00;
    localparam FIRST_BYTE = 2'b01;
    localparam SECOND_BYTE = 2'b10;
    localparam THIRD_BYTE = 2'b11;

    reg [1:0] current_state, next_state;
    reg [7:0] byte1, byte2;
    reg [23:0] out_bytes_reg;
    reg done_reg;

    // Initialize registers
    initial begin
        current_state = IDLE;
        next_state = IDLE;
        byte1 = 0;
        byte2 = 0;
        out_bytes_reg = 0;
        done_reg = 0;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            current_state <= IDLE;
            byte1 <= 8'h0;
            byte2 <= 8'h0;
            out_bytes_reg <= 24'h0;
            done_reg <= 0;
        end else begin
            current_state <= next_state;
            if (current_state == IDLE && in[3]) begin
                byte1 <= in;
            end else if (current_state == FIRST_BYTE) begin
                byte2 <= in;
            end else if (current_state == SECOND_BYTE) begin
                // No action needed here, next_state moves to THIRD_BYTE
            end
        end
    end

    // Combinational next state logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (in[3]) begin
                    next_state = FIRST_BYTE;
                end
            end
            FIRST_BYTE: next_state = SECOND_BYTE;
            SECOND_BYTE: next_state = THIRD_BYTE;
            THIRD_BYTE: next_state = IDLE;
        endcase
    end

    // Capture third byte and trigger done
    always @(posedge clk) begin
        if (!reset && (current_state == SECOND_BYTE)) begin
            // Wait for next state to move to THIRD_BYTE
            if (next_state == THIRD_BYTE) begin
                // Third byte is in 'in' when state transitions to THIRD_BYTE
                out_bytes_reg <= {byte1, byte2, in};
                done_reg <= 1;
            end else begin
                done_reg <= 0;
            end
        end else begin
            done_reg <= 0;
        end
    end

    // Output assignments
    assign out_bytes = out_bytes_reg;
    assign done = done_reg;

endmodule