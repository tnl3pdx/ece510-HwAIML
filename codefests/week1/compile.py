import py_compile
import dis
import os
import sys
import io
import contextlib
import marshal

# Prompt the user to enter the script path
script_path = input("Enter the path to the Python script to compile: ")

try:
    py_compile.compile(script_path)
    print(f"Successfully compiled {script_path} to bytecode.")

    # Construct the bytecode file name
    base_name = os.path.basename(script_path)
    script_name = os.path.splitext(base_name)[0]
    
    # Construct the __pycache__ path
    cache_dir = os.path.join(os.path.dirname(script_path), '__pycache__')
    
    # Construct the bytecode file name inside __pycache__
    if sys.implementation.cache_tag is not None:
        bytecode_name = f"{script_name}.{sys.implementation.cache_tag}.pyc"
    else:
        bytecode_name = f"{script_name}.pyc"
    
    bytecode_path = os.path.join(cache_dir, bytecode_name)

    # Construct the output file name
    output_file = os.path.splitext(script_path)[0] + "_disassembly.txt"

    # Redirect the output of dis.dis to a file
    with open(output_file, 'w') as f:
        
        # Capture the output of dis.dis
        with io.StringIO() as buffer, contextlib.redirect_stdout(buffer):
            try:
                # Check if the bytecode file exists and is not empty
                if os.path.exists(bytecode_path) and os.path.getsize(bytecode_path) > 0:
                    with open(bytecode_path, 'rb') as bytecode_file:
                        bytecode_file.read(16)  # Skip the .pyc header (magic number, timestamp, etc.)
                        code_object = marshal.load(bytecode_file)  # Load the code object

                    # Use dis.dis to disassemble the code object
                    dis.dis(code_object)
                    buffer.flush()  # Ensure all data is written to the buffer
                    f.write(buffer.getvalue())
                else:
                    error_message = f"Bytecode file is empty or does not exist: {bytecode_path}"
                    f.write(error_message)
                    print(error_message)  # Also print to console
            except FileNotFoundError:
                f.write(f"Bytecode file not found: {bytecode_path}")
            except Exception as e:
                f.write(f"Error disassembling bytecode: {e}")

    print(f"\nDisassembly written to {output_file}")

except py_compile.PyCompileError as e:
    print(f"Error compiling {script_path}: {e}")
except FileNotFoundError:
    print(f"Error: {script_path} not found.")
except Exception as e:
    print(f"Error disassembling bytecode: {e}")
