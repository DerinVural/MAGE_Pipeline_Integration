module TopModule(input logic [5:0] y, input w, output logic Y2, output logic Y4);

    assign Y2 = y[1] | y[3];
    assign Y4 = y[3] | y[4] | y[5];

endmodule