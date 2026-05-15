module TopModule(
    input logic clk,
    input logic load,
    input logic [511:0] data,
    output logic [511:0] q
);

    // Register to hold the current state of the cellular automaton
    logic [511:0] current_q;

    // Wire to hold the calculated next state (combinational result)
    logic [511:0] next_q;

    // Combinational logic for Rule 90 calculation
    always @* begin
        // Initialize next_q to zero (handles default state and boundary conditions implicitly if not overwritten)
        next_q = 512'h0;

        // Boundary condition i=0: q'[0] = q[-1] XOR q[1] = 0 XOR q[1] = q[1]
        next_q[0] = current_q[1];

        // Interior cells i=1 to i=510: q'[i] = q[i-1] XOR q[i+1]
        // We iterate explicitly to resolve the range selection errors reported by the tool.
        for (int i = 1; i <= 510; i = i + 1) begin
            // q[i-1] is the left neighbor
            // q[i+1] is the right neighbor
            next_q[i] = current_q[i-1] ^ current_q[i+1];
        end

        // Boundary condition i=511: q'[511] = q[510] XOR q[512] = q[510] XOR 0 = q[510]
        next_q[511] = current_q[510];
    end

    // Sequential logic: Update state on positive clock edge
    always @(posedge clk)
    begin
        if (load) begin
            // Load new data
            current_q <= data;
        end else begin
            // Apply cellular automaton rule (Update)
            current_q <= next_q;
        end
    end

    // Output assignment
    assign q = current_q;

endmodule