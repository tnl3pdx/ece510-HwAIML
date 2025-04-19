import os
import sys

def quicksort(filename):
    """
    Sorts a list of numbers from a file using the quicksort algorithm and writes the sorted list to a new file.

    Args:
        filename (str): The name of the input file containing numbers separated by newlines.
    """
    try:
        with open(filename, 'r') as f:
            numbers = [int(line.strip()) for line in f]
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")
        return
    except ValueError:
        print(f"Error: File '{filename}' contains non-numeric data.")
        return

    def partition(arr, low, high):
        i = (low - 1)
        pivot = arr[high]

        for j in range(low, high):
            if arr[j] <= pivot:
                i = i + 1
                arr[i], arr[j] = arr[j], arr[i]

        arr[i + 1], arr[high] = arr[high], arr[i + 1]
        return (i + 1)

    def quickSortHelper(arr, low, high):
        if low < high:
            pi = partition(arr, low, high)

            quickSortHelper(arr, low, pi - 1)
            quickSortHelper(arr, pi + 1, high)

    quickSortHelper(numbers, 0, len(numbers) - 1)

    base_filename = os.path.basename(filename)
    output_filename = os.path.join(os.path.dirname(filename), "sorted_" + base_filename)
    try:
        with open(output_filename, 'w') as f:
            for number in numbers:
                f.write(str(number) + '\n')
        print(f"Sorted data written to '{output_filename}'")
    except Exception as e:
        print(f"Error writing to file: {e}")

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    if len(sys.argv) == 1:
        input_file = "random_numbers.txt"
        input_path = os.path.join(script_dir, input_file)
    elif len(sys.argv) == 2 and sys.argv[1] == '-m':
        input_file = input("Enter the input filename: ")
        input_path = os.path.join(script_dir, input_file)
    else:
        print("Usage: python quicksort.py [-m]")
        exit()

    print(f"Script directory: {script_dir}")  # Debug print
    print(f"Combined input path: {input_path}") # Debug print

    if quicksort(input_path) is None:
        exit()