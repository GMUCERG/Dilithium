-- =====================================================================
-- Copyright © 2010-2012 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.sha3_pkg.all;
use work.keccak_pkg.all;
	
-- implementation of Keccak round: there are two basic architectures of Keccak function
-- Guido Bertoni implementation of Keccak round - streightforward
-- Marcin Rogawski implementation of Keccak round - based on C implementation 
-- Marcin Rogawski implementation is smaller and faster on Altera (Stratix II-IV, Cyclone II-IV)
-- and Xilinx (Virtex 4-6, Spartan 3 and 6)	devices than Guido Bertoni implementation
entity keccak_round is
port (
    rin     			: in std_logic_vector(KECCAK_STATE-1 downto 0);
    rc			   	 	: in std_logic_vector(63 downto 0);
    rout    			: out std_logic_vector(KECCAK_STATE-1 downto 0));
end keccak_round;

architecture gbertoni_round of keccak_round is

signal theta_in, theta_out, pi_in, pi_out, rho_in, rho_out, 
chi_in, chi_out, iota_in, iota_out, round_in, round_out : state;
signal sum_sheet: plane;
  
begin  

in_outer_gen : for i in 0 to 4 generate 
	in_inner_gen : for j in 0 to 4 generate 
	  round_in(i)(j) <= rin((1599 - 320*i - 64*j) downto (1536 - 320*i - 64*j));
	end generate;	
end generate;	

out_outer_gen : for i in 0 to 4 generate 
	out_inner_gen : for j in 0 to 4 generate 
	 rout((1599 - 320*i - 64*j) downto (1536 - 320*i - 64*j)) <=  round_out(i)(j);
	end generate;	
end generate;	
	
	theta_in<=round_in;
	pi_in<=rho_out;
	rho_in<=theta_out;
	chi_in<=pi_out;
	iota_in<=chi_out;
	round_out<=iota_out;



chi01_gen: for y in 0 to 4 generate
	chi02_gen: for x in 0 to 2 generate
		chi03_gen: for i in 0 to 63 generate
			chi_out(y)(x)(i)<=chi_in(y)(x)(i) xor  ( not(chi_in (y)(x+1)(i))and chi_in (y)(x+2)(i));
		end generate;	
	end generate;
end generate;

chi11_gen: for y in 0 to 4 generate
	chi12_gen: for i in 0 to 63 generate
		chi_out(y)(3)(i)<=chi_in(y)(3)(i) xor  ( not(chi_in (y)(4)(i))and chi_in (y)(0)(i));
	end generate;	
end generate;
	
chi21_gen: for y in 0 to 4 generate
	chi21_gen: for i in 0 to 63 generate
		chi_out(y)(4)(i)<=chi_in(y)(4)(i) xor  ( not(chi_in (y)(0)(i))and chi_in (y)(1)(i));		
	end generate;	
end generate;

theta01_gen: for x in 0 to 4 generate
	theta02_gen: for i in 0 to 63 generate
		sum_sheet(x)(i)<=theta_in(0)(x)(i) xor theta_in(1)(x)(i) xor theta_in(2)(x)(i) xor theta_in(3)(x)(i) xor theta_in(4)(x)(i);
	end generate;	
end generate;

theta11_gen: for y in 0 to 4 generate
	theta12_gen: for x in 1 to 3 generate
		theta_out(y)(x)(0)<=theta_in(y)(x)(0) xor sum_sheet(x-1)(0) xor sum_sheet(x+1)(63);
		theta13_gen: for i in 1 to 63 generate
			theta_out(y)(x)(i)<=theta_in(y)(x)(i) xor sum_sheet(x-1)(i) xor sum_sheet(x+1)(i-1);
		end generate;	
	end generate;
end generate;

