module TopModule(
    input logic [2:0] in,
    output logic [1:0] out
);

    // Logic to count the number of 1's in the input
    logic [1:0] count;
    always_comb begin
        count = 2'b00;
        count = (count + in[2]) & (count + in[1]) & (count + in[0]);
    end

    // Assign the count to the output
    assign out = count;

endmodule