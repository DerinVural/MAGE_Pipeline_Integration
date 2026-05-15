module tb();
	typedef struct packed {
		int errors;
		int errortime;
		int errors_z;
		int errortime_z;
		int clocks;
	} stats;

	stats stats1;

	logic x;
	logic y;
	logic z;

	logic z_ref;

	// Instantiate the DUT
	TopModule dut (
		.x(x),
		.y(y),
		.z(z)
	);

	// Instantiate the golden module for reference
	RefModule golden (
		.x(x),
		.y(y),
		.z(z_ref)
	);

	// Timing for clock
	reg clk = 0;
	initial fork
	    begin
		forever #5 clk = ~clk;
	    end
	join_none

	// Error detection
	wire tb_match = ( { z } === ( { z } ^ { z_ref } ^ { z } ) );

	service_task(); // Define service task for timeouts

	// Queue-based error reporting
	localparam MAX_QUEUE_SIZE = 9;
	delayed_display(); // Define delayed display for error

	initial begin
	    stats1.clocks = 0;
	    stats1.errors = 0;
	    stats1.errors_z = 0;
	    stats1.errortime = 0;
	    stats1.errortime_z = 0;
	    @(posedge clk);
	    #1;
	    $finish();
	end

	// Monitor changes and check for mismatches
	event monitor_changes = @(posedge clk);

	service monitor_changes do
	    begin
		stats1.clocks++;
		if (!tb_match) begin
		    if (stats1.errors == 0) stats1.errortime = $time;
		    stats1.errors++;
		end
	    if (z_ref !== z_ref ^ z ^ z_ref) begin
		    if (stats1.errors_z == 0) stats1.errortime_z = $time;
		    stats1.errors_z++;
	    end
	end
	event on finish_sim;

	service on finish_sim do
	    begin
		if (stats1.errors_z == 0) begin
		    $display("SIMULATION PASSED");
		end else begin
		    $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_z, stats1.errortime_z);
		end
	    end

	    // Original initial timeout
	service after 1_000_000 do
	    begin
		$display("TIMEOUT");
		$finish();
	    end

	end
endmodule

// Additional required tasks and services
function delayed_display; // Placeholder for delayed display logic
endfunction

function service_task; // Placeholder for timeout handling
endfunction
