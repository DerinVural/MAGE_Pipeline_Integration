module TopModule (input clk, reset, input data, output logic [3:0] count, output logic counting, done, ack); 
 localparam STATE_IDLE = 0;
 localparam STATE_CAPTURE = 1;
 localparam STATE_COUNTING = 2;
 localparam STATE_DONE = 3;
 
 reg [2:0] state, next_state;
 reg [3:0] delay_reg;
 reg [12:0] cycle_count;
 reg [3:0] captured_delay;
 reg [3:0] remaining_time;
 reg done_reg;
 reg ack_reg;
 reg [3:0] count_reg;
 reg counting_reg;
 
 reg [3:0] shift_reg;
 wire start_detected;
 
 // Initialization
 initial begin
 state = STATE_IDLE;
 delay_reg = 0;
 cycle_count = 0;
 remaining_time = 0;
 done_reg = 0;
 ack_reg = 0;
 counting_reg = 0;
 captured_delay = 0;
 count_reg = 0;
 end
 
 // State transition sequential logic
 always @(posedge clk) begin
 if (reset) state <= STATE_IDLE;
 else state <= next_state;
 end
 
 // Shift register for start sequence detection
 always @(posedge clk) begin
 if (~reset) shift_reg <= 4'b0;
 else shift_reg <= {shift_reg[2:0], data};
 end
 
 // Start detection
 assign start_detected = (shift_reg == 4'b1101);
 
 // Next state logic
 always @(*) begin
 next_state = state;
 case (state)
 STATE_IDLE: if (start_detected) next_state = STATE_CAPTURE;
 STATE_CAPTURE: if (capture_count == 3) next_state = STATE_COUNTING;
 STATE_COUNTING: if (cycle_count >= (remaining_time * 1000 -1)) next_state = STATE_DONE;
 STATE_DONE: if (ack) next_state = STATE_IDLE;
 endcase
 end
 
 // Capture count
 reg [2:0] capture_count;
 always @(posedge clk) begin
 if (state == STATE_IDLE && start_detected) capture_count <= 0;
 else if (state == STATE_CAPTURE) begin
 if (capture_count < 3) begin
 captured_delay[capture_count] <= data;
 capture_count <= capture_count +1;
 end else begin
 captured_delay[3] <= data;
 end
 end
 end
 
 // Set delay_reg on capture completion
 always @(posedge clk) begin
 if (state == STATE_CAPTURE && capture_count ==3) delay_reg <= captured_delay;
 end
 
 // Cycle count logic
 always @(posedge clk) begin
 if (state == STATE_COUNTING) begin
 if (cycle_count < (delay_reg * 1000)) cycle_count <= cycle_count +1;
 end else begin
 cycle_count <=0;
 remaining_time <= delay_reg +1;
 end
 end
 
 // Assign outputs
 assign count = (state == STATE_COUNTING) ? remaining_time : 4'b0;
 assign counting = (state == STATE_COUNTING);
 assign done = (state == STATE_DONE);
 assign ack = ack_reg;
 
 // Done state logic
 always @(posedge clk) begin
 if (reset) begin
 done_reg <=0; ack_reg <=0;
 end else if (state == STATE_DONE) begin
 done_reg <=1;
 if (ack) begin
 ack_reg <=1; done_reg <=0;
 end
 end
 end
 endmodule