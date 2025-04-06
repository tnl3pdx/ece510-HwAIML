import re
from collections import Counter, defaultdict
from tabulate import tabulate
import os

def extract_instructions(text):
    """Extracts instructions from the given text based on the criteria."""
    return re.findall(r'\b[A-Z_]+\b', text)

def process_files():
    """Processes multiple disassembled Python program files and counts instruction occurrences."""
    file_instruction_counts = {}  # Stores per-file counts
    overall_counter = Counter()
    file_list = []
    file_paths = []
    
    # Collect file paths first
    while True:
        file_path = input("Enter file path (or press Enter to finish): ").strip()
        if not file_path:
            break
        file_paths.append(file_path)
    
    # Process collected files
    for file_path in file_paths:
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()
                instructions = extract_instructions(content)
                instruction_counter = Counter(instructions)
                
                file_name = os.path.basename(file_path)  # Get only the file name
                file_instruction_counts[file_name] = instruction_counter
                overall_counter.update(instruction_counter)
                file_list.append(file_name)
                
                # Print individual file report
                print(f"\nInstruction Distribution for {file_name}:")
                for instr in sorted(instruction_counter):
                    print(f"{instr}: {instruction_counter[instr]}")
        except FileNotFoundError:
            print(f"Error: File '{file_path}' not found.")
        except Exception as e:
            print(f"Error processing '{file_path}': {e}")
    
    # Create a summary table
    if file_instruction_counts:
        print("\nFinal Instruction Distribution Table:")
        all_instructions = sorted(set(overall_counter.keys()))
        table_data = []
        
        for instr in all_instructions:
            row = [instr]
            for file in file_list:
                row.append(file_instruction_counts[file].get(instr, 0))
            table_data.append(row)
        
        headers = ["Instruction"] + file_list
        table_str = tabulate(table_data, headers=headers, tablefmt="grid")
        print(table_str)
        
        # Save the table to a text file
        with open("table.txt", "w", encoding="utf-8") as file:
            file.write(table_str)

if __name__ == "__main__":
    process_files()
