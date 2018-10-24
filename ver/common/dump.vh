
`ifndef DUMPLFO
`ifndef KEYON_TEST
`ifndef SSG_TEST

initial begin
`ifdef DUMPSIGNALS
	`ifdef NCVERILOG
		$shm_open("jt12_test.shm");
//		$shm_probe(jt12_test,"AS");
		$shm_probe(jt12_test.uut,"AS");
//        $shm_probe(jt12_test.u_testdata,"A");
        `ifdef POSTPROC
        	$shm_probe(jt12_test.speaker_left);
        `endif
	`else
		$dumpfile("jt12_test.lxt");
		// $dumpvars( 1, jt12_test.uut );
		$dumpvars;
		$dumpon;
	`endif
`endif
end

`endif
`endif
`endif

`ifdef KEYON_TEST
initial begin
	$dumpfile("jt12_test.lxt");
	$dumpvars(1, jt12_test.uut.u_op );
	$dumpvars(1, jt12_test.uut.u_eg );
	$dumpvars(1, jt12_test.uut.u_mmr.u_reg.u_kon );
	$dumpon;
end
`endif

`ifdef DUMPLFO
initial begin
	$dumpfile("jt12_test.lxt");
	$dumpvars(0, jt12_test.uut.u_lfo );
	$dumpon;
end
`endif

`ifdef SSG_TEST
initial begin
	`ifdef NCVERILOG
		$shm_open("ssg.shm");
		$shm_probe(jt12_test,"AS"); // gets everything
		$shm_probe(jt12_test.uut.u_op,"A");
        $shm_probe(jt12_test.uut.u_eg,"A");
        $shm_probe(jt12_test.uut.u_mmr.ssg_ch2s4);
        `ifdef POSTPROC
	        $shm_probe(jt12_test.speaker_left);
	        //$shm_probe(jt12_test.filter_left);
        `endif
    `else
		$dumpfile("ssg.lxt");
		$dumpvars(1, jt12_test.uut.u_op );
		$dumpvars(1, jt12_test.uut.u_eg );
		$dumpvars(1, jt12_test.uut.u_mmr.ssg_ch2s4 );
        $dumpvars(1, jt12_test.speaker_left );
		$dumpon;
    `endif
end
`endif


/*

$shm_probe

A: all nodes, including inputs, outputs and inouts, of the specified scope
S: inputs, outputs and inouts of the specified scope, and in all instantiations
below it, except inside library cells.
C: inputs, outputs and inouts of the specifed scope, and in all instantiations
below it, including those inside library cells.
AS: all nodes, including inputs, outputs and inouts, of the specified scope, and
in all instantiations below it, except inside library cells.
AC: all nodes, including inputs outputs and inouts, in the specified scope and
in all instantiations below it, even inside library cells.

*/
