module stimulus_gen (input logic clk, output logic a, b, cin);

    logic [1:0] count;
    logic [1:0] count_mod;
    integer systemverilog_timeout;
    integer systemverilog_done;
    integer count_max;

    initial begin
        a = 0;
        b = 0;
        cin = 0;
        count = 0;
        count_mod = 0;
        systemverilog_timeout = 1000;
        count_max = 4;
        systemverilog_done = 0;
    end

    always_ff @(posedge clk) begin
        if (count < count_max) begin
            case (count)
                2'd0: {a, b, cin} <= 3'b000;
                2'd1: {a, b, cin} <= 3'b110;
                2'd2: {a, b, cin} <= 3'b011;
                2'd3: {a, b, cin} <= 3'b101;
                default: {a, b, cin} <= 3'b000;
            endcase
        end else begin
            count <= 0;
        end
        count <= count + 1;
    end

    initial begin
        repeat (count_max) @(negedge clk);
        $display("Test done");
        systemverilog_done = 1;
    end

endmodule