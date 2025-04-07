import ast
import os
from tabulate import tabulate

class ScriptAnalyzer(ast.NodeVisitor):
    def __init__(self):
        self.functions = {}
        self.variables = set()
        self.loops = 0
        self.conditionals = 0
        self.function_calls = {}
    
    def visit_FunctionDef(self, node):
        """Extract function definitions and their arguments."""
        self.functions[node.name] = [arg.arg for arg in node.args.args]
        self.generic_visit(node)

    def visit_Assign(self, node):
        """Track variable assignments."""
        for target in node.targets:
            if isinstance(target, ast.Name):
                self.variables.add(target.id)
        self.generic_visit(node)

    def visit_For(self, node):
        """Count loop structures."""
        self.loops += 1
        self.generic_visit(node)

    def visit_While(self, node):
        """Count while loops."""
        self.loops += 1
        self.generic_visit(node)

    def visit_If(self, node):
        """Count conditionals."""
        self.conditionals += 1
        self.generic_visit(node)

    def visit_Call(self, node):
        """Track function calls and dependencies."""
        if isinstance(node.func, ast.Name):
            func_name = node.func.id
            if func_name in self.function_calls:
                self.function_calls[func_name] += 1
            else:
                self.function_calls[func_name] = 1
        self.generic_visit(node)

def analyze_script(filepath):
    """Reads and analyzes the Python script from a given filepath."""
    analysis_results = {}
    try:
        with open(filepath, "r", encoding="utf-8") as file:
            code = file.read()
        tree = ast.parse(code)
        analyzer = ScriptAnalyzer()
        analyzer.visit(tree)

        analysis_results['functions'] = len(analyzer.functions)
        analysis_results['variables'] = len(analyzer.variables)
        analysis_results['loops'] = analyzer.loops
        analysis_results['conditionals'] = analyzer.conditionals
        analysis_results['function_calls'] = sum(analyzer.function_calls.values())

        return analysis_results
    except Exception as e:
        print(f"Error analyzing script {filepath}: {e}")
        return None

def main():
    """Analyzes multiple script files and prints a tabulated report."""
    filepaths = input("Enter the Python script filepaths, separated by commas: ").strip().split(',')
    filepaths = [fp.strip() for fp in filepaths]

    all_results = {}
    for filepath in filepaths:
        filename = os.path.basename(filepath)
        all_results[filename] = analyze_script(filepath)

    # Prepare data for tabulate
    headers = ["Metric"] + [os.path.basename(fp) for fp in filepaths]
    table_data = [
        ["Functions Defined"] + [all_results[os.path.basename(fp)]['functions'] if all_results[os.path.basename(fp)] else "Error" for fp in filepaths],
        ["Variables Used"] + [all_results[os.path.basename(fp)]['variables'] if all_results[os.path.basename(fp)] else "Error" for fp in filepaths],
        ["Loops Found"] + [all_results[os.path.basename(fp)]['loops'] if all_results[os.path.basename(fp)] else "Error" for fp in filepaths],
        ["Conditionals Found"] + [all_results[os.path.basename(fp)]['conditionals'] if all_results[os.path.basename(fp)] else "Error" for fp in filepaths],
        ["Function Calls"] + [all_results[os.path.basename(fp)]['function_calls'] if all_results[os.path.basename(fp)] else "Error" for fp in filepaths],
    ]

    print(tabulate(table_data, headers=headers, tablefmt="grid"))

if __name__ == "__main__":
    main()
