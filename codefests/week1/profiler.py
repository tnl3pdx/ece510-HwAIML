import cProfile
import pstats
import sys
import os
import subprocess
import runpy

def profile_script(script_path):
    script_path = os.path.abspath(script_path)
    if not os.path.exists(script_path):
        print("Error: The specified script does not exist.")
        return
    
    profile_output = "profile_output.prof"
    print(f"Profiling {script_path}...")
    
    cProfile.run(f'runpy.run_path(r"{script_path}")', profile_output)
    
    print("Profiling complete. Generating statistics...")
    
    # Print profile stats in human-readable format
    stats = pstats.Stats(profile_output)
    #stats.strip_dirs().sort_stats(pstats.SortKey.TIME).print_stats()
    
    print("Profile data saved. You can visualize it using SnakeViz.")
    print("Running SnakeViz...")
    
    # Open snakeviz for visualizing the profile
    subprocess.run(["snakeviz", profile_output])

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python profiler.py <script_to_profile.py>")
    else:
        profile_script(sys.argv[1])
