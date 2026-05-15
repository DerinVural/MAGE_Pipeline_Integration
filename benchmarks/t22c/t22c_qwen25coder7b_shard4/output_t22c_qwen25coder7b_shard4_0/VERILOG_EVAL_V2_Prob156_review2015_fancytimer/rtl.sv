module TopModule(
    input logic clk,
    input logic reset,
    input logic data,
    output logic [3:0] count,
    output logic counting,
    output logic done,
    input logic ack
);

    // Define states
    localparam IDLE = 3'b000;
    localparam DETECT = 3'b001;
    localparam COUNTING = 3'b010;
    localparam DONE = 3'b011;

    // State and counter variables
    logic [2:0] state;
    logic [3:0] delay;
    logic [3:0] counter;
    logic [3:0] delay_reg;
    logic [3:0] counter_reg;
    logic counting_reg;
    logic done_reg;

    // Register initialization
    initial begin
        state = IDLE;
        delay = 4'b0;
        counter = 4'b0;
        counting_reg = 1'b0;
        done_reg = 1'b0;
    end

    // Sequential logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            delay_reg <= 4'b0;
            counter_reg <= 4'b0;
            counting_reg <= 1'b0;
            done_reg <= 1'b0;
        end else begin
            state <= state;
            delay_reg <= delay;
            counter_reg <= counter;
            counting_reg <= counting;
            done_reg <= done;
        end
    end

    // Detect the start sequence '1101'
    logic [3:0] data_shifted;
    always_comb begin
data_shifted = {data, delay_reg};
            case(data_shifted)
                4'b1101: begin
                    state = DETECT;
                    delay = data;
                end
                default: state = IDLE;
            endcase
        end

    // Counting state
    always_comb begin
        case(state)
            IDLE: begin
                counting_reg = 1'b0;
                done_reg = 1'b0;
            end
            DETECT: begin
                counting_reg = 1'b0;
                done_reg = 1'b0;
            end
            COUNTING: begin
                counting_reg = 1'b1;
                done_reg = (counter_reg == 0) ? 1'b1 : 1'b0;
            end
            DONE: begin
                counting_reg = 1'b0;
                done_reg = 1'b0;
            end
        endcase
    end

    // Counter decrement
    always_comb begin
        counter_reg = counter;
        if (counting_reg && (counter_reg > 0)) begin
            counter_reg = counter_reg - 1;
        end
    end

    // Update counter on rising edge of data
    always @(posedge clk) begin
        if (reset) begin
            counter_reg <= 4'b0;
        end else begin
            if ((state == DETECT) && (data == 1'b1)) begin
                counter_reg <= delay;
            end else if (done_reg) begin
                counter_reg <= 4'b0;
            end
        end
    end

    // Assign output signals
    assign count = counter_reg;
    assign counting = counting_reg;
    assign done = done_reg;

endmodule