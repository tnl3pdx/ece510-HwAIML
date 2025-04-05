import numpy as np
from scipy.integrate import solve_ivp
import matplotlib.pyplot as plt

def solve_ode(ode_func, t_span, y0, t_eval=None):
    """Solves an ODE using scipy.integrate.solve_ivp.

    Args:
        ode_func (callable): ODE to solve. Should take t, y and return dy/dt.
        t_span (tuple): Integration interval (t_start, t_end).
        y0 (array_like): Initial condition(s).
        t_eval (array_like, optional): Times to store the solution. If None, the solver selects points.

    Returns:
        sol : Bunch object with fields t (time points) and y (solution values).
    """
    sol = solve_ivp(ode_func, t_span, y0, dense_output=True, t_eval=t_eval)
    return sol

if __name__ == '__main__':
    # Get user input for the ODE
    ode_str = input("Enter the ODE as a function of t and y (e.g., -y): ")
    t_start = float(input("Enter the start time: "))
    t_end = float(input("Enter the end time: "))
    y0_str = input("Enter the initial condition(s) (e.g., 1): ")
    y0 = [float(x) for x in y0_str.split(',')]
    num_points = int(input("Enter the number of points for evaluation: "))

    # Define the ODE function based on user input
    def user_ode(t, y):
        # Evaluate the ODE string with t and y values
        return eval(ode_str, {'t': t, 'y': y, 'np': np})

    t_span = (t_start, t_end)
    t_eval = np.linspace(t_start, t_end, num_points)

    sol = solve_ode(user_ode, t_span, y0, t_eval)

    plt.plot(sol.t, sol.y[0])
    plt.xlabel('t')
    plt.ylabel('y(t)')
    plt.title('Solution of dy/dt = ' + ode_str)
    plt.grid(True)
    plt.show()