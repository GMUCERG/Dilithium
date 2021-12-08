/*
 * From our research paper "High-Performance Hardware Implementation of CRYSTALS-Dilithium"
 * by Luke Beckwith, Duc Tri Nguyen, Kris Gaj
 * at George Mason University, USA
 * https://eprint.iacr.org/2021/1451.pdf
 * =============================================================================
 * Copyright (c) 2021 by Cryptographic Engineering Research Group (CERG)
 * ECE Department, George Mason University
 * Fairfax, VA, U.S.A.
 * Author: Luke Beckwith
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * =============================================================================
 * @author   Luke Beckwith <lbeckwit@gmu.edu>
 */


module DecoupledStage(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [23:0] io_in_bits_ul,
  input  [23:0] io_in_bits_quo,
  input         io_out_ready,
  output        io_out_valid,
  output [23:0] io_out_bits_ul,
  output [23:0] io_out_bits_quo
);
  reg  valid;  
  reg [23:0] reg_ul;  
  reg [23:0] reg_quo;  
  wire  _T = io_in_ready & io_in_valid;  
  wire  _GEN_0 = io_out_ready ? 1'h0 : valid;  
  wire  _GEN_3 = _T | _GEN_0;  
  assign io_in_ready = ~valid | io_out_ready;  
  assign io_out_valid = valid;  
  assign io_out_bits_ul = reg_ul;  
  assign io_out_bits_quo = reg_quo;  
  always @(posedge clock) begin
    if (reset) begin  
      valid <= 1'h0;  
    end else begin
      valid <= _GEN_3;
    end
    if (_T) begin  
      reg_ul <= io_in_bits_ul;  
    end
    if (_T) begin  
      reg_quo <= io_in_bits_quo;  
    end
  end
initial begin
end  
endmodule
module DecoupledStage_1(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [23:0] io_in_bits_ul,
  input  [23:0] io_in_bits_quo,
  input  [23:0] io_in_bits_quo_times_Q,
  input         io_out_ready,
  output        io_out_valid,
  output [23:0] io_out_bits_ul,
  output [23:0] io_out_bits_quo,
  output [23:0] io_out_bits_quo_times_Q
);
  reg  valid;  
  reg [23:0] reg_ul;  
  reg [23:0] reg_quo;  
  reg [23:0] reg_quo_times_Q;  
  wire  _T = io_in_ready & io_in_valid;  
  wire  _GEN_0 = io_out_ready ? 1'h0 : valid;  
  wire  _GEN_4 = _T | _GEN_0;  
  assign io_in_ready = ~valid | io_out_ready;  
  assign io_out_valid = valid;  
  assign io_out_bits_ul = reg_ul;  
  assign io_out_bits_quo = reg_quo;  
  assign io_out_bits_quo_times_Q = reg_quo_times_Q;  
  always @(posedge clock) begin
    if (reset) begin  
      valid <= 1'h0;  
    end else begin
      valid <= _GEN_4;
    end
    if (_T) begin  
      reg_ul <= io_in_bits_ul;  
    end
    if (_T) begin  
      reg_quo <= io_in_bits_quo;  
    end
    if (_T) begin  
      reg_quo_times_Q <= io_in_bits_quo_times_Q;  
    end
  end
initial begin
end  
endmodule
module DecoupledStage_2(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [22:0] io_in_bits_remainder,
  input  [23:0] io_in_bits_quotient,
  input         io_out_ready,
  output        io_out_valid,
  output [22:0] io_out_bits_remainder,
  output [23:0] io_out_bits_quotient
);
  reg  valid;  
  reg [22:0] reg_remainder;  
  reg [23:0] reg_quotient;  
  wire  _T = io_in_ready & io_in_valid;  
  wire  _GEN_0 = io_out_ready ? 1'h0 : valid;  
  wire  _GEN_3 = _T | _GEN_0;  
  assign io_in_ready = ~valid | io_out_ready;  
  assign io_out_valid = valid;  
  assign io_out_bits_remainder = reg_remainder;  
  assign io_out_bits_quotient = reg_quotient;  
  always @(posedge clock) begin
    if (reset) begin  
      valid <= 1'h0;  
    end else begin
      valid <= _GEN_3;
    end
    if (_T) begin  
      reg_remainder <= io_in_bits_remainder;  
    end
    if (_T) begin  
      reg_quotient <= io_in_bits_quotient;  
    end
  end
