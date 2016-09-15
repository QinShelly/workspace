
public class Game {
	
	private int score = 0;

	private int[] rolls = new int[21];
	private int currentRoll = 0;
	private int[] frameScores = new int[10];
	
	void roll(int pins){
		score += pins;
		rolls[currentRoll++] = pins;
	}
	
	int frameScore(int frameIndex){
		return frameScores[frameIndex];
	}
	
	int score(){
		int score = 0;
		int frameIndex = 0;
		for (int frame = 0; frame < 10; frame++){
			if (isStrike(frameIndex)){ 
				score += 10 + rolls[frameIndex + 1] + rolls[frameIndex + 2];
				frameIndex++;
			}
			else if(isSpare(frameIndex)) 
			{
				score += 10 + rolls[frameIndex+2];
				frameIndex+=2;
			} else{
				score += rolls[frameIndex] + rolls[frameIndex+1];
				frameIndex+=2;
			}
		}
			
		return score;
	}

	private boolean isStrike(int frameIndex) {
		return rolls[frameIndex] == 10;
	}

	private boolean isSpare(int frameIndex) {
		return rolls[frameIndex] + rolls[frameIndex+1] == 10;
	}
	
	public static void main(String[] args) {
		// TODO Auto-generated method stub

	}

}
