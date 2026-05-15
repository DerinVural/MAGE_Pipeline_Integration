module TopModule (
    input clk,
    input reset,
    output logic [2:0] ena,
    output logic [15:0] q
);

    // Register to hold the current 4-digit BCD count (0 to 9999)
    logic [15:0] q_reg;

    // Wire to hold the calculated next state
    logic [15:0] q_next;
    
    // --- Sequential Logic (Counter Update) ---
    always @(posedge clk)
    begin
        if (reset)
        begin
            q_reg <= 16'h0000;
        end
        else
        begin
            // Default next state is current state (holds if no increment or if enabled=0)
            q_next = q_reg;

            // --- Calculate Next State Digit by Digit, propagating carry ---
            
            // 1. Ones Digit (D0): Always counts up unless saturated (9)
            logic [3:0] d0_curr = q_reg[3:0];
            logic carry_d0_to_d1;

            if (d0_curr == 4'd9) begin
                q_next[3:0] = 4'h0; // Rollover
                carry_d0_to_d1 = 1'b1;
            end else begin
                q_next[3:0] = d0_curr + 1; // Increment
                carry_d0_to_d1 = 1'b0;
            end

            // 2. Tens Digit (D1): Controlled by ena[0]
            logic [3:0] d1_curr = q_reg[7:4];
            logic carry_d1_to_d2;

            if (ena[0] == 1'b1) begin
                if (d1_curr == 4'd9 && carry_d0_to_d1 == 1'b1) begin
                    q_next[7:4] = 4'h0; // Rollover
                    carry_d1_to_d2 = 1'b1;
                end else if (d1_curr < 4'd9) begin
                    q_next[7:4] = d1_curr + 1; // Increment
                    carry_d1_to_d2 = 1'b0;
                end else begin
                    // d1_curr == 9 and carry_d0_to_d1 == 0 (Held at 9)
                    q_next[7:4] = 4'h9;
                end
            end else begin
                q_next[7:4] = d1_curr; // Disabled, holds value
                carry_d1_to_d2 = 1'b0;
            end

            // 3. Hundreds Digit (D2): Controlled by ena[1]
            logic [3:0] d2_curr = q_reg[11:8];
            logic carry_d2_to_d3;

            if (ena[1] == 1'b1) begin
                if (d2_curr == 4'd9 && carry_d1_to_d2 == 1'b1) begin
                    q_next[11:8] = 4'h0; // Rollover
                    carry_d2_to_d3 = 1'b1;
                end else if (d2_curr < 4'd9) begin
                    q_next[11:8] = d2_curr + 1; // Increment
                    carry_d2_to_d3 = 1'b0;
                end else begin
                    // d2_curr == 9 and carry_d1_to_d2 == 0 (Held at 9)
                    q_next[11:8] = 4'h9;
                end
            end else begin
                q_next[11:8] = d2_curr; // Disabled, holds value
                carry_d2_to_d3 = 1'b0;
            end

            // 4. Thousands Digit (D3): Controlled by ena[2]
            logic [3:0] d3_curr = q_reg[15:12];
            
            if (ena[2] == 1'b1) begin
                if (d3_curr == 4'd9 && carry_d2_to_d3 == 1'b1) begin
                    q_next[15:12] = 4'h0; // Rollover
                    // No further carry out
                end else if (d3_curr < 4'd9) begin
                    q_next[15:12] = d3_curr + 1; // Increment
                end else begin
                    // d3_curr == 9 and carry_d2_to_d3 == 0 (Held at 9)
                    q_next[15:12] = 4'h9;
                end
            end else begin
                q_next[15:12] = d3_curr; // Disabled, holds value
            end

            q_reg <= q_next;
        end
    end

    // --- Combinational Logic (Output Generation for ENA) ---
    // Ena outputs indicate if the corresponding digit is NOT saturated at 9, 
    // allowing the increment to proceed (i.e., allowing rollover from 9)
    always @(*)
    begin
        // ena[0] controls D1 (Tens): True if D1 is not 9
        ena[0] = (q_reg[7:4] != 4'd9);
        
        // ena[1] controls D2 (Hundreds): True if D2 is not 9
        ena[1] = (q_reg[11:8] != 4'd9);
        
        // ena[2] controls D3 (Thousands): True if D3 is not 9
        ena[2] = (q_reg[15:12] != 4'd9);
    end

    // Drive outputs from the register
    assign q = q_reg;

endmodule