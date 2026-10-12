`timescale 1ns/1ps
module tb_add_round_key;
  logic [127:0] state_i, key_i, state_o;
  int errors = 0;

  add_round_key dut (.state_i(state_i), .key_i(key_i), .state_o(state_o));

  task automatic check(input logic [127:0] s, input logic [127:0] k, input logic [127:0] exp);
    state_i = s; key_i = k;
    #10 if (state_o !== exp) begin
      $display("ERRO: %h ^ %h = %h (esperado %h)", s, k, state_o, exp);
      errors++;
    end
  endtask

  initial begin
    // FIPS-197 Apendice B, rodada 0: entrada ^ chave
    check(128'h3243f6a8885a308d313198a2e0370734,
          128'h2b7e151628aed2a6abf7158809cf4f3c,
          128'h193de3bea0f4e22b9ac68d2ae9f84808);
    check('0, '0, '0);
    check('1, '0, '1);
    check('1, '1, '0);
    if (errors == 0) $display("TEST PASSED");
    else             $fatal(1, "TEST FAILED: %0d erro(s)", errors);
    $finish;
  end
endmodule
