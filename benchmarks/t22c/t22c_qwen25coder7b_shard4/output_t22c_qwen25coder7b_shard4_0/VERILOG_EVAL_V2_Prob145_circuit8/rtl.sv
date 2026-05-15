module TopModule(
    logic clock,
    logic a,
    logic p,
    logic q,
    logic reset
);

    // State definitions
    localparam IDLE = 2'b00;
    localparam P_SET = 2'b01;
    localparam Q_SET = 2'b10;

    // State register
    logic [1:0] state;
    logic [1:0] state_next;

    // Initialize state register to known values
    initial begin
        state = IDLE;
        state_next = IDLE;
    end

    // Next state logic
    always_comb begin
        state_next = IDLE;
        case (state)
            IDLE: state_next = a ? P_SET : IDLE;
            P_SET: state_next = a ? Q_SET : IDLE;
            Q_SET: state_next = a ? IDLE : Q_SET;
        endcase
    end

    // Output logic
    always_comb begin
        p = 1'b0;
        q = 1'b0;
        case (state)
            IDLE: p = 1'b0;
            P_SET: p = 1'b1;
            Q_SET: p = 1'b0;
        endcase
        case (state)
            IDLE: q = 1'b0;
            P_SET: q = 1'b0;
            Q_SET: q = 1'b1;
        endcase
    end

endmodule