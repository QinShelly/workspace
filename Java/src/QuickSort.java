public class QuickSort {
	static void quickSort(int[] arr, int low, int high){
		int pivotPos;
		if (low < high){
			pivotPos = Partition(arr, low, high);
			quickSort(arr, low, pivotPos - 1);
			quickSort(arr,pivotPos + 1, high);
		}
	}
	
	static int Partition(int[] R, int i, int j){
		int pivot = R[i];
		while(i < j){
			while(i < j && R[j] >= pivot)
				j--;
			if(i < j)
				R[i++] = R[j];
			while(i < j && R[i] <= pivot)
				i++;
			if(i < j)
				R[j--] = R[i];
		}
		R[i] = pivot;
		return i;
	}
	
	//1 2 3 4 5 6 7 8 9  10
	//4 2 3 1 6 7 9 8 10 5           
	public static void main(String[] args) {
		int[] test = new int[20];
		for (int i=0;i<20;i++){
			test[i] = 100 + (int)(Math.random() * 100);
		}
		 
		quickSort(test, 0, test.length - 1);
		//int a = Partition(test, 0,5);
		//System.out.println(a);
		for(int i: test)
			System.out.print(i + " ");
	}

}
