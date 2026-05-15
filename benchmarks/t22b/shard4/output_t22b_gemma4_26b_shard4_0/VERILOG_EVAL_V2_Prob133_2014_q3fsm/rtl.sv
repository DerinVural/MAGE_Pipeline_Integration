module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic s,
    input  logic w,
    output logic z
);

    // State definitions
    localparam STATE_A = 1'b0;
    localparam STATE_B = 1'b1;

    // State and auxiliary registers
    logic state;
    logic [1:0] cycle_cnt;
    logic [1:0] w_sum;
    logic z_reg;

    // Initialize registers to avoid X in simulation
    initial begin
        state = STATE_A;
        cycle_cnt = 2'b00;
        w_sum = 2'b00;
        z_reg = 1'b0;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_A;
            cycle_cnt <= 2'b00;
            w_sum <= 2'b00;
            z_reg <= 1'b0;
        end else begin
            case (state)
                STATE_A:
                    if (s) begin
                        state <= STATE_B;
                        cycle_cnt <= 2'b00;
                        w_sum <= 2'b00;
                    end else begin
                        state <= STATE_A;
                    end

                STATE_B:
                    begin
                        // The current cycle is being processed
                        // cycle_cnt tracks how many cycles have COMPLETED
                        // We are currently in the (cycle_cnt + 1)-th cycle
                        
                        if (cycle_cnt == 2'd2) begin
                            // This is the 3rd cycle. 
                            // We calculate the result for the window and reset for the next window.
                            if ((w_sum + (w ? 1'b1 : 1'b0)) == 2'b10) begin
                                z_reg <= 1'b1;
                            end else begin
                                z_reg <= 1'b0;
                            end
                            cycle_cnt <= 2'b00;
                            w_sum <= 2'b00;
                        end else begin
                            // Not the 3rd cycle yet
                            cycle_cnt <= cycle_cnt + 1'b1;
                            if (w) begin
                                w_sum <= w_sum + 1'b1;
                            end else begin
                                w_sum <= w_sum;
                            end
                            z_reg <= 1'b0; // z is only 1 on the cycle AFTER the window
                        end
                    end
            endcase
        end
    end

    // The problem states: "If w=1 in exactly two... then set output z to 1 in the following clock cycle. Otherwise z has to be 0." 
    // This implies z should be 1 only for one cycle then go back to 0.
    // However, we also need to handle the "Otherwise z has to be 0" during the counting phase.
    // Based on the logic above, z_reg handles the single-cycle pulse after the 3rd cycle.
    // But we need to ensure z stays 0 during the other 3 cycles.
    // Let's refine: the z output is 1 on the cycle following the 3-cycle window if sum==2.
    
    // A small correction: the requirement "Otherwise z has to be 0" applies to the cycle where z could have been 1.
    // My logic: 
    // Cycle 1: cycle_cnt=0, w_sum updated, z_reg=0
    // Cycle 2: cycle_cnt=1, w_sum updated, z_reg=0
    // Cycle 3: cycle_cnt=2, w_sum/z_reg updated, z_reg becomes 1 if sum==2 (this happens at the end of Cycle 3)
    // Cycle 4 (next cycle): z_reg is 1, and we just started a new window (cycle_cnt=0)
    // But the reset of cycle_cnt and w_sum happens at the same time as z_reg update.
    // Let's re-verify timing: 
    // If we are in cycle 3, we update z_reg to 1. 
    // In the NEXT clock edge, z_reg will be 1. This is the "following clock cycle".
    // In that same clock edge, we also reset cycle_cnt to 0. 
    // So in the cycle where z=1, cycle_cnt=0, which is the start of the next window. Correct.

    // One detail: the spec says "z has to be 0" if the condition isn't met. 
    // In my logic, z_reg is 0 during the 3 counting cycles. 
    // And it is 1 only on the cycle following the window.
    
    // Let's add logic to clear z_reg after one cycle if it was set.
    // Actually, the current logic: if (cycle_cnt == 2) { z_reg <= (sum==2); cycle_cnt <= 0; } 
    // This means in the cycle where cycle_cnt is 0 (the start of the next window), z_reg is 1.
    // We need to make sure z_reg becomes 0 in the cycle after that.
    // But wait, if cycle_cnt is 0, it's the 1st cycle of the next window. 
    // In the next clock edge, the 'else' branch of 'if (cycle_cnt == 2)' will execute,
    // which contains 'z_reg <= 1'b0'. So z_reg will be 1 for exactly one cycle. 
    
    // Final adjustment to ensure z is 0 when not in the 'pulse' cycle.
    // In STATE_B, when cycle_cnt < 2, z_reg <= 0. 
    // When cycle_cnt == 2, z_reg <= (sum_condition).
    // In the next cycle, cycle_cnt will be 0, so z_reg will be set to 0.
    // This looks perfect.

    assign z = z_reg;

endmodule