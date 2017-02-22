initial begin
`ifdef DUMPSIGNALS
	`ifdef NCVERILOG
		$shm_open("jt12_test.shm");
		$shm_probe(jt12_test,"AS");
	`else
		$dumpfile("jt12_test.lxt");
		$dumpvars();
		$dumpon;
	`endif
`endif
end