theta21_gen: for y in 0 to 4 generate
	theta_out(y)(0)(0)<=theta_in(y)(0)(0) xor sum_sheet(4)(0) xor sum_sheet(1)(63);
	theta22_gen: for i in 1 to 63 generate
		theta_out(y)(0)(i)<=theta_in(y)(0)(i) xor sum_sheet(4)(i) xor sum_sheet(1)(i-1);
	end generate;	
end generate;

theta31_gen: for y in 0 to 4 generate
	theta_out(y)(4)(0)<=theta_in(y)(4)(0) xor sum_sheet(3)(0) xor sum_sheet(0)(63);
	theta32_gen: for i in 1 to 63 generate
		theta_out(y)(4)(i)<=theta_in(y)(4)(i) xor sum_sheet(3)(i) xor sum_sheet(0)(i-1);
	end generate;	
end generate;

pi01_gen: for y in 0 to 4 generate
	pi02_gen: for x in 0 to 4 generate
		pi03_gen: for i in 0 to 63 generate
			pi_out((2*x+3*y) mod 5)(0*x+1*y)(i)<=pi_in(y) (x)(i);
		end generate;	
	end generate;
end generate;

rho01_gen: for i in 0 to 63 generate
	rho_out(0)(0)(i)<=rho_in(0)(0)(i);
end generate;	

rho11_gen: for i in 0 to 63 generate
	rho_out(0)(1)(i)<=rho_in(0)(1)((i-1)mod 64);
end generate;

rho21_gen: for i in 0 to 63 generate
	rho_out(0)(2)(i)<=rho_in(0)(2)((i-62)mod 64);
end generate;

rho31_gen: for i in 0 to 63 generate
	rho_out(0)(3)(i)<=rho_in(0)(3)((i-28)mod 64);
end generate;

rho41_gen: for i in 0 to 63 generate
	rho_out(0)(4)(i)<=rho_in(0)(4)((i-27)mod 64);
end generate;

rho51_gen: for i in 0 to 63 generate
	rho_out(1)(0)(i)<=rho_in(1)(0)((i-36)mod 64);
end generate;	

rho61_gen: for i in 0 to 63 generate
	rho_out(1)(1)(i)<=rho_in(1)(1)((i-44)mod 64);
end generate;

rho71_gen: for i in 0 to 63 generate
	rho_out(1)(2)(i)<=rho_in(1)(2)((i-6)mod 64);
end generate;

rho81_gen: for i in 0 to 63 generate
	rho_out(1)(3)(i)<=rho_in(1)(3)((i-55)mod 64);
end generate;

rho91_gen: for i in 0 to 63 generate
	rho_out(1)(4)(i)<=rho_in(1)(4)((i-20)mod 64);
end generate;

rhoa1_gen: for i in 0 to 63 generate
	rho_out(2)(0)(i)<=rho_in(2)(0)((i-3)mod 64);
end generate;	

rhob1_gen: for i in 0 to 63 generate
	rho_out(2)(1)(i)<=rho_in(2)(1)((i-10)mod 64);
end generate;

rhoc1_gen: for i in 0 to 63 generate
	rho_out(2)(2)(i)<=rho_in(2)(2)((i-43)mod 64);
end generate;

rhod1_gen: for i in 0 to 63 generate
	rho_out(2)(3)(i)<=rho_in(2)(3)((i-25)mod 64);
end generate;

rhoe1_gen: for i in 0 to 63 generate
	rho_out(2)(4)(i)<=rho_in(2)(4)((i-39)mod 64);
end generate;

rhof1_gen: for i in 0 to 63 generate
	rho_out(3)(0)(i)<=rho_in(3)(0)((i-41)mod 64);
end generate;	

rhog1_gen: for i in 0 to 63 generate
	rho_out(3)(1)(i)<=rho_in(3)(1)((i-45)mod 64);
end generate;

rhoh1_gen: for i in 0 to 63 generate
	rho_out(3)(2)(i)<=rho_in(3)(2)((i-15)mod 64);
end generate;

rhoi1_gen: for i in 0 to 63 generate
	rho_out(3)(3)(i)<=rho_in(3)(3)((i-21)mod 64);
