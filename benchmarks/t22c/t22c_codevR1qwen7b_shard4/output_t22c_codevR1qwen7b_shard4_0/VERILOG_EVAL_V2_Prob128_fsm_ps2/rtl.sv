module TopModule (clk, reset, in, done);
    input logic clk;
    input logic reset;
    input logic [7:0] in;
    output logic done;

    // State parameters
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] WAIT2 = 2'b01;
    localparam [1:0] WAIT3 = 2'b10;

    // State and counter registers
    logic [1:0] state = IDLE;
    logic [1:0] count = 0;

    // Next state and done signals
    logic [1:0] next_state;
    logic [1:0] next_count;
    logic next_done;

    // Combinational logic for state transitions and done signal
    always @(*) begin
        next_state = state;
        next_count = count;
        next_done = 0;
        case (state)
            IDLE: begin
                if (in[3]) begin
                    next_state = WAIT2;
                    next_count = 1;
                end
            end
            WAIT2: begin
                if (in[3]) begin
                    next_count = count + 1;
                end
                if (count == 2) begin
                    next_state = IDLE;
                    next_done = 1;
                end else begin
                    next_state = WAIT3;
                end
            end
            WAIT3: begin
                if (in[3]) begin
                    next_count = 0;
                    next_state = IDLE;
                    next_done = 1;
                end else begin
                    next_count = 0;
                    next_state = IDLE;
                end
            end
            default: next_state = IDLE;
        endcase
    end

    // Sequential logic for state and count updates
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            count <= 0;
        end else begin
            state <= next_state;
            count <= next_count;
        end
    end

    // Done output register
    reg done_reg = 0;

    always @(posedge clk) begin
        done_reg <= next_done;
    end

    assign done = done_reg;

endmodule