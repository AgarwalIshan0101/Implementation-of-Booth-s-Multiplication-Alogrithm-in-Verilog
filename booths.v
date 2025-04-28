// Implementing Booth's Algorithm for Multiplication 
// It requires less of storing for partial addition 
// if 00 or 11 occurs we will shift 
// if 01 occurs we will add and shift 
// if 10 occurs we will subtract and shift 
// clk : clock 
// Defining the register used for data path 

// Defining shiftregister 

module  shiftregister(data_out , data_in, s_in, clk , ld , clr , sft);
input  s_in,clk,ld,clr,sft;// s_in : serial in , ld : load , sft : shift 
input [15:0] data_in;
output reg [15:0] data_out;

always @(posedge clk)
begin
  if (clr) data_out <= 0;
  else if (ld) data_out <= data_in;
  else if (sft) data_out <= {s_in,data_out[15:1]};
end
endmodule

// defining parallel in parallel out register 

module  PIPO(data_out, data_in, clk , load );
input [15:0] data_in;
input load, clk;
output reg [15:0] data_out;

always @(posedge clk)
if (load) data_out <= data_in;
endmodule

// defining D flip flop 

module  dff(d ,q ,clk ,clr);
input  d, clk ,clr ; // d : input to flip flop , clr : clear flip flop , 
output reg q ;
always @(posedge clk)
if (clr) q <= 0 ;
else q <= d ; 
endmodule

// defining ALU for addition or subtraction as per requirement 

module  alu( out , in1, in2, addsub);
input  [15:0] in1, in2;// in_1 , in_2 : ipus to the ALU , addsub : to decide whether to add or subtract 
input addsub;
output  reg [15:0] out;// out : store the output 

always @(*)
begin
  if (addsub==0) out = in1 - in2 ; 
  else out = in1 + in2 ; 
end
endmodule

// defining counter 

module  cntr(data_out , decr, ldcnt , clk);
input decr, clk,ldcnt ; // decr : decreasing the no of steps performed 
output reg [4:0] data_out;

always @(posedge clk)
begin
    if (ldcnt) data_out <= 5'b10000; 
    else if (decr) data_out <= data_out - 1 ; 
end
endmodule

// defining control path and control signals 

module  controller(lda , clra, sfta, ldq, clrq,sftq,ldm, clrff, addsub, start, decr,ldcnt, done, clk, q0, qm1,eqz);

input clk , q0,qm1,start,eqz;
output  reg lda,clra,sfta, ldq, clrq,sftq,ldm , clrff, addsub, decr, ldcnt, done;
reg [2:0] state; 
parameter s0=3'b000;
parameter s1=3'b001;
parameter s2=3'b010;
parameter s3=3'b011;
parameter s4=3'b100;
parameter s5=3'b101;
parameter s6=3'b110;

always @(posedge clk)
begin
case ( state)
s0: if ( start) state <= s1 ; 
s1: state <= s2 ; 
s2: #2 if ({q0, qm1}==2'b01) state <= s3 ; 
        else if ({q0, qm1}==2'b10) state <= s4 ;
        else state <= s5 ; 
s3: state <= s5 ; 
s4: state <= s5 ; 
s5: #2 if (({q0, qm1}==2'b01) && !eqz) state <= s3;
         else if (({q0, qm1}==2'b10) && !eqz) state <= s4;
         else if (eqz) state <= s6 ;
s6: state <= s6 ; 
default: state <= s0 ; 
endcase  
end 

always @(state)
begin 
case ( state)
s0: begin clra = 0 ; lda = 0 ; sfta = 0 ; clrq = 0 ; ldq = 0 ; sftq = 0; ldm = 0 ; clrff = 0 ; done = 0 ; end 
s1: begin clra = 1 ; clrff = 1; ldcnt = 1 ; ldm = 1 ; end 
s2: begin clra=0; clrff = 0; ldcnt = 0 ; ldm = 0; ldq = 1 ; end 
s3: begin lda = 1 ; addsub = 1 ; ldq = 0; sfta = 0 ; sftq = 0 ; decr = 0 ; end
s4: begin lda = 1 ; addsub = 0 ; ldq= 0 ; sfta = 0 ; sftq = 0 ; decr = 0; end 
s5: begin sfta = 1 ; sftq = 1 ; lda = 0 ; ldq =0 ; decr = 1 ; end 
s6: done =1 ; 
default: begin clra = 0; sfta = 0 ; ldq = 0 ; sftq = 0 ; end 
endcase 
end
endmodule

// defining data path 

module booth(lda, ldq , ldm , clra , clrq , clrff, sfta, sftq , addsub, decr, ldcnt, data_in, clk, qm1, eqz);
input lda, ldq, ldm, clra, clrq, clrff, sfta, sftq, addsub, clk,decr,ldcnt;
input [15:0] data_in;
output qm1, eqz ; 
wire [15:0] A, M, Q,Z;
wire [4:0] count ; 
assign eqz = ~&count; 

shiftregister ar(A,Z,A[15],clk,lda,clra,sfta);
shiftregister qr(Q,data_in, A[0],clk,ldq,clrq,sftq);
dff qm11(Q[0], qm1,clk, clrff);
PIPO mr( M, data_in,clk, ldm);
alu as(Z,A,M,addsub);
cntr cn(count, decr,ldcnt,clk);

endmodule