end generate;

rhoj1_gen: for i in 0 to 63 generate
	rho_out(3)(4)(i)<=rho_in(3)(4)((i-8)mod 64);
end generate;

rhok1_gen: for i in 0 to 63 generate
	rho_out(4)(0)(i)<=rho_in(4)(0)((i-18)mod 64);
end generate;	

rhol1_gen: for i in 0 to 63 generate
	rho_out(4)(1)(i)<=rho_in(4)(1)((i-2)mod 64);
end generate;

rhom1_gen: for i in 0 to 63 generate
	rho_out(4)(2)(i)<=rho_in(4)(2)((i-61)mod 64);
end generate;

rhon1_gen: for i in 0 to 63 generate
	rho_out(4)(3)(i)<=rho_in(4)(3)((i-56)mod 64);
end generate;

rhoo1_gen: for i in 0 to 63 generate
	rho_out(4)(4)(i)<=rho_in(4)(4)((i-14)mod 64);
end generate;

iota01_gen: for y in 1 to 4 generate
	iota02_gen: for x in 0 to 4 generate
		iota03_gen: for i in 0 to 63 generate
			iota_out(y)(x)(i)<=iota_in(y)(x)(i);
		end generate;	
	end generate;
end generate;


iota11_gen: for x in 1 to 4 generate
	iota12_gen: for i in 0 to 63 generate
		iota_out(0)(x)(i)<=iota_in(0)(x)(i);
	end generate;	
end generate;

iota21_gen: for i in 0 to 63 generate
	iota_out(0)(0)(i)<=iota_in(0)(0)(i) xor rc(i);
end generate;	

end gbertoni_round;

architecture mrogawski_round of keccak_round is 

signal Aba, Abe, Abi, Abo, Abu: std_logic_vector(63 downto 0); 
signal Aga, Age, Agi, Ago, Agu: std_logic_vector(63 downto 0); 
signal Aka, Ake, Aki, Ako, Aku: std_logic_vector(63 downto 0); 
signal Ama, Ame, Ami, Amo, Amu: std_logic_vector(63 downto 0); 
signal Asa, Ase, Asi, Aso, Asu: std_logic_vector(63 downto 0); 
signal Aba_wire, Abe_wire, Abi_wire, Abo_wire, Abu_wire: std_logic_vector(63 downto 0); 
signal Aga_wire, Age_wire, Agi_wire, Ago_wire, Agu_wire: std_logic_vector(63 downto 0); 
signal Aka_wire, Ake_wire, Aki_wire, Ako_wire, Aku_wire: std_logic_vector(63 downto 0); 
signal Ama_wire, Ame_wire, Ami_wire, Amo_wire, Amu_wire: std_logic_vector(63 downto 0); 
signal Asa_wire, Ase_wire, Asi_wire, Aso_wire, Asu_wire: std_logic_vector(63 downto 0); 
signal Bba, Bbe, Bbi, Bbo, Bbu: std_logic_vector(63 downto 0); 
signal Bga, Bge, Bgi, Bgo, Bgu: std_logic_vector(63 downto 0); 
signal Bka, Bke, Bki, Bko, Bku: std_logic_vector(63 downto 0); 
signal Bma, Bme, Bmi, Bmo, Bmu: std_logic_vector(63 downto 0); 
signal Bsa, Bse, Bsi, Bso, Bsu: std_logic_vector(63 downto 0); 
signal Ca, Ce, Ci, Co, Cu: std_logic_vector(63 downto 0); 
signal Da, De, Di, Do, Du: std_logic_vector(63 downto 0); 
signal Eba, Ebe, Ebi, Ebo, Ebu ,Eba_wire: std_logic_vector(63 downto 0); 
signal Ega, Ege, Egi, Ego, Egu: std_logic_vector(63 downto 0); 
signal Eka, Eke, Eki, Eko, Eku: std_logic_vector(63 downto 0); 
signal Ema, Eme, Emi, Emo, Emu: std_logic_vector(63 downto 0); 
signal Esa, Ese, Esi, Eso, Esu: std_logic_vector(63 downto 0); 

