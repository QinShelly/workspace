
public class Flower {
	Flower reference;
	int petalCount = 0;
	String s = "initial value";
	
	Flower(int petals){
		petalCount = petals;
		System.out.println("init with int argument only, petalCount = "
		+ petalCount);
	}
	
	Flower(String ss){
		System.out.println("init with string argument only, s = " + ss);
	}
	
	Flower(String s, int petals){
		this(petals);
		this.s = s;
		System.out.println("String && int args");
	}
	
	Flower(){
		this("hi",47);
		System.out.println("no args");
	}
	
	void printPetalCount(){
		System.out.println("petalCount = " + petalCount + " s =" + s);
	}
	

	public static void main(String[] args) {
		Flower f = new Flower();
		f.printPetalCount();
		System.out.println(f.reference);
	}

}
