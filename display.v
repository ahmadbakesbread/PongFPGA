module display (input [3:0] seg0, input [3:0] seg1, input [3:0] seg2,input [3:0] seg3, input [3:0] seg4, input [3:0] seg5,
    output [6:0] HEX0, output [6:0] HEX1, output [6:0] HEX2, output [6:0] HEX3, output [6:0] HEX4, output [6:0] HEX5
);

// Function that converts binary to 7-segment display encoding, holding the scores.
function [6:0] bin_to_7seg;
    input [3:0] bin;
    begin
        case (bin)
            4'd0: bin_to_7seg = 7'b1000000;
            4'd1: bin_to_7seg = 7'b1111001;
            4'd2: bin_to_7seg = 7'b0100100;
            4'd3: bin_to_7seg = 7'b0110000;
            4'd4: bin_to_7seg = 7'b0011001;
            4'd5: bin_to_7seg = 7'b0010010;
            4'd6: bin_to_7seg = 7'b0000010;
            4'd7: bin_to_7seg = 7'b1111000;
            4'd8: bin_to_7seg = 7'b0000000;
            4'd9: bin_to_7seg = 7'b0010000;
            default: bin_to_7seg = 7'b1111111; // Off for values 10-15
        endcase
    end
endfunction

// Assign the converted values to HEX outputs
assign HEX0 = bin_to_7seg(seg0);
assign HEX1 = bin_to_7seg(seg1);
assign HEX2 = bin_to_7seg(seg2);
assign HEX3 = bin_to_7seg(seg3);
assign HEX4 = bin_to_7seg(seg4);
assign HEX5 = bin_to_7seg(seg5);

endmodule
