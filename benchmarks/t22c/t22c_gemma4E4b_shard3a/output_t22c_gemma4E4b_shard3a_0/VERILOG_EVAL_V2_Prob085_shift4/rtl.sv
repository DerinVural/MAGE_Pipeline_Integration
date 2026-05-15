module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic load,
    input  logic ena,
    input  logic [3:0] data,
    output logic [3:0] q
);

    // Internal storage for the shift register
    logic [3:0] shift_register;

    // Initialize the register to a known state (e.g., zero)
    initial begin
        shift_register = 4'b0000;
    end

    // Synchronous sequential logic triggered on positive clock edge
    always @(posedge clk)
    begin
        // (1) Asynchronous Reset (Active High)
        if (areset)
        begin
            shift_register <= 4'b0000; // Reset to zero
        end
        // Non-reset logic
        else if (load)
        begin
            // (2) Load has higher priority than shift
            shift_register <= data;
        end
        else if (ena)
        begin
            // (3) Shift Right
            // Q[3] becomes 0 (MSB filled with 0),
            // Q[2] takes Q[3], Q[1] takes Q[2], Q[0] takes Q[1].
            // New value = {1'b0, shift_register[3:1]}
            shift_register <= {1'b0, shift_register[3:1]};
        end
        // (4) Hold state if neither load nor ena is asserted
        else
        begin
            shift_register <= shift_register;
        end
    end

    // Output assignment
    assign q = shift_register;

endmodule