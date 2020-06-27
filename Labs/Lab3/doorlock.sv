
module KeyPad(output reg [15:0] last4, //the binary-coded digit for a key, a number in the range [0, 10);
              input wire [3:0] key, //the binary-coded digit for a key, a number in the range [0, 10)
              input wire pressed, //a Boolean signal telling whether a key was pressed in the current cycle
              input wire clk);
  initial begin
  last4 = 0;  
  end
  
  always @ (posedge clk) begin 
    if (pressed) begin
      last4 = ((last4 % 1000) * 10) + key;
    end
  end  

endmodule

module ReqKeyPad(input [3:0] key,
                 input pressed,
                 input clk);

/*
 * last4pc: This register is used to store the contents of the last4 in the previous cycle
 *          so that it can be compared with the contents of the last4 in the next cycle in
 *          case no key is pressed. Used while realizing Requirement 6
 * keypc: This register is assigned the value of the pressed key from the previous 
 *        cycle. Used while realizing Requirement 5. 
 */ 

   wire [15:0] last4;
   KeyPad keypad(last4, key, pressed, clk);
   reg [15:0] last4pc;
   reg [3:0] keypc;

  always @ (posedge clk) begin 
    last4pc <= last4;
    keypc <= key;
  end 

  assume property (key >= 0 && key < 10);                //E1

  assert property (0 <= last4 && last4 < 10000);         //R4    
  assert property (pressed |=> (last4 % 10) == keypc);   //R5
  assert property (!pressed |=> last4pc == last4);       //R6
   // Add requirements R4, R5, R6, and assumption E1 here
endmodule

//////////////////////////////////////////////////////////////////////

module Control(output reg code_matches,
               input pressed,
               input [15:0] last4,
               input wire set_code,
               input clk);
    
    
      reg [16:0] storecode;
      reg init;

    initial begin
      storecode = 10000;
      init = 0;
      code_matches = 0;
    end
   // Add your implementation here
    always @(posedge clk) begin

      if(set_code == 1) begin
          storecode = last4;
          init = 1;
      end
      
      if(pressed) begin
        if(last4 == storecode && init)
          code_matches <= 1;
        else
          code_matches <= 0;
      end
      else 
        code_matches <= 0;
    end

endmodule

module ReqControl(input pressed,
                  input [15:0] last4,
                  input set_code,
                  input clk);

/*
 * isetc_o: This register is used as a flag to indicate whether set_code has not been true
 *          since the last time the code was changed. Used while realizing Requirement 9.
 * pcpressed: This register is used to store the value of the pressed input from the 
 *            previous cycle. Used while realizing Requirement 8.
 * init: This register is a flag that determines whether a code was set with the set_code
 *       input or not. Used while realizing Requirement 7. 
 */ 

   reg pcpressed;
   reg init;
   wire code_matches;
   reg isetc_o; 
   reg [16:0] storecode;
   
   Control control(code_matches, pressed, last4, set_code, clk);

   initial begin
    storecode = 10000;
    init = 0;
    isetc_o = 0;
   end
   

   always @(posedge clk) begin

    if(set_code == 1) begin
      storecode = last4;
      
      isetc_o = 1; 
      init = 1;
    end
    else if(code_matches)
      isetc_o = 0;
    
    if(pressed)
      pcpressed <= pressed; 
    end

   // Add requirements R7, R8, R9, and assumption E2 here
  assume property (last4 >= 0 && last4 < 10000);                                                 // E2

  assert property ((init && code_matches) || (!init && !code_matches) || (init && !code_matches));//R7
  assert property (code_matches |-> pcpressed);                                                   //R8
  //assert property ((init && !isetc_o && last4 == storecode) |=> 1==1 && !pressed |=> code_matches);                    //R9


endmodule

//////////////////////////////////////////////////////////////////////

module Lock(output unlocked,
            input [3:0] key,
            input pressed,
            input set_code,
            input clk);

   wire [15:0] last4;
   wire code_matches;

   // we delay the signals pressed and set_code going to the controller
   // by one cycle, to compensate for the delay of last4 introduced
   // by the keypad

   reg pre_pressed = 0, pre_set_code = 0;
   always @(posedge clk) begin
     pre_pressed = pressed;
     pre_set_code = set_code;
   end

   KeyPad  keypad(last4, key, pressed, clk);
   Control control(code_matches, pre_pressed, last4, pre_set_code, clk);

   reg [3:0] i = 15;
   always @(posedge clk) begin
     if (code_matches)
       i = 0;
     else if (i < 15)
       i = i + 1;
   end

   assign unlocked = code_matches || i < 9;

endmodule

module ReqLock(input [3:0] key,
               input pressed,
               input set_code,
               input clk);

/*
 * flag: This register is used as a flag to indicate if the door remains locked if the door is not unlocked
 *        and the key is not pressed.
 * count: This register is used to count cycles to check if the door locks after 10 cycles if no key pressed 
 .        and the door is unlocked. */ 


   wire unlocked;
   reg [3:0] count;

   initial begin
      count = 0;
  end
    
   Lock lock(unlocked, key, pressed, set_code, clk);

   always @(posedge clk) begin
    if(unlocked && !pressed)
      count = count + 1;
    else
      count = 0;
   end

   // Add requirements R1, R2, and assumption E1 here
   assume property (key >= 0 && key < 10);                  //E1
                                                               
   assert property ((!unlocked && !pressed) |=> (!unlocked && !pressed) |=> !unlocked);     //R1
   assert property ((count == 9 && !pressed && unlocked)|=> ##1 !unlocked);  //R2

   // Bonus requirement:
   // After setting the code to 1234,
   // entering 1234 again will unlock the door

   assert property (key == 1 && pressed |=>
                    key == 2 && pressed |=>
                    key == 3 && pressed |=>
                    key == 4 && pressed |=>
                    !pressed && set_code |=>
                    key == 1 && pressed && !set_code |=>
                    key == 2 && pressed && !set_code |=>
                    key == 3 && pressed && !set_code |=>
                    key == 4 && pressed && !set_code |=>
                    ##1 unlocked);

endmodule
