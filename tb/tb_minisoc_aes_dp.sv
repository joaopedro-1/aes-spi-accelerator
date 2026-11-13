`timescale 1ns/1ps
// TB semana 4: key_exp + dp juntos.
// Apendice B rodada a rodada, apendice C.1 nos dois sentidos e 50 casos aleatorios
// de decifra(cifra(x)) == x.
module tb_minisoc_aes_dp;

  logic         clk = 0, rst_n = 0;
  logic         key_start = 0, key_ready;
  logic         start = 0, decrypt = 0, busy, done;
  logic [127:0] key, block_in, block_out, rk;
  logic [3:0]   rnd;
  int errors = 0;

  always #5 clk = ~clk;

  minisoc_aes_key_exp u_key_exp (
    .clk(clk), .rst_n(rst_n), .start_i(key_start), .key_i(key),
    .rnd_i(rnd), .rk_o(rk), .ready_o(key_ready)
  );

  minisoc_aes_dp dut (
    .clk(clk), .rst_n(rst_n), .start_i(start), .decrypt_i(decrypt),
    .block_i(block_in), .rk_i(rk), .rnd_o(rnd),
    .block_o(block_out), .busy_o(busy), .done_o(done)
  );

  // apendice B: start of round 2..10 e saida
  logic [127:0] start_of_round [10] = '{
    128'ha49c7ff2689f352b6b5bea43026a5049,
    128'haa8f5f0361dde3ef82d24ad26832469a,
    128'h486c4eee671d9d0d4de3b138d65f58e7,
    128'he0927fe8c86363c0d9b1355085b8be01,
    128'hf1006f55c1924cef7cc88b325db5d50c,
    128'h260e2e173d41b77de86472a9fdd28b25,
    128'h5a4142b11949dc1fa3e019657a8c040c,
    128'hea835cf00445332d655d98ad8596b0c5,
    128'heb40f21e592e38848ba113e71bc342d2,
    128'h3925841d02dc09fbdc118597196a0b32
  };

  task automatic check(string what, logic [127:0] got, logic [127:0] exp);
    if (got !== exp) begin
      $display("ERRO %s: %h (esperado %h)", what, got, exp);
      errors++;
    end
  endtask

  task automatic load_key(logic [127:0] k);
    @(negedge clk); key = k; key_start = 1;
    @(negedge clk); key_start = 0;
    wait (key_ready);
  endtask

  // roda um bloco e confere a latencia (11 ciclos)
  task automatic run(logic dec, logic [127:0] din, output logic [127:0] dout);
    int cycles = 0;
    @(negedge clk); decrypt = dec; block_in = din; start = 1;
    @(negedge clk); start = 0;
    while (!done) begin
      @(negedge clk);
      cycles++;
    end
    if (cycles != 10) begin
      $display("ERRO latencia: %0d ciclos (esperado 11)", cycles + 1);
      errors++;
    end
    dout = block_out;
  endtask

  logic [127:0] res, ct, k, pt;

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;

    // apendice B rodada a rodada
    load_key(128'h2b7e151628aed2a6abf7158809cf4f3c);
    @(negedge clk); decrypt = 0; block_in = 128'h3243f6a8885a308d313198a2e0370734; start = 1;
    @(negedge clk); start = 0;
    check("B rodada 0", block_out, 128'h193de3bea0f4e22b9ac68d2ae9f84808);
    for (int r = 0; r < 10; r++) begin
      @(negedge clk);
      check($sformatf("B rodada %0d", r + 1), block_out, start_of_round[r]);
    end
    if (!done) begin
      $display("ERRO: done_o nao pulsou no fim da rodada 10");
      errors++;
    end

    // decifra do B
    run(1, 128'h3925841d02dc09fbdc118597196a0b32, res);
    check("B decifra", res, 128'h3243f6a8885a308d313198a2e0370734);

    // apendice C.1
    load_key(128'h000102030405060708090a0b0c0d0e0f);
    run(0, 128'h00112233445566778899aabbccddeeff, res);
    check("C.1 cifra", res, 128'h69c4e0d86a7b0430d8cdb78070b4c55a);
    run(1, 128'h69c4e0d86a7b0430d8cdb78070b4c55a, res);
    check("C.1 decifra", res, 128'h00112233445566778899aabbccddeeff);

    // aleatorios
    for (int i = 0; i < 50; i++) begin
      k  = {$urandom, $urandom, $urandom, $urandom};
      pt = {$urandom, $urandom, $urandom, $urandom};
      load_key(k);
      run(0, pt, ct);
      run(1, ct, res);
      check($sformatf("aleatorio %0d", i), res, pt);
    end

    if (errors == 0) $display("TEST PASSED");
    else             $fatal(1, "TEST FAILED: %0d erro(s)", errors);
    $finish;
  end

endmodule
