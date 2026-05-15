module TopModule (
    input  logic cpu_overheated,
    output logic shut_off_computer,
    input  logic arrived,
    input  logic gas_tank_empty,
    output logic keep_driving
);

    // Combinational logic for shut_off_computer
    // Fix: Ensure the signal is assigned in all cases to avoid latches
    always @(*) begin
        if (cpu_overheated) begin
            shut_off_computer = 1'b1;
        end else begin
            shut_off_computer = 1'b0;
        end
    end

    // Combinational logic for keep_driving
    // Fix: Ensure the signal is assigned in all cases to avoid latches
    always @(*) begin
        if (~arrived) begin
            keep_driving = ~gas_tank_empty;
        end else begin
            keep_driving = 1'b0;
        end
    end

endmodule