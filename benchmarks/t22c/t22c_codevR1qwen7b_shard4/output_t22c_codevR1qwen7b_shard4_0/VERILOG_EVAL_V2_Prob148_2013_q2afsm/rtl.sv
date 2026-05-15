module TopModule(input clk, input resetn, input [2:0] r, output logic [2:0] g);

 localparam STATE_A = 3'b000;
 localparam STATE_B = 3'b001;
 localparam STATE_C = 3'b010;
 localparam STATE_D = 3'b100;

 logic [2:0] state, next_state;

 // Sequential block for state update
 always_ff @(posedge clk) begin
 if (!resetn) state <= STATE_A;
 else state <= next_state;
 end

 // Combinational next state logic
 always_comb begin
 next_state = state;
 case (state)
 STATE_A: begin
 if (r == 0) next_state = STATE_A;
 else if (r[0]) next_state = STATE_B;
 else if (r == 3'b001) next_state = STATE_C;
 else if (r == 3'b000) next_state = STATE_D;
 end
 STATE_B: begin
 next_state = r[0] ? STATE_B : STATE_A;
 end
 STATE_C: begin
 next_state = r[1] ? STATE_C : STATE_A;
 end
 default: next_state = STATE_A;
 endcase
 end

 // Output logic
 assign g[0] = (state == STATE_B);
 assign g[1] = (state == STATE_C);
 assign g[2] = (state == STATE_D);

endmodule