initial begin
end  
endmodule
module Barrett(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [45:0] io_in_bits,
  input         io_out_ready,
  output        io_out_valid,
  output [22:0] io_out_bits_remainder,
  output [23:0] io_out_bits_quotient
);
  wire  stg0_clock;  
  wire  stg0_reset;  
  wire  stg0_io_in_ready;  
  wire  stg0_io_in_valid;  
  wire [23:0] stg0_io_in_bits_ul;  
  wire [23:0] stg0_io_in_bits_quo;  
  wire  stg0_io_out_ready;  
  wire  stg0_io_out_valid;  
  wire [23:0] stg0_io_out_bits_ul;  
  wire [23:0] stg0_io_out_bits_quo;  
  wire  stg1_clock;  
  wire  stg1_reset;  
  wire  stg1_io_in_ready;  
  wire  stg1_io_in_valid;  
  wire [23:0] stg1_io_in_bits_ul;  
  wire [23:0] stg1_io_in_bits_quo;  
  wire [23:0] stg1_io_in_bits_quo_times_Q;  
  wire  stg1_io_out_ready;  
  wire  stg1_io_out_valid;  
  wire [23:0] stg1_io_out_bits_ul;  
  wire [23:0] stg1_io_out_bits_quo;  
  wire [23:0] stg1_io_out_bits_quo_times_Q;  
  wire  stg2_clock;  
  wire  stg2_reset;  
  wire  stg2_io_in_ready;  
  wire  stg2_io_in_valid;  
  wire [22:0] stg2_io_in_bits_remainder;  
  wire [23:0] stg2_io_in_bits_quotient;  
  wire  stg2_io_out_ready;  
  wire  stg2_io_out_valid;  
  wire [22:0] stg2_io_out_bits_remainder;  
  wire [23:0] stg2_io_out_bits_quotient;  
  wire [23:0] mult8396807Adder7ShiftedNode1Left0 = io_in_bits[45:22];  
  wire [26:0] _stg0_io_in_bits_quo_adderHiBits_T = {mult8396807Adder7ShiftedNode1Left0,3'h0};  
  wire [27:0] _stg0_io_in_bits_quo_adderHiBits_T_2 = {{1'd0}, _stg0_io_in_bits_quo_adderHiBits_T};  
  wire [27:0] _GEN_0 = {{4'd0}, mult8396807Adder7ShiftedNode1Left0};  
  wire [27:0] stg0_io_in_bits_quo_mult8396807Adder7HighBits = _stg0_io_in_bits_quo_adderHiBits_T_2 - _GEN_0;  
  wire [34:0] _stg0_io_in_bits_quo_adderHiBits_T_4 = {{11'd0}, mult8396807Adder7ShiftedNode1Left0};  
  wire [33:0] stg0_io_in_bits_quo_adderHiBits_mult8396807Adder8396807ShiftedNode1Left10 = {
    mult8396807Adder7ShiftedNode1Left0,10'h0};  
  wire [34:0] _GEN_1 = {{1'd0}, stg0_io_in_bits_quo_adderHiBits_mult8396807Adder8396807ShiftedNode1Left10};  
  wire [34:0] _stg0_io_in_bits_quo_adderHiBits_T_6 = _stg0_io_in_bits_quo_adderHiBits_T_4 + _GEN_1;  
  wire [23:0] stg0_io_in_bits_quo_adderHiBits_mult8396807Adder8396807ShiftedNode7Right13 = {{9'd0},
    stg0_io_in_bits_quo_mult8396807Adder7HighBits[27:13]};  
  wire [34:0] _GEN_2 = {{11'd0}, stg0_io_in_bits_quo_adderHiBits_mult8396807Adder8396807ShiftedNode7Right13};  
  wire [34:0] stg0_io_in_bits_quo_mult8396807Adder8396807HighBits = _stg0_io_in_bits_quo_adderHiBits_T_6 + _GEN_2;  
  wire [47:0] stg0_io_in_bits_quo_out_1 = {stg0_io_in_bits_quo_mult8396807Adder8396807HighBits,
    stg0_io_in_bits_quo_mult8396807Adder7HighBits[12:0]};  
  wire [33:0] _stg1_io_in_bits_quo_times_Q_adderHiBits_T = {stg0_io_out_bits_quo,10'h0};  
  wire [34:0] _stg1_io_in_bits_quo_times_Q_adderHiBits_T_2 = {{1'd0}, _stg1_io_in_bits_quo_times_Q_adderHiBits_T};  
  wire [34:0] _GEN_3 = {{11'd0}, stg0_io_out_bits_quo};  
  wire [34:0] _stg1_io_in_bits_quo_times_Q_adderHiBits_T_4 = _stg1_io_in_bits_quo_times_Q_adderHiBits_T_2 - _GEN_3;  
  wire [23:0] stg1_io_in_bits_quo_times_Q_adderHiBits_mult8380417Adder8380417ShiftedNode1Right13 = {{13'd0},
    stg0_io_out_bits_quo[23:13]};  
  wire [34:0] _GEN_4 = {{11'd0}, stg1_io_in_bits_quo_times_Q_adderHiBits_mult8380417Adder8380417ShiftedNode1Right13};  
  wire [34:0] stg1_io_in_bits_quo_times_Q_mult8380417Adder8380417HighBits = _stg1_io_in_bits_quo_times_Q_adderHiBits_T_4
     + _GEN_4;  
  wire [47:0] stg1_io_in_bits_quo_times_Q_out = {stg1_io_in_bits_quo_times_Q_mult8380417Adder8380417HighBits,
    stg0_io_out_bits_quo[12:0]};  
  wire [23:0] rem = stg1_io_out_bits_ul - stg1_io_out_bits_quo_times_Q;  
  wire [23:0] remMinusQ = rem - 24'h7fe001;  
  wire [23:0] _stg2_io_in_bits_remainder_T = rem - 24'h7fe001;  
  wire [23:0] _stg2_io_in_bits_remainder_T_3 = _stg2_io_in_bits_remainder_T[23] ? rem : remMinusQ;  
  wire [23:0] _stg2_io_in_bits_quotient_T_4 = stg1_io_out_bits_quo + 24'h1;  
  DecoupledStage stg0 (  
    .clock(stg0_clock),
    .reset(stg0_reset),
    .io_in_ready(stg0_io_in_ready),
    .io_in_valid(stg0_io_in_valid),
    .io_in_bits_ul(stg0_io_in_bits_ul),
    .io_in_bits_quo(stg0_io_in_bits_quo),
    .io_out_ready(stg0_io_out_ready),
    .io_out_valid(stg0_io_out_valid),
    .io_out_bits_ul(stg0_io_out_bits_ul),
    .io_out_bits_quo(stg0_io_out_bits_quo)
  );
  DecoupledStage_1 stg1 (  
    .clock(stg1_clock),
    .reset(stg1_reset),
    .io_in_ready(stg1_io_in_ready),
    .io_in_valid(stg1_io_in_valid),
    .io_in_bits_ul(stg1_io_in_bits_ul),
    .io_in_bits_quo(stg1_io_in_bits_quo),
    .io_in_bits_quo_times_Q(stg1_io_in_bits_quo_times_Q),
    .io_out_ready(stg1_io_out_ready),
    .io_out_valid(stg1_io_out_valid),
    .io_out_bits_ul(stg1_io_out_bits_ul),
    .io_out_bits_quo(stg1_io_out_bits_quo),
    .io_out_bits_quo_times_Q(stg1_io_out_bits_quo_times_Q)
  );
  DecoupledStage_2 stg2 (  
    .clock(stg2_clock),
    .reset(stg2_reset),
    .io_in_ready(stg2_io_in_ready),
    .io_in_valid(stg2_io_in_valid),
    .io_in_bits_remainder(stg2_io_in_bits_remainder),
    .io_in_bits_quotient(stg2_io_in_bits_quotient),
    .io_out_ready(stg2_io_out_ready),
    .io_out_valid(stg2_io_out_valid),
    .io_out_bits_remainder(stg2_io_out_bits_remainder),
    .io_out_bits_quotient(stg2_io_out_bits_quotient)
  );
  assign io_in_ready = stg0_io_in_ready;  
  assign io_out_valid = stg2_io_out_valid;  
  assign io_out_bits_remainder = stg2_io_out_bits_remainder;  
  assign io_out_bits_quotient = stg2_io_out_bits_quotient;  
  assign stg0_clock = clock;
  assign stg0_reset = reset;
  assign stg0_io_in_valid = io_in_valid;  
  assign stg0_io_in_bits_ul = io_in_bits[23:0];  
  assign stg0_io_in_bits_quo = stg0_io_in_bits_quo_out_1[47:24];  
  assign stg0_io_out_ready = stg1_io_in_ready;  
  assign stg1_clock = clock;
  assign stg1_reset = reset;
  assign stg1_io_in_valid = stg0_io_out_valid;  
  assign stg1_io_in_bits_ul = stg0_io_out_bits_ul;  
  assign stg1_io_in_bits_quo = stg0_io_out_bits_quo;  
  assign stg1_io_in_bits_quo_times_Q = stg1_io_in_bits_quo_times_Q_out[23:0];  
  assign stg1_io_out_ready = stg2_io_in_ready;  
  assign stg2_clock = clock;
  assign stg2_reset = reset;
  assign stg2_io_in_valid = stg1_io_out_valid;  
  assign stg2_io_in_bits_remainder = _stg2_io_in_bits_remainder_T_3[22:0];  
  assign stg2_io_in_bits_quotient = _stg2_io_in_bits_remainder_T[23] ? stg1_io_out_bits_quo :
    _stg2_io_in_bits_quotient_T_4;  
  assign stg2_io_out_ready = io_out_ready;  
endmodule
