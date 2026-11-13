`timescale 1ns/1ps
// TB semana 4: key_exp contra a FIPS-197 (apendice A.1 e chave 10 do C.1).
// Tambem confere que ready_o sobe 11 ciclos depois do start.
module tb_minisoc_aes_key_exp;

  logic         clk = 0, rst_n = 0, start = 0, ready;
  logic [127:0] key, rk;
  logic [3:0]   rnd = 0;
  int errors = 0;

  always #5 clk = ~clk;

  minisoc_aes_key_exp dut (
    .clk(clk), .rst_n(rst_n), .start_i(start), .key_i(key),
    .rnd_i(rnd), .rk_o(rk), .ready_o(ready)
  );

  logic [127:0] keys_a1 [11] = '{
    128'h2b7e151628aed2a6abf7158809cf4f3c,
    128'ha0fafe1788542cb123a339392a6c7605,
    128'hf2c295f27a96b9435935807a7359f67f,
    128'h3d80477d4716fe3e1e237e446d7a883b,
    128'hef44a541a8525b7fb671253bdb0bad00,
    128'hd4d1c6f87c839d87caf2b8bc11f915bc,
    128'h6d88a37a110b3efddbf98641ca0093fd,
    128'h4e54f70e5f5fc9f384a64fb24ea6dc4f,
    128'head27321b58dbad2312bf5607f8d292f,
    128'hac7766f319fadc2128d12941575c006e,
    128'hd014f9a8c9ee2589e13f0cc8b6630ca6
  };

  task automatic check(string what, logic [127:0] got, logic [127:0] exp);
    if (got !== exp) begin
      $display("ERRO %s: %h (esperado %h)", what, got, exp);
      errors++;
    end
  endtask

  task automatic expand(logic [127:0] k);
    int cycles = 0;
    @(negedge clk); key = k; start = 1;
    @(negedge clk); start = 0;
    while (!ready) begin
      @(negedge clk);
      cycles++;
    end
    if (cycles != 10) begin
      $display("ERRO latencia: ready em %0d ciclos (esperado 11)", cycles + 1);
      errors++;
    end
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;

    expand(keys_a1[0]);
    for (int r = 0; r <= 10; r++) begin
      rnd = r[3:0];
      #1 check($sformatf("A.1 chave %0d", r), rk, keys_a1[r]);
    end

    expand(128'h000102030405060708090a0b0c0d0e0f);
    rnd = 10;
    #1 check("C.1 chave 10", rk, 128'h13111d7fe3944a17f307a78b4d2b30c5);

    if (errors == 0) $display("TEST PASSED");
    else             $fatal(1, "TEST FAILED: %0d erro(s)", errors);
    $finish;
  end

endmodule
