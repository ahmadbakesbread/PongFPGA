module Pong (
	// Clock input
	input clk,
	// Reset switch input
	input resetSwitch,
	// Player 1 paddle movement switch input
	input playerSwitch,
	// Player 2 paddle movement switch input
	input player2Switch,
	// Horizontal synchronization output
	output hSync, 
	// Vertical synchronization output
	output vSync,
	// RGB color components for display output
	output [3:0] red, 
	output [3:0] green, 
	output [3:0] blue,
	// Player 1 scoreboard output
	output [6:0] playerScoreboard,
	// Player 2 scoreboard output
	output [6:0] player2Scoreboard
);

	// Constants for game parameters
	parameter BALL_SPEED = 1;
	parameter BALL_START_X = 320;
	parameter BALL_START_Y = 240;
	parameter H_MIN = 140;
	parameter H_MAX = 790;
	parameter V_MIN = 30;
	parameter V_MAX = 520;

	// Constants for logic parameters
	localparam CLOCK_3HZ_PERIOD = 625_000;
	localparam CLOCK_GAME_STATE_PERIOD = 25_000_000;
	localparam PLAYER_SCORE_BITS = 7;
	localparam SCORE_WIN_THRESHOLD = 5;

	// Registers for internal state
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
	reg clk3Hz = 0;
	reg clkGameState = 0;
	reg enableVCounter;
	reg [15:0] hCounter = 0;
	reg [15:0] vCounter = 0;
	reg[1:0] bounceVarianceX = 2'b01;
	reg[1:0] bounceVarianceY = 2'b01;

	// Wire for reset condition
	wire reset;

	// Score display encoding
	reg [6:0] player1ScoreEncoding;
	reg [6:0] player2ScoreEncoding;

	// Score display logic
	always @(posedge clk) begin
		case(player1Score)
			7'b0000: player1ScoreEncoding = 7'b1000000; // 0
			7'b0001: player1ScoreEncoding = 7'b1111001; // 1
			7'b0010: player1ScoreEncoding = 7'b0100100; // 2
			7'b0011: player1ScoreEncoding = 7'b0110000; // 3
			7'b0100: player1ScoreEncoding = 7'b0011001; // 4
			7'b0101: player1ScoreEncoding = 7'b0010010; // 5
			default: player1ScoreEncoding = 7'b0000000; // default to 0 for invalid input
	endcase

	case(player2Score)
		7'b0000: player2ScoreEncoding = 7'b1000000; // 0
		7'b0001: player2ScoreEncoding = 7'b1111001; // 1
		7'b0010: player2ScoreEncoding = 7'b0100100; // 2
		7'b0011: player2ScoreEncoding = 7'b0110000; // 3
		7'b0100: player2ScoreEncoding = 7'b0011001; // 4
		7'b0101: player2ScoreEncoding = 7'b0010010; // 5
		default: player2ScoreEncoding = 7'b0000000; // default to 0 for invalid input
		endcase
	end

	// Assign score display values
	assign playerScoreboard = {8'b00000000, player1ScoreEncoding};
	assign player2Scoreboard = {8'b00000000, player2ScoreEncoding};

	// Clock dividers for different frequencies
	always @(posedge clk) begin
		// Toggle 25MHz clock
		clk25MHz <= ~clk25MHz;
		// Divide the clock to achieve 3Hz frequency
		if (j >= CLOCK_3HZ_PERIOD) begin
			clk3Hz <= ~clk3Hz;
			j <= 0;
		end else begin
			j <= j + BALL_SPEED;
		end
		// Divide the clock to achieve a slower frequency for game state handling
		if (k >= CLOCK_GAME_STATE_PERIOD) begin
			clkGameState = ~clkGameState;
			k <= 0;
		end else
			k <= k + 1;
	end

	// Horizontal counter for screen drawing
	always @(posedge clk25MHz) begin
		if (hCounter < 800) begin
			hCounter <= hCounter + 1;
			enableVCounter <= 0;
		end
		else begin
			hCounter <= 0;
			enableVCounter <= 1;
		end
	end

	// Vertical counter for screen drawing
	always @(posedge clk25MHz) begin
		if (enableVCounter == 1'b1) begin
			if (vCounter < 525)
				vCounter <= vCounter + 1;
			else
				vCounter <= 0;
			end
	end
	
	assign hSync = (hCounter < 96) ? 1 : 0;
	assign vSync = (vCounter < 2) ? 1 : 0;

	// Ball movement and collision handling
	always @(posedge clk3Hz) begin
		// Reset conditions when the reset switch is active
		if (reset) begin
			ballPosX = BALL_START_X;
			ballPosY = BALL_START_Y;
			ballXDir = 1;
			ballYDir = 1;
			player1Score <= 0;
			player2Score = 0;
		end

		// Ball hit the left boundary, player 2 scores
		if (ballPosX <= H_MIN + 1) begin
			ballPosX = BALL_START_X;
			ballPosY = BALL_START_Y;
			ballXDir = 1;
			ballYDir = 1;
			player2Score = player2Score + 1;
		end

		// Ball hit the right boundary, player 1 scores
		if (ballPosX >= H_MAX - 1) begin
			ballPosX = BALL_START_X + 300;
			ballPosY = BALL_START_Y;
			ballXDir = 0;
			ballYDir = ~ballYDir;
			player1Score <= player1Score + 1;
		end

		// Check collision with player 1 paddle
		if (ballPosX >= paddlePosX && ballPosX <= paddlePosX + 1 && ballPosY >= paddleBottom && ballPosY <= paddleTop) begin
			// Determine the direction of ball bounce
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
			// Change ball direction after collision
			ballXDir = ~ballXDir;
		end else if (ballPosX <= paddle2PosX && ballPosX >= paddle2PosX - 1 && ballPosY >= paddle2Bottom && ballPosY <= paddle2Top) begin
			// Ball hit player 2 paddle, change direction
				ballXDir = ~ballXDir;
		end

		// Ball hit top or bottom boundaries, change vertical direction
		if (ballPosY >= (V_MAX - 3) || ballPosY <= (V_MIN + 3))
			ballYDir = ~ballYDir;

		// Update ball position based on direction and variance
		ballPosX = (ballXDir) ? ballPosX + bounceVarianceX : ballPosX - bounceVarianceX;
		ballPosY = (ballYDir) ? ballPosY + bounceVarianceY : ballPosY - bounceVarianceY;
	end

	// Controlling player paddles
	always @(posedge clk3Hz) begin
		 // Controlling player 1's paddle
		 if (~playerSwitch) begin
			  // Switch is ON (1), move paddle up
			  if (paddlePosY < V_MAX - paddleLength)
					paddlePosY <= paddlePosY + 1;
		 end else begin
			  // Switch is OFF (0), move paddle down
			  if (paddlePosY > V_MIN + paddleLength)
					paddlePosY <= paddlePosY - 1;
		 end

		 // Update player 1 paddle top and bottom positions for collision detection
		 paddleTop <= paddlePosY + paddleLength;
		 paddleBottom <= paddlePosY - paddleLength;

		 // Controlling player 2's paddle
		 if (player2Switch) begin
			  // Switch is ON (1), move paddle up
			  if (paddle2PosY > V_MIN + paddleLength)
					paddle2PosY <= paddle2PosY - 1;
		 end else begin
			  // Switch is OFF (0), move paddle down
			  if (paddle2PosY < V_MAX - paddleLength)
					paddle2PosY <= paddle2PosY + 1;
		 end

		 // Update player 2 paddle top and bottom positions for collision detection
		 paddle2Top <= paddle2PosY + paddleLength;
		 paddle2Bottom <= paddle2PosY - paddleLength;
	end


	// Game state handling
	always @(posedge clkGameState) begin
		// Reset the game state if the reset condition is triggered
			if (resetRegister)
				resetRegister = 0;

		// Check for winning condition, reset the game if either player reaches a score of 9
		if (player1Score >= SCORE_WIN_THRESHOLD || player2Score >= SCORE_WIN_THRESHOLD) begin
			resetRegister = 1;
		end
	end
	
	assign reset = (resetRegister || resetSwitch);

	// Drawing the scenario on the display
	always @(posedge clk) begin              
		// Draw the ball on the screen
		if ((hCounter <= ballPosX + 3 && hCounter >= ballPosX && vCounter <= ballPosY + 2 && vCounter >= ballPosY - 2)) begin
			redValue <= 4'hF;
			greenValue <= 4'hA;
			blueValue <= 4'hF;
		// Draw the player 1 paddle
		end else if (vCounter >= paddleBottom && vCounter <= paddleTop && hCounter == paddlePosX + 2) begin
			redValue <= 4'h0;
			greenValue <= 4'hF;
			blueValue <= 4'h0;
		// Draw the player 2 paddle
		end else if (vCounter >= paddle2Bottom && vCounter <= paddle2Top && hCounter == paddle2PosX + 2) begin
			redValue <= 4'hF;
			greenValue <= 4'h0;
			blueValue <= 4'h0;    
		// Draw the background
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
