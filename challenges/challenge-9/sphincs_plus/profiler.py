#!/usr/bin/env python3

import cProfile
import pstats
import os
import time
import sys
from typing import Callable, List, Any
from functools import wraps

# Try importing pycallgraph, but don't fail if not installed
try:
    from pycallgraph import PyCallGraph
    from pycallgraph.output import GraphvizOutput
    from pycallgraph import Config
    from pycallgraph import GlobbingFilter
    PYCALLGRAPH_AVAILABLE = True
except ImportError:
    PYCALLGRAPH_AVAILABLE = False
    print("Warning: pycallgraph not installed. Call graphs will not be available.")


class Profiler:
    """
    A simple profiler class that can profile Python code using cProfile 
    and generate call graphs using pycallgraph with graphviz.
    """
    
    def __init__(self, 
                 output_dir: str = "profile_results",
                 include_patterns: List[str] = None, 
                 exclude_patterns: List[str] = None):
        """
        Initialize the profiler.
        
        Args:
            output_dir: Directory where profile results will be saved
            include_patterns: List of glob patterns to include in call graph
            exclude_patterns: List of glob patterns to exclude from call graph
        """
        self.output_dir = output_dir
        self.include_patterns = include_patterns or ["*"]
        self.exclude_patterns = exclude_patterns or []
        
        # Create output directory if needed
        os.makedirs(self.output_dir, exist_ok=True)
        
        # Verify graphviz availability
        self.has_pycallgraph = PYCALLGRAPH_AVAILABLE
        self.enabled = True
    
    def profile_enabled(self, en: bool) -> bool:
        """
        Enable or disable profiling.
        
        Args:
            en: Boolean to enable or disable profiling
            
        Returns:
            The current state of profiling
        """
        self.enabled = en
        return self.enabled
    
    def profile_function(self, 
                        func: Callable, 
                        *args, 
                        use_cprofile: bool = True,
                        use_callgraph: bool = True,
                        output_prefix: str = None,
                        **kwargs) -> Any:
        """
        Profile a function with both cProfile and pycallgraph.
        
        Args:
            func: Function to profile
            *args: Arguments to pass to the function
            use_cprofile: Whether to use cProfile
            use_callgraph: Whether to generate call graph
            output_prefix: Prefix for output files
            **kwargs: Keyword arguments to pass to the function
            
        Returns:
            The return value of the function
        """
        if not self.enabled:
            print("Profiling is disabled.")
            return func(*args, **kwargs)
        
        # Generate default output prefix if not provided
        if output_prefix is None:
            output_prefix = f"{func.__name__}_{int(time.time())}"
        
        result = None
        
        # Run with cProfile if requested
        if use_cprofile:
            result = self._run_with_cprofile(func, output_prefix, *args, **kwargs)
        
        # Run with pycallgraph if requested and available
        if use_callgraph and self.has_pycallgraph:
            # If cProfile wasn't used, we need to actually run the function
            if not use_cprofile:
                result = self._run_with_callgraph(func, output_prefix, *args, **kwargs)
            else:
                # Just generate the graph without re-running 
                # (we already have the result from cProfile)
                self._generate_callgraph(func, output_prefix, *args, **kwargs)
        elif use_callgraph and not self.has_pycallgraph:
            print("Warning: pycallgraph not available, skipping call graph generation")
            # If cProfile wasn't used either, run the function without profiling
            if not use_cprofile:
                result = func(*args, **kwargs)
        
        return result
    
    def profile_decorator(self, 
                        use_cprofile: bool = True, 
                        use_callgraph: bool = True):
        """
        Decorator to profile a function.
        
        Args:
            use_cprofile: Whether to use cProfile
            use_callgraph: Whether to generate call graph
            
        Returns:
            Decorated function
        """
        def decorator(func):
            @wraps(func)
            def wrapper(*args, **kwargs):
                output_prefix = f"{func.__name__}_{int(time.time())}"
                return self.profile_function(
                    func, 
                    *args, 
                    use_cprofile=use_cprofile,
                    use_callgraph=use_callgraph,
                    output_prefix=output_prefix,
                    **kwargs
                )
            return wrapper
        return decorator
    
    def _run_with_cprofile(self, 
                         func: Callable, 
                         output_prefix: str, 
                         *args, 
                         **kwargs) -> Any:
        """
        Run a function with cProfile and save the results.
        
        Args:
            func: Function to profile
            output_prefix: Prefix for output files
            *args: Arguments to pass to the function
            **kwargs: Keyword arguments to pass to the function
            
        Returns:
            The return value of the function
        """
        print(f"Profiling {func.__name__} with cProfile...")
        
        # Create profiler
        profiler = cProfile.Profile()
        profiler.enable()
        
        # Run the function
        try:
            result = func(*args, **kwargs)
        finally:
            profiler.disable()
        
        # Save results
        stats = pstats.Stats(profiler)
        stats.sort_stats('cumulative')
        
        # Save to file
        output_file = os.path.join(self.output_dir, f"{output_prefix}_cprofile.txt")
        stats.dump_stats(os.path.join(self.output_dir, f"{output_prefix}_cprofile.prof"))
        
        # Also save readable text version
        with open(output_file, 'w') as f:
            stdout_backup = sys.stdout
            try:
                sys.stdout = f
                #stats.print_stats()
            finally:
                sys.stdout = stdout_backup
        
        print(f"cProfile results saved to {output_file}")
        return result
    
    def _run_with_callgraph(self, 
                          func: Callable, 
                          output_prefix: str, 
                          *args, 
                          **kwargs) -> Any:
        """
        Run a function with pycallgraph and generate a call graph.
        
        Args:
            func: Function to profile
            output_prefix: Prefix for output files
            *args: Arguments to pass to the function
            **kwargs: Keyword arguments to pass to the function
            
        Returns:
            The return value of the function
        """
        print(f"Generating call graph for {func.__name__}...")
        
        # Configure pycallgraph
        output_file = os.path.join(self.output_dir, f"{output_prefix}_callgraph.png")
        graphviz = GraphvizOutput(output_file=output_file)
        config = Config()
        
        # Set filters
        if self.include_patterns or self.exclude_patterns:
            config.trace_filter = GlobbingFilter(
                include=self.include_patterns,
                exclude=self.exclude_patterns
            )
        
        # Run with pycallgraph
        with PyCallGraph(output=graphviz, config=config):
            result = func(*args, **kwargs)
        
        print(f"Call graph saved to {output_file}")
        return result
    
    def _generate_callgraph(self, 
                          func: Callable, 
                          output_prefix: str, 
                          *args, 
                          **kwargs) -> None:
        """
        Generate a call graph for a function without returning result.
        
        Args:
            func: Function to profile
            output_prefix: Prefix for output files
            *args: Arguments to pass to the function
            **kwargs: Keyword arguments to pass to the function
        """
        self._run_with_callgraph(func, output_prefix, *args, **kwargs)
