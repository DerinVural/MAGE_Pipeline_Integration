module TopModule (
    input clk,
    input in,
    input reset,
    output reg [7:0] out_byte,
    output reg done
);

    // State definitions
    localparam IDLE     = 3'b000;
    localparam START    = 3'b001;
    localparam DATA     = 3'b010;
    localparam STOP     = 3'b011;
    localparam WAIT_STOP = 3'b100;

    // State register
    logic [2:0] state, next_state;

    // Data shift register
    logic [7:0] data_reg;
    logic [3:0] bit_count;

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            data_reg <= 8'h00;
            bit_count <= 4'd0;
            out_byte <= 8'h00;
            done <= 1'b0;
        end else begin
            state <= next_state;
            if (bit_count != 4'd0) begin
                data_reg <= {in, data_reg[7:1]};
            end
            if (bit_count == 4'd8) begin
                out_byte <= data_reg;
            end
            if (done) begin
                done <= 1'b0;
            end
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (in == 1'b0) begin
                    next_state = START;
                end else begin
                    next_state = IDLE;
                end
            end
            
            START: begin
                if (bit_count == 4'd8) begin
                    if (in == 1'b1) begin
                        next_state = STOP;
                    end else begin
                        next_state = WAIT_STOP;
                    end
                end else begin
                    next_state = START;
                end
            end
            
            DATA: begin
                if (bit_count == 4'd8) begin
                    if (in == 1'b1) begin
                        next_state = STOP;
                    end else begin
                        next_state = WAIT_STOP;
                    end
                end else begin
                    next_state = DATA;
                end
            end
            
            STOP: begin
                next_state = IDLE;
            end
            
            WAIT_STOP: begin
                if (in == 1'b1) begin
                    next_state = IDLE;
                end else begin
                    next_state = WAIT_STOP;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end

    // Output logic
    always @(*) begin
        case (state)
            IDLE: begin
                bit_count = 4'd0;
                done = 1'b0;
            end
            
            START: begin
                bit_count = 4'd1;
                done = 1'b0;
            end
            
            DATA: begin
                bit_count = bit_count + 1;
                done = 1'b0;
            end
            
            STOP: begin
                bit_count = 4'd0;
                done = 1'b1;
            end
            
            WAIT_STOP: begin
                bit_count = 4'd0;
                done = 1'b0;
            end
            
            default: begin
                bit_count = 4'd0;
                done = 1'b0;
            end
        endcase
    end

endmodule