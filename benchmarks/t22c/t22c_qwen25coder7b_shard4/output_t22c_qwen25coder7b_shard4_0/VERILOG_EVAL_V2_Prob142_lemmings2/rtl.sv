module TopModule (
	input logic clk,
	input logic areset,
	input logic bump_left,
	input logic bump_right,
	input logic ground,
	output logic walk_left,
	output logic walk_right,
	output logic aaah
);

parameter [1:0] WALK_LEFT = 2'b00;
parameter [1:0] WALK_RIGHT = 2'b01;
parameter [1:0] FALLING = 2'b10;

localparam [1:0][1:0][1:0] NEXT_STATE_TABLE = [
	[WALK_LEFT, WALK_RIGHT, WALK_RIGHT],
	[WALK_LEFT, BUMP_RIGHT, WALK_RIGHT],
	[WALK_LEFT, BUMP_LEFT, WALK_LEFT],
	[WALK_LEFT, BUMP_RIGHT | BUMP_LEFT, WALK_LEFT],
	[WALK_RIGHT, BUMP_RIGHT, WALK_LEFT],
	[WALK_RIGHT, BUMP_LEFT, WALK_RIGHT],
	[WALK_RIGHT, BUMP_RIGHT | BUMP_LEFT, WALK_RIGHT],
	[FALLING, GROUND, FALLING],
	[FALLING, ~GROUND, WALK_LEFT]
];

logic [1:0] state;
logic [1:0] nxt_state;
logic [1:0] fall_timer;

initial begin
	state = WALK_LEFT;
	fall_timer = 0;
	nxt_state = WALK_LEFT;
end

always_ff @(posedge clk or posedge areset) begin
	if (areset) begin
		state <= WALK_LEFT;
		fall_timer <= 0;
		nxt_state <= WALK_LEFT;
	end else begin
		state <= nxt_state;
		fall_timer <= fall_timer ? fall_timer - 1 : 0;
	end
end

always @(*) begin
	if (!fall_timer) begin
		if (ground) begin
			case ({bump_left, bump_right})
				2'b00: nxt_state = WALK_LEFT;
				2'b10: nxt_state = WALK_RIGHT;
				2'b01: nxt_state = WALK_LEFT;
				2'b11: nxt_state = WALK_LEFT;
			endcase
		end else begin
			fall_timer = 3;
			case ({bump_left, bump_right})
				2'b00: nxt_state = FALLING;
				default: nxt_state = FALLING;
			endcase
		end
	end else begin
		nxt_state = FALLING;
	end
	walk_left = (nxt_state == WALK_LEFT);
	walk_right = (nxt_state == WALK_RIGHT);
	aaah = (nxt_state == FALLING);
end

endmodule