begin 
	
	Aba	<= rin(1599 downto 1536); 
	Abe	<= rin(1535 downto 1472); 
	Abi	<= rin(1471 downto 1408); 
	Abo	<= rin(1407 downto 1344); 
	Abu	<= rin(1343 downto 1280);
	Aga	<= rin(1279 downto 1216); 
	Age	<= rin(1215 downto 1152); 
	Agi	<= rin(1151 downto 1088); 
	Ago	<= rin(1087 downto 1024); 
	Agu	<= rin(1023 downto 960);
	Aka	<= rin(959 downto 896); 
	Ake	<= rin(895 downto 832); 
	Aki	<= rin(831 downto 768); 
	Ako	<= rin(767 downto 704); 
	Aku	<= rin(703 downto 640);
	Ama	<= rin(639 downto 576); 
	Ame	<= rin(575 downto 512); 
	Ami	<= rin(511 downto 448); 
	Amo	<= rin(447 downto 384); 
	Amu	<= rin(383 downto 320);
	Asa	<= rin(319 downto 256); 
	Ase	<= rin(255 downto 192); 
	Asi	<= rin(191 downto 128); 
	Aso	<= rin(127 downto 64); 
	Asu	<= rin(63 downto 0); 
 	
	Ca <= Aba xor Aga xor Aka xor Ama xor Asa; 
	Ce <= Abe xor Age xor Ake xor Ame xor Ase; 
	Ci <= Abi xor Agi xor Aki xor Ami xor Asi; 
	Co <= Abo xor Ago xor Ako xor Amo xor Aso; 
	Cu <= Abu xor Agu xor Aku xor Amu xor Asu; 
	
	
	Da <= Cu xor rolx(Ce, 1); 
	De <= Ca xor rolx(Ci, 1); 
	Di <= Ce xor rolx(Co, 1); 
	Do <= Ci xor rolx(Cu, 1); 
	Du <= Co xor rolx(Ca, 1); 
	
	Aba_wire <= Aba xor Da;
	Bba <= Aba_wire; 

	Age_wire <= Age xor De; 
	Bbe <= rolx(Age_wire, 44); 
	Aki_wire <= Aki xor Di; 
	Bbi <= rolx(Aki_wire, 43); 
	Eba_wire <=  Bba  xor ((not Bbe) and Bbi); 
	Eba <= Eba_wire xor rc; 
	Amo_wire <= Amo xor Do; 
	Bbo <= rolx(Amo_wire, 21); 
	Ebe <= Bbe xor ((not Bbi) and Bbo); 
	Asu_wire <= Asu xor Du; 
	Bbu <= rolx(Asu_wire, 14); 
	Ebi <= Bbi xor ((not Bbo) and Bbu); 
	Ebo <= Bbo xor ((not Bbu) and Bba); 
	Ebu <= Bbu xor ((not Bba) and Bbe); 
	Abo_wire <= Abo xor Do; 
	Bga <= rolx(Abo_wire, 28); 
	Agu_wire <= Agu xor Du; 
	Bge <= rolx(Agu_wire, 20); 
	Aka_wire <= Aka xor Da; 
	Bgi <= rolx(Aka_wire, 3); 
	Ega <=  Bga  xor ((not Bge)and Bgi); 
	Ame_wire <= Ame xor De; 
	Bgo <= rolx(Ame_wire, 45); 
	Ege <= Bge xor ((not Bgi)and Bgo);
	Asi_wire <= Asi  xor Di; 
	Bgu <= rolx(Asi_wire, 61); 
	Egi <= Bgi xor ((not Bgo)and Bgu); 
	Ego <= Bgo xor ((not Bgu)and Bga); 
	Egu <= Bgu xor ((not Bga)and Bge); 
	Abe_wire <= Abe xor De; 
	Bka <= rolx(Abe_wire, 1); 
	Agi_wire <=  Agi xor Di; 
	Bke <= rolx(Agi_wire, 6); 
	Ako_wire <= Ako xor Do; 
	Bki <= rolx(Ako_wire, 25); 
	Eka <= Bka  xor ((not Bke)and Bki); 
	Amu_wire <=  Amu xor Du; 
	Bko <= rolx(Amu_wire, 8); 
	Eke <= Bke xor ((not Bki) and Bko); 
	Asa_wire <= Asa xor Da; 
	Bku <= rolx(Asa_wire, 18); 
	Eki <= Bki xor ((not Bko)and Bku); 
	Eko <= Bko xor ((not Bku)and Bka); 
	Eku <= Bku xor ((not Bka)and Bke); 
	Abu_wire <= Abu xor Du; 
	Bma <= rolx(Abu_wire, 27); 
	Aga_wire <= Aga xor Da; 
	Bme <= rolx(Aga_wire, 36); 
	Ake_wire <= Ake xor De; 
	Bmi <= rolx(Ake_wire, 10); 
	Ema <= Bma  xor ((not Bme)and Bmi); 
	Ami_wire <= Ami xor Di; 
	Bmo <= rolx(Ami_wire, 15); 
	Eme <=  Bme xor ((not Bmi)and Bmo); 
	Aso_wire <=  Aso xor Do; 
	Bmu <= rolx(Aso_wire, 56); 
	Emi <= Bmi xor ((not Bmo)and Bmu); 
	Emo <= Bmo xor ((not Bmu)and Bma); 
	Emu <= Bmu xor ((not Bma)and Bme); 
	Abi_wire <= Abi xor Di; 
	Bsa <= rolx(Abi_wire, 62); 
	Ago_wire <= Ago xor Do; 
	Bse <= rolx(Ago_wire, 55); 
	Aku_wire <= Aku xor Du; 
	Bsi <= rolx(Aku_wire, 39); 
	Esa <= Bsa xor ((not Bse)and Bsi); 
	Ama_wire <= Ama xor Da; 
	Bso <= rolx(Ama_wire, 41); 
	Ese <=  Bse xor ((not Bsi)and Bso); 
	Ase_wire <= Ase xor De; 
	Bsu <= rolx(Ase_wire, 2); 
	Esi <= Bsi  xor ((not Bso) and Bsu); 
	Eso <= Bso  xor ((not Bsu)and Bsa); 
	Esu <= Bsu  xor ((not Bsa)and Bse);    
	
	rout(1599 downto 1536) <= Eba; 
	rout(1535 downto 1472) <= Ebe; 
	rout(1471 downto 1408) <= Ebi; 
	rout(1407 downto 1344)<= Ebo; 
	rout(1343 downto 1280)<= Ebu;
	rout(1279 downto 1216)<= Ega; 
	rout(1215 downto 1152)<= Ege; 
	rout(1151 downto 1088)<= Egi; 
	rout(1087 downto 1024)<= Ego; 
	rout(1023 downto 960)<= Egu;
	rout(959 downto 896)<= Eka; 
	rout(895 downto 832)<= Eke; 
	rout(831 downto 768)<= Eki; 
	rout(767 downto 704)<= Eko; 
	rout(703 downto 640)<= Eku;
	rout(639 downto 576)<= Ema; 
	rout(575 downto 512)<= Eme; 
	rout(511 downto 448)<= Emi; 
	rout(447 downto 384)<= Emo; 
	rout(383 downto 320)<= Emu;
	rout(319 downto 256)<= Esa; 
	rout(255 downto 192)<= Ese; 
	rout(191 downto 128)<= Esi; 
	rout(127 downto 64)<= Eso; 
	rout(63 downto 0)<= Esu; 
	
	
end;	   


