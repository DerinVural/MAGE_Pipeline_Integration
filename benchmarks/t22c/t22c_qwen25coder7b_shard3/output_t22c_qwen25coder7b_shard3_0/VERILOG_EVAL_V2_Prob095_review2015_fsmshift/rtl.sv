module TopModule (
    input  logic clk,
    input  logic reset,
    output logic shift_ena
);

// Counter to keep track of the number of cycles since reset
logic [2:0] counter;

// Initial block to set the initial values of the counter and shift_ena
initial begin
    counter = 3'd0;
    shift_ena = 1'b0;
end

// Sequential logic to count cycles and assert shift_ena
always @(posedge clk or posedge reset) begin
    if (reset) begin
        counter <= 3'd0;
        shift_ena <= 1'b1;
    end else begin
        if (counter < 3'd4) begin
            shift_ena <= 1'b1;
            counter <= counter + 1;
        end else begin
            shift_ena <= 1'b0;
        end
    end
end

endmodule