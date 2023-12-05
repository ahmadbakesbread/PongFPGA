module Pong (
	// clock input
	input clk,
	// reset switch input
	input resetSwitch,
	// player 1 paddle movement switch input
	input playerSwitch,
	// player 2 paddle movement switch input
	input player2Switch,
	// horizontal synchronization output
	output hSync, 
	// vertical synchronization output
	output vSync,
	// RGB color components for display output
	output [3:0] red, 
	output [3:0] green, 
	output [3:0] blue,
	// player 1 scoreboard output
	output [6:0] playerScoreboard,
	// player 2 scoreboard output
	output [6:0] player2Scoreboard
);

	// constants for game parameters
	parameter BALL_SPEED = 1;
	parameter BALL_START_X = 320;
	parameter BALL_START_Y = 240;
	parameter H_MIN = 140;
	parameter H_MAX = 790;
	parameter V_MIN = 30;
	parameter V_MAX = 520;

	// constants for logic parameters
	localparam CLOCK_GAME_PERIOD = 400_000;
	localparam CLOCK_GAME_STATE_PERIOD = 25_000_000;
	localparam PLAYER_SCORE_BITS = 7;
	localparam SCORE_WIN_THRESHOLD = 5;

	// registers for internal state
	reg resetRegister = 0;
	reg [20:0] i = 0;
	reg [20:0] j = 0;
	reg [25:0] k = 0;
	reg [3:0] redValue, greenValue, blueValue;
	reg [15:0] ballPosX = BALL_START_X;
	reg [15:0] ballPosY = BALL_START_Y;
	reg ballXDir = 1;
	reg ballYDir = 1;
	reg [15:0] paddlePosX = 200;
	reg [15:0] paddlePosY = 275;
	reg [15:0] paddleBottom, paddleTop;
	reg [15:0] paddle2PosX = 710;
	reg [15:0] paddle2PosY = 275;
	reg [15:0] paddle2Bottom, paddle2Top;
	reg [5:0] paddleLength = 6'b101000;
	reg [PLAYER_SCORE_BITS-1:0] player1Score = 7'b0000000;
	reg [PLAYER_SCORE_BITS-1:0] player2Score = 7'b0000000;
	reg clk25MHz = 0;
	reg clkGame = 0;
	reg clkGameState = 0;
	reg toggleVCounter;
	reg [15:0] hCounter = 0;
	reg [15:0] vCounter = 0;
	reg[1:0] bounceVarianceX = 2'b01;
	reg[1:0] bounceVarianceY = 2'b01;

	// wire for reset condition
	wire reset;

	// score display encoding
	reg [6:0] player1ScoreEncoding;
	reg [6:0] player2ScoreEncoding;

	// score display logic
	always @(posedge clk) begin
		case(player1Score)
			7'b0000: player1ScoreEncoding = 7'b1000000; // 0
			7'b0001: player1ScoreEncoding = 7'b1111001; // 1
			7'b0010: player1ScoreEncoding = 7'b0100100; // 2
			7'b0011: player1ScoreEncoding = 7'b0110000; // 3
			7'b0100: player1ScoreEncoding = 7'b0011001; // 4
			7'b0101: player1ScoreEncoding = 7'b0010010; // 5
			default: player1ScoreEncoding = 7'b0000000; // default to 0 for unexpected input
		endcase

		case(player2Score)
			7'b0000: player2ScoreEncoding = 7'b1000000; // 0
			7'b0001: player2ScoreEncoding = 7'b1111001; // 1
			7'b0010: player2ScoreEncoding = 7'b0100100; // 2
			7'b0011: player2ScoreEncoding = 7'b0110000; // 3
			7'b0100: player2ScoreEncoding = 7'b0011001; // 4
			7'b0101: player2ScoreEncoding = 7'b0010010; // 5
			default: player2ScoreEncoding = 7'b0000000; // default to 0 for unexpected input
		endcase
	end

	// assign score display values
	assign playerScoreboard = {8'b00000000, player1ScoreEncoding};
	assign player2Scoreboard = {8'b00000000, player2ScoreEncoding};

	// clock dividers, modified from lab code
	always @(posedge clk) begin
		// toggle 25MHz clock
		clk25MHz <= ~clk25MHz;
		
		// divide the clock further for game functions
		if (j >= CLOCK_GAME_PERIOD) begin
			clkGame <= ~clkGame;
			j <= 0;
		end else begin
			j <= j + BALL_SPEED;
		end
		
		// divide the clock to achieve a slower frequency for game state handling
		if (k >= CLOCK_GAME_STATE_PERIOD) begin
			clkGameState = ~clkGameState;
			k <= 0;
		end else
			k <= k + 1;
	end

	// horizontal counter for screen drawing
	always @(posedge clk25MHz) begin
		if (hCounter < 800) begin
			hCounter <= hCounter + 1;
			toggleVCounter <= 0;
		end
		else begin
			hCounter <= 0;
			toggleVCounter <= 1;
		end
	end

	// vertical counter for screen drawing
	always @(posedge clk25MHz) begin
		if (toggleVCounter == 1'b1) begin
			if (vCounter < 525)
				vCounter <= vCounter + 1;
			else
				vCounter <= 0;
			end
	end
	
	assign hSync = (hCounter < 96) ? 1 : 0;
	assign vSync = (vCounter < 2) ? 1 : 0;

	// ball movement and collision handling
	always @(posedge clkGame) begin
		// reset conditions when the reset switch is active
		if (reset) begin
			ballPosX = BALL_START_X;
			ballPosY = BALL_START_Y;
			ballXDir = 1;
			ballYDir = 1;
			player1Score <= 0;
			player2Score = 0;
		end

		// ball hit the left boundary, player 2 scores
		if (ballPosX <= H_MIN + 1) begin
			ballPosX = BALL_START_X;
			ballPosY = BALL_START_Y;
			ballXDir = 1;
			ballYDir = 1;
			player2Score = player2Score + 1;
		end

		// ball hit the right boundary, player 1 scores
		if (ballPosX >= H_MAX - 1) begin
			ballPosX = BALL_START_X + 300;
			ballPosY = BALL_START_Y;
			ballXDir = 0;
			ballYDir = ~ballYDir;
			player1Score <= player1Score + 1;
		end

		// check collision with player 1 paddle
		if (ballPosX >= paddlePosX && ballPosX <= paddlePosX + 1 && ballPosY >= paddleBottom && ballPosY <= paddleTop) begin
			// determine the direction of ball bounce
			if ((playerSwitch && ballYDir) || (~playerSwitch && ~ballYDir)) begin
				bounceVarianceY <= 2'b10;
				bounceVarianceX <= 2'b01;
			end else if ((playerSwitch && ~ballYDir) || (~playerSwitch && ~ballYDir)) begin
				bounceVarianceX <= 2'b10;
				bounceVarianceY <= 2'b01;
			end else if ((player2Switch && ballYDir) || (~player2Switch && ~ballYDir)) begin
				bounceVarianceY <= 2'b10;
				bounceVarianceX <= 2'b01;
			end else if ((player2Switch && ~ballYDir) || (~player2Switch && ~ballYDir)) begin
				bounceVarianceX <= 2'b10;
				bounceVarianceY <= 2'b01;
			end else begin
				bounceVarianceX <= 2'b01;
				bounceVarianceY <= 2'b01;
			end
			// change ball direction after collision
			ballXDir = ~ballXDir;
		end else if (ballPosX <= paddle2PosX && ballPosX >= paddle2PosX - 1 && ballPosY >= paddle2Bottom && ballPosY <= paddle2Top) begin
			// ball hit player 2 paddle, change direction
				ballXDir = ~ballXDir;
		end

		// ball hit top or bottom boundaries, change vertical direction
		if (ballPosY >= (V_MAX - 3) || ballPosY <= (V_MIN + 3))
			ballYDir = ~ballYDir;

		// update ball position based on direction and variance
		ballPosX = (ballXDir) ? ballPosX + bounceVarianceX : ballPosX - bounceVarianceX;
		ballPosY = (ballYDir) ? ballPosY + bounceVarianceY : ballPosY - bounceVarianceY;
	end

	// controlling player paddles
	always @(posedge clkGame) begin
		 // controlling player 1's paddle
		 if (~playerSwitch) begin
			  // switch is ON (1), move paddle up
			  if (paddlePosY < V_MAX - paddleLength)
					paddlePosY <= paddlePosY + 1;
		 end else begin
			  // switch is OFF (0), move paddle down
			  if (paddlePosY > V_MIN + paddleLength)
					paddlePosY <= paddlePosY - 1;
		 end

		 // update player 1 paddle top and bottom positions for collision detection
		 paddleTop <= paddlePosY + paddleLength;
		 paddleBottom <= paddlePosY - paddleLength;

		 // controlling player 2's paddle
		 if (player2Switch) begin
			  // switch is ON (1), move paddle up
			  if (paddle2PosY > V_MIN + paddleLength)
					paddle2PosY <= paddle2PosY - 1;
		 end else begin
			  // switch is OFF (0), move paddle down
			  if (paddle2PosY < V_MAX - paddleLength)
					paddle2PosY <= paddle2PosY + 1;
		 end

		 // update player 2 paddle top and bottom positions for collision detection
		 paddle2Top <= paddle2PosY + paddleLength;
		 paddle2Bottom <= paddle2PosY - paddleLength;
	end


	// game state handling
	always @(posedge clkGameState) begin
		// reset the game state if the reset condition is triggered
		if (resetRegister)
			resetRegister = 0;

		// check for winning condition, reset the game if either player reaches a score of 9
		if (player1Score >= SCORE_WIN_THRESHOLD || player2Score >= SCORE_WIN_THRESHOLD) begin
			resetRegister = 1;
		end
	end
	
	assign reset = (resetRegister || resetSwitch);
	

	// drawing scenario on vga display
	always @(posedge clk) begin
	
		// player 1 wins
		if (player1Score >= SCORE_WIN_THRESHOLD) begin
			redValue <= 4'h0;
			greenValue <= 4'hF;
			blueValue <= 4'h0;
		// player 2 wins
		end else if (player2Score >= SCORE_WIN_THRESHOLD) begin
			redValue <= 4'hF;
			greenValue <= 4'h0;
			blueValue <= 4'h0; 
		// draw ball on screen
		end else if ((hCounter <= ballPosX + 3 && hCounter >= ballPosX && vCounter <= ballPosY + 2 && vCounter >= ballPosY - 2)) begin
			redValue <= 4'hF;
			greenValue <= 4'hA;
			blueValue <= 4'hF;
		// draw player 1's paddle
		end else if (vCounter >= paddleBottom && vCounter <= paddleTop && hCounter == paddlePosX + 2) begin
			redValue <= 4'h0;
			greenValue <= 4'hF;
			blueValue <= 4'h0;
		// draw player 2's paddle
		end else if (vCounter >= paddle2Bottom && vCounter <= paddle2Top && hCounter == paddle2PosX + 2) begin
			redValue <= 4'hF;
			greenValue <= 4'h0;
			blueValue <= 4'h0;    
		// draw background
		end else if (hCounter < H_MAX && hCounter > H_MIN && vCounter < V_MAX && vCounter > V_MIN) begin
			redValue <= 4'h0;
			greenValue <= 4'h0;
			blueValue <= 4'h0;
		end
	end

	assign red = redValue;
	assign green = greenValue;
	assign blue = blueValue;

endmodule
