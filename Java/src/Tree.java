
public class Tree {
	private int height;

	Tree(int initialHeight)
	{
		height = initialHeight;
		System.out.println("planting new tree " + height + " tall");
	}

	Tree()
	{
		height = 0;
		System.out.println("planting seedling ");
	}

	public void info() {
		System.out.println("tall " + height);
	}
	
	public void info(String s) {
		System.out.println(s + height);
	}
	
}
