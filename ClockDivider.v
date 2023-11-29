// This clock divider program was provided to us by Professor Robert Allison, York Uniiversity.
module ClockDivider(cin,cout);
    input cin;
    output reg cout;
    reg[31:0] count;
    parameter D = 32'd833333; // The game logic updates every 1/60th of a second, achieving a frame rate of 60 FPS.
    always @(posedge cin)
    begin
    count <= count + 32'd1;
    if (count >= (D-1)) begin
    cout <= ~cout;
    count <= 32'd0;
    end
    end
endmodule