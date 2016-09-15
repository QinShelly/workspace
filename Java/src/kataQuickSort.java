
public class kataQuickSort {

	static void qSort(int[] arr, int low, int high){
		int pivotPos;
		if (low < high){
			pivotPos = Partition(arr,low,high);
			qSort(arr,low,pivotPos - 1);
			qSort(arr,pivotPos+1, high);
		}
	}
	private static int Partition(int[] arr, int i, int j) {
		int pivot = arr[i];
		while(i < j){
			while(i < j && arr[j] >= pivot)
				j--;
			if(i < j)
				arr[i++] = arr[j];
			while(i < j && arr[i] <= pivot)
				i++;
			if(i < j)
				arr[j--] = arr[i];
		}
		arr[i] = pivot;
		return i;
	}
	public static void main(String[] args) {
		int[] test = new int[10];
		for (int i = 0;i < 10;i++){
			test[i] = 100 + (int)(Math.random() * 100);
		}
		 
		qSort(test, 0, test.length - 1);
		//int a = Partition(test, 0,5);
		//System.out.println(a);
		for(int i: test)
			System.out.print(i + " ");
	}

}
