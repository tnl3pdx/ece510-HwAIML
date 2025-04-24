#%% python --epochs 2000 --verbose True --neurons 5


import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from typing import Union, List, Tuple, Optional
import argparse


class SigmoidNeuron:
    """
    A perceptron model with sigmoid activation function that has two inputs.
    Capable of learning through gradient descent.
    """
    
    def __init__(self, learning_rate: float = 0.1, random_state: int = None):
        """
        Initialize the sigmoid neuron with random weights.
        
        Args:
            learning_rate: The step size for gradient descent updates
            random_state: Seed for reproducible weight initialization
        """
        # Set the random seed if provided
        if random_state is not None:
            np.random.seed(random_state)
            
        # Initialize weights and bias with small random values
        self.weights = np.random.randn(2) * 0.1  # two input weights
        self.bias = np.random.randn() * 0.1
        self.learning_rate = learning_rate
        
    def sigmoid(self, x: Union[float, np.ndarray]) -> Union[float, np.ndarray]:
        """
        Sigmoid activation function.
        
        Args:
            x: Input value(s)
            
        Returns:
            Output from sigmoid function
        """
        return 1 / (1 + np.exp(-x))
        
    def sigmoid_derivative(self, x: Union[float, np.ndarray]) -> Union[float, np.ndarray]:
        """
        Derivative of sigmoid function, used in backpropagation.
        
        Args:
            x: Input value(s) (sigmoid output)
            
        Returns:
            Derivative value(s)
        """
        return x * (1 - x)
        
    def forward(self, inputs: np.ndarray) -> float:
        """
        Calculate the neuron output for given inputs.
        
        Args:
            inputs: Array of two input values
            
        Returns:
            Neuron output after sigmoid activation
        """
        if len(inputs) != 2:
            raise ValueError("This neuron expects exactly 2 inputs")
        
        # Calculate weighted sum
        weighted_sum = np.dot(inputs, self.weights) + self.bias

        # Apply activation function
        return self.sigmoid(weighted_sum)
    
    def train(self, inputs: np.ndarray, target: float) -> float:
        """
        Train the neuron using gradient descent.
        
        Args:
            inputs: Array of two input values
            target: Expected output value (0 or 1)
            
        Returns:
            Error value for this training step
        """
        # Forward pass
        output = self.forward(inputs)
        
        # Calculate error
        error = target - output
        
        # Backpropagation
        delta = error * self.sigmoid_derivative(output)
        
        # Update weights and bias
        self.weights += self.learning_rate * delta * inputs
        self.bias += self.learning_rate * delta
        
        return error
    
    def train_batch(self, inputs: np.ndarray, targets: np.ndarray, epochs: int = 1000, 
                   verbose: bool = False, log_interval: int = 50) -> Union[List[float], Tuple]:
        """
        Train the neuron on multiple examples and optionally log weights for animation.
        
        Args:
            inputs: 2D array of input pairs
            targets: Array of target values
            epochs: Number of training iterations
            verbose: Whether to print progress
            log_interval: How often to log weights for animation
            
        Returns:
            If log_interval > 0: Tuple of (error_history, weight_history)
            Otherwise: List of mean squared errors for each epoch
        """
        error_history = []
        weight_history = []  # List to store weight snapshots
        
        # Store initial weights
        weight_history.append((self.weights.copy(), self.bias))
        
        for epoch in range(epochs):
            errors = []
            for x, y in zip(inputs, targets):
                error = self.train(x, y)
                errors.append(error ** 2)  # squared error
            
            mse = np.mean(errors)
            error_history.append(mse)
            
            # Periodically log weights
            if epoch % log_interval == 0 or epoch == epochs - 1:
                weight_history.append((self.weights.copy(), self.bias))
            
            if verbose and epoch % 100 == 0:
                print(f"Epoch {epoch}, MSE: {mse:.4f}")
        
        return error_history, weight_history
    
    def predict(self, inputs: np.ndarray, threshold: float = 0.5) -> Union[int, np.ndarray]:
        """
        Make binary predictions based on a threshold.
        
        Args:
            inputs: Input array (single sample or batch)
            threshold: Classification threshold
            
        Returns:
            Binary prediction(s)
        """
        # Handle both single sample and batch inputs
        if inputs.ndim == 1:
            output = self.forward(inputs)
            return 1 if output >= threshold else 0
        else:
            predictions = []
            for x in inputs:
                output = self.forward(x)
                predictions.append(1 if output >= threshold else 0)
            return np.array(predictions)
    
    def get_weights(self) -> Tuple[np.ndarray, float]:
        """
        Get the current weights and bias.
        
        Returns:
            Tuple of (weights, bias)
        """
        return self.weights, self.bias
    
    def set_weights(self, weights: np.ndarray, bias: float) -> None:
        """
        Set the weights and bias directly.
        
        Args:
            weights: Array of two weight values
            bias: Bias value
        """
        if len(weights) != 2:
            raise ValueError("This neuron expects exactly 2 weights")
        
        self.weights = weights.copy()
        self.bias = bias
        
    def visualize_decision_boundary(self, inputs: np.ndarray, targets: np.ndarray) -> None:
        """
        Visualize the decision boundary of the perceptron.
        
        Args:
            inputs: 2D array of input pairs
            targets: Array of target values
        """
        # Create a mesh grid
        x_min, x_max = inputs[:, 0].min() - 0.5, inputs[:, 0].max() + 0.5
        y_min, y_max = inputs[:, 1].min() - 0.5, inputs[:, 1].max() + 0.5
        h = 0.01
        xx, yy = np.meshgrid(np.arange(x_min, x_max, h), np.arange(y_min, y_max, h))
        
        # Predict class labels for each point in the mesh
        Z = np.array([self.predict(np.array([x, y])) for x, y in zip(xx.ravel(), yy.ravel())])
        Z = Z.reshape(xx.shape)
        
        # Plot the decision boundary
        plt.figure(figsize=(6, 4))
        plt.contourf(xx, yy, Z, alpha=0.3)
        plt.scatter(inputs[:, 0], inputs[:, 1], c=targets, edgecolors='k', marker='o')
        plt.xlabel('Input 1')
        plt.ylabel('Input 2')
        plt.title('Decision Boundary')
        plt.grid(True)
        plt.show()
    
    def animate_decision_boundary(self, inputs: np.ndarray, targets: np.ndarray, 
                                 weight_history: List, save_path: str = None,
                                 dpi: int = 70, fps: int = 5, log_interval = 100) -> None:
        """
        Create animation showing how the decision boundary evolves during training.
        
        Args:
            inputs: 2D array of input pairs
            targets: Array of target values
            weight_history: List of (weights, bias) tuples from training
            save_path: Path to save the animation
            dpi: Resolution for the saved animation
            fps: Frames per second for the animation
        """
        # Store original weights to restore later
        orig_weights, orig_bias = self.weights.copy(), self.bias
        
        # Create mesh grid (using coarser grid for performance)
        x_min, x_max = inputs[:, 0].min() - 0.5, inputs[:, 0].max() + 0.5
        y_min, y_max = inputs[:, 1].min() - 0.5, inputs[:, 1].max() + 0.5
        h = 0.02  # Coarser grid for better performance
        xx, yy = np.meshgrid(np.arange(x_min, x_max, h), np.arange(y_min, y_max, h))
        
        # Initialize figure
        fig, ax = plt.subplots(figsize=(6, 5))
        
        # Function to update the plot for each frame
        def update(frame):
            # Update weights to those at this frame
            self.weights, self.bias = weight_history[frame]
            
            # Clear the axis for new frame
            ax.clear()
            
            # Calculate decision boundary
            Z = np.array([self.predict(np.array([x, y])) for x, y in zip(xx.ravel(), yy.ravel())])
            Z = Z.reshape(xx.shape)
            
            # Draw filled contour and data points
            ax.contourf(xx, yy, Z, alpha=0.3)
            ax.scatter(inputs[:, 0], inputs[:, 1], c=targets, edgecolors='k', marker='o')
            
            # Calculate current MSE
            errors = []
            for x, y in zip(inputs, targets):
                out = self.forward(x)
                errors.append((y - out) ** 2)
            mse = np.mean(errors)
            
            # Display epoch info and weight values
            frame_epoch = frame * log_interval
            ax.set_title(f"{save_path}: Decision Boundary Evolution\nEpoch {frame_epoch}")
            ax.text(0.05, 0.05, 
                   f"w1: {self.weights[0]:.3f}\nw2: {self.weights[1]:.3f}\nbias: {self.bias:.3f}\nMSE: {mse:.6f}", 
                   transform=ax.transAxes, bbox=dict(facecolor='white', alpha=0.7)) 
            
            # Set labels and grid
            ax.set_xlabel('Input 1')
            ax.set_ylabel('Input 2')
            ax.grid(True)
            
            return ax,
        
        # Create animation
        ani = animation.FuncAnimation(fig, update, frames=len(weight_history), interval=200)
        
        # Save or show the animation
        if save_path:
            ani.save(save_path, writer='pillow', fps=fps, dpi=dpi)
            plt.close(fig)
            print(f"Animation saved to {save_path}")
        else:
            plt.tight_layout()
            plt.show()
        
        # Restore original weights
        self.weights, self.bias = orig_weights, orig_bias


class MultiLayerNetwork:
    """
    A multi-layer neural network with sigmoid activation function.
    Configurable number of neurons in the hidden layer.
    Capable of learning through backpropagation.
    """
    
    def __init__(self, hidden_neurons: int = 2, learning_rate: float = 0.1, random_state: Optional[int] = None):
        """
        Initialize the multi-layer network with random weights.
        
        Args:
            hidden_neurons: Number of neurons in the hidden layer
            learning_rate: The step size for gradient descent updates
            random_state: Seed for reproducible weight initialization
        """
        # Set the random seed if provided
        if random_state is not None:
            np.random.seed(random_state)
        
        self.hidden_neurons = hidden_neurons
        self.learning_rate = learning_rate
        
        # Initialize weights and biases with small random values
        # Layer 1: 2 inputs -> hidden_neurons
        self.weights1 = np.random.randn(2, hidden_neurons) * 0.1
        self.bias1 = np.random.randn(hidden_neurons) * 0.1
        
        # Layer 2: hidden_neurons -> 1 output
        self.weights2 = np.random.randn(hidden_neurons) * 0.1
        self.bias2 = np.random.randn() * 0.1
    
    def sigmoid(self, x: np.ndarray) -> np.ndarray:
        """
        Sigmoid activation function.
        """
        return 1 / (1 + np.exp(-x))
    
    def sigmoid_derivative(self, x: np.ndarray) -> np.ndarray:
        """
        Derivative of sigmoid function.
        """
        return x * (1 - x)
    
    def forward(self, inputs: np.ndarray) -> Tuple[float, np.ndarray]:
        """
        Calculate network output for given inputs.
        
        Args:
            inputs: Array of two input values
            
        Returns:
            Network output after sigmoid activation and hidden layer activations
        """
        if len(inputs) != 2:
            raise ValueError("This network expects exactly 2 inputs")
        
        # First layer
        self.hidden_inputs = np.dot(inputs, self.weights1) + self.bias1
        self.hidden_outputs = self.sigmoid(self.hidden_inputs)
        
        # Output layer
        self.output_input = np.dot(self.hidden_outputs, self.weights2) + self.bias2
        self.output = self.sigmoid(self.output_input)
        
        return self.output, self.hidden_outputs
    
    def train(self, inputs: np.ndarray, target: float) -> float:
        """
        Train the network using backpropagation.
        
        Args:
            inputs: Array of two input values
            target: Expected output value (0 or 1)
            
        Returns:
            Error value for this training step
        """
        # Forward pass
        output, _ = self.forward(inputs)
        
        # Calculate error
        error = target - output
        
        # Backpropagation for output layer
        d_output = error * self.sigmoid_derivative(output)
        
        # Backpropagation for hidden layer
        d_hidden = np.dot(d_output, self.weights2) * self.sigmoid_derivative(self.hidden_outputs)
        
        # Update weights and biases
        self.weights2 += self.learning_rate * d_output * self.hidden_outputs
        self.bias2 += self.learning_rate * d_output
        
        self.weights1 += self.learning_rate * np.outer(inputs, d_hidden)
        self.bias1 += self.learning_rate * d_hidden
        
        return error
    
    def train_batch(self, inputs: np.ndarray, targets: np.ndarray, epochs: int = 1000, 
                   verbose: bool = False, log_interval: int = 50) -> Union[List[float], Tuple]:
        """
        Train the network on multiple examples and optionally log weights for animation.
        
        Args:
            inputs: 2D array of input pairs
            targets: Array of target values
            epochs: Number of training iterations
            verbose: Whether to print progress
            log_interval: How often to log network state
            
        Returns:
            If log_interval > 0: Tuple of (error_history, weight_history)
            Otherwise: List of mean squared errors for each epoch
        """
        error_history = []
        weight_history = []  # List to store weight snapshots
        
        # Store initial weights
        weight_history.append((
            self.weights1.copy(), 
            self.bias1.copy(), 
            self.weights2.copy(), 
            self.bias2
        ))
        
        for epoch in range(epochs):
            errors = []
            for x, y in zip(inputs, targets):
                error = self.train(x, y)
                errors.append(error ** 2)  # squared error
            
            mse = np.mean(errors)
            error_history.append(mse)
            
            # Periodically log weights
            if epoch % log_interval == 0 or epoch == epochs - 1:
                weight_history.append((
                    self.weights1.copy(), 
                    self.bias1.copy(), 
                    self.weights2.copy(), 
                    self.bias2
                ))
            
            if verbose and epoch % 100 == 0:
                print(f"Epoch {epoch}, MSE: {mse:.4f}")
        
        return error_history, weight_history
    
    def predict(self, inputs: np.ndarray, threshold: float = 0.5) -> Union[int, np.ndarray]:
        """
        Make binary predictions based on a threshold.
        
        Args:
            inputs: Input array (single sample or batch)
            threshold: Classification threshold
            
        Returns:
            Binary prediction(s)
        """
        # Handle both single sample and batch inputs
        if inputs.ndim == 1:
            output, _ = self.forward(inputs)
            return 1 if output >= threshold else 0
        else:
            predictions = []
            for x in inputs:
                output, _ = self.forward(x)
                predictions.append(1 if output >= threshold else 0)
            return np.array(predictions)
    
    def get_weights(self) -> Tuple[np.ndarray, np.ndarray, np.ndarray, float]:
        """
        Get the current weights and biases.
        
        Returns:
            Tuple of (weights1, bias1, weights2, bias2)
        """
        return self.weights1, self.bias1, self.weights2, self.bias2
    
    def visualize_decision_boundary(self, inputs: np.ndarray, targets: np.ndarray) -> None:
        """
        Visualize the decision boundary of the network.
        
        Args:
            inputs: 2D array of input pairs
            targets: Array of target values
        """
        # Create a mesh grid
        x_min, x_max = inputs[:, 0].min() - 0.5, inputs[:, 0].max() + 0.5
        y_min, y_max = inputs[:, 1].min() - 0.5, inputs[:, 1].max() + 0.5
        h = 0.01
        xx, yy = np.meshgrid(np.arange(x_min, x_max, h), np.arange(y_min, y_max, h))
        
        # Predict class labels for each point in the mesh
        Z = np.array([self.predict(np.array([x, y])) for x, y in zip(xx.ravel(), yy.ravel())])
        Z = Z.reshape(xx.shape)
        
        # Plot the decision boundary
        plt.figure(figsize=(6, 4))
        plt.contourf(xx, yy, Z, alpha=0.3)
        plt.scatter(inputs[:, 0], inputs[:, 1], c=targets, edgecolors='k', marker='o')
        plt.xlabel('Input 1')
        plt.ylabel('Input 2')
        plt.title('Decision Boundary')
        plt.grid(True)
        plt.show()
    
    def animate_decision_boundary(self, inputs: np.ndarray, targets: np.ndarray, 
                                 weight_history: List, save_path: str = None,
                                 dpi: int = 70, fps: int = 5, log_interval = 100) -> None:
        """
        Create animation showing how the decision boundary evolves during training.
        
        Args:
            inputs: 2D array of input pairs
            targets: Array of target values
            weight_history: List of weight tuples from training
            save_path: Path to save the animation
            dpi: Resolution for the saved animation
            fps: Frames per second for the animation
        """
        # Store original weights to restore later
        orig_w1 = self.weights1.copy()
        orig_b1 = self.bias1.copy()
        orig_w2 = self.weights2.copy()
        orig_b2 = self.bias2
        
        # Create mesh grid (using coarser grid for performance)
        x_min, x_max = inputs[:, 0].min() - 0.5, inputs[:, 0].max() + 0.5
        y_min, y_max = inputs[:, 1].min() - 0.5, inputs[:, 1].max() + 0.5
        h = 0.02  # Coarser grid for better performance
        xx, yy = np.meshgrid(np.arange(x_min, x_max, h), np.arange(y_min, y_max, h))
        
        # Initialize figure
        fig, ax = plt.subplots(figsize=(6, 5))
        
        # Function to update the plot for each frame
        def update(frame):
            # Update weights to those at this frame
            self.weights1, self.bias1, self.weights2, self.bias2 = weight_history[frame]
            
            # Clear the axis for new frame
            ax.clear()
            
            # Calculate decision boundary
            Z = np.array([self.predict(np.array([x, y])) for x, y in zip(xx.ravel(), yy.ravel())])
            Z = Z.reshape(xx.shape)
            
            # Draw filled contour and data points
            ax.contourf(xx, yy, Z, alpha=0.3)
            ax.scatter(inputs[:, 0], inputs[:, 1], c=targets, edgecolors='k', marker='o')
            
            # Display epoch info and network details
            frame_epoch = frame * log_interval
            ax.set_title(f"{save_path}: Decision Boundary Evolution\nEpoch {frame_epoch}")
            
            # Calculate current MSE
            errors = []
            for x, y in zip(inputs, targets):
                out, _ = self.forward(x)
                errors.append((y - out) ** 2)
            mse = np.mean(errors)
            
            # Display network info
            ax.text(0.05, 0.05, 
                   f"Hidden neurons: {self.hidden_neurons}\nMSE: {mse:.6f}", 
                   transform=ax.transAxes, bbox=dict(facecolor='white', alpha=0.7))
            
            # Set labels and grid
            ax.set_xlabel('Input 1')
            ax.set_ylabel('Input 2')
            ax.grid(True)
            
            return ax,
        
        # Create animation
        ani = animation.FuncAnimation(fig, update, frames=len(weight_history), interval=200)
        
        # Save or show the animation
        if save_path:
            ani.save(save_path, writer='pillow', fps=fps, dpi=dpi)
            plt.close(fig)
            print(f"Animation saved to {save_path}")
        else:
            plt.tight_layout()
            plt.show()
        
        # Restore original weights
        self.weights1, self.bias1, self.weights2, self.bias2 = orig_w1, orig_b1, orig_w2, orig_b2


def example_usage():
    """Example of how to use the SigmoidNeuron and MultiLayerNetwork classes for learning XOR and NAND."""

    # Add new command line arguments for animation
    parser = argparse.ArgumentParser(description="Neural Network Learning Examples")
    parser.add_argument("-f", "--fff", help="a dummy argument to fool ipython", default="1")
    parser.add_argument("--epochs", type=int, default=12500, help="Number of training epochs")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose output during training")
    parser.add_argument("--neurons", type=int, default=2, help="Number of hidden neurons in multi-layer network")
    parser.add_argument("--no-animate", action="store_true", help="Don't generate decision boundary animations")
    parser.add_argument("--log-interval", type=int, default=250, help="Interval for logging animation frames")
    parser.add_argument("--dpi", type=int, default=150, help="DPI for saved animation")
    
    args = parser.parse_args()
    
    epoch_number = args.epochs
    verboseness = args.verbose
    num_neurons = args.neurons
    no_animate = args.no_animate
    log_interval = args.log_interval
    dpi = args.dpi

    # Common inputs for both problems
    inputs = np.array([
        [0, 0],
        [0, 1],
        [1, 0],
        [1, 1]
    ])
    
    # XOR example with single neuron
    print("-" * 50)
    print("XOR PROBLEM EXAMPLE - SINGLE NEURON")
    print("-" * 50)
    xor_targets = np.array([0, 1, 1, 0])
    
    print("XOR Problem: Note that a single perceptron cannot learn XOR perfectly")
    
    # Initialize neuron with fixed random seed
    xor_neuron = SigmoidNeuron(learning_rate=0.2, random_state=42)
    
    # Train the neuron on XOR (with animation if requested)
    if not no_animate:
        xor_errors, xor_weights = xor_neuron.train_batch(
            inputs, xor_targets, epochs=epoch_number, 
            verbose=verboseness, log_interval=log_interval
        )
        # Generate animation after training
        xor_neuron.animate_decision_boundary(
            inputs, xor_targets, xor_weights, 
            save_path="xor_neuron_boundary.gif", dpi=dpi, fps=5, log_interval=log_interval
        )
    else:
        xor_errors, _ = xor_neuron.train_batch(inputs, xor_targets, epochs=epoch_number, verbose=verboseness)
    
    # Print final predictions for XOR
    print("\nFinal XOR predictions (single neuron - " + str(epoch_number) + " iterations):")
    for input_pair, target in zip(inputs, xor_targets):
        output = xor_neuron.forward(input_pair)
        prediction = xor_neuron.predict(input_pair)
        print(f"Input: {input_pair}, Target: {target}, Output: {output:.4f}, Prediction: {prediction}")
    
    # Plot XOR error history
    plt.figure(figsize=(6, 4))
    plt.plot(xor_errors)
    plt.xlabel('Epoch')
    plt.ylabel('Mean Squared Error')
    plt.title('XOR Learning Curve (Single Neuron)')
    plt.grid(True)
    plt.show()
    
    # Visualize XOR decision boundary
    xor_neuron.visualize_decision_boundary(inputs, xor_targets)
    
    # Show learned XOR weights
    weights, bias = xor_neuron.get_weights()
    print(f"\nLearned XOR weights (single neuron): {weights}, bias: {bias:.4f}")
    
    # NAND example with single neuron
    print("\n" + "-" * 50)
    print("NAND PROBLEM EXAMPLE - SINGLE NEURON")
    print("-" * 50)
    nand_targets = np.array([1, 1, 1, 0])
    
    print("NAND Problem: This should be learnable by a single perceptron")
    
    # Initialize neuron with fixed random seed
    nand_neuron = SigmoidNeuron(learning_rate=0.2, random_state=42)
    
    # Train the neuron on NAND (with animation if requested)
    if not no_animate:
        nand_errors, nand_weights = nand_neuron.train_batch(
            inputs, nand_targets, epochs=epoch_number, 
            verbose=verboseness, log_interval=log_interval
        )
        # Generate animation after training
        nand_neuron.animate_decision_boundary(
            inputs, nand_targets, nand_weights, 
            save_path="nand_neuron_boundary.gif", dpi=dpi, fps=5, log_interval=log_interval
        )
    else:
        nand_errors, _ = nand_neuron.train_batch(inputs, nand_targets, epochs=epoch_number, verbose=verboseness)
    
    # Print final predictions for NAND
    print("\nFinal NAND predictions (single neuron - " + str(epoch_number) + " iterations)):")
    for input_pair, target in zip(inputs, nand_targets):
        output = nand_neuron.forward(input_pair)
        prediction = nand_neuron.predict(input_pair)
        print(f"Input: {input_pair}, Target: {target}, Output: {output:.4f}, Prediction: {prediction}")
    
    # Plot NAND error history
    plt.figure(figsize=(6, 4))
    plt.plot(nand_errors)
    plt.xlabel('Epoch')
    plt.ylabel('Mean Squared Error')
    plt.title('NAND Learning Curve (Single Neuron)')
    plt.grid(True)
    plt.show()
    
    # Visualize NAND decision boundary
    nand_neuron.visualize_decision_boundary(inputs, nand_targets)
    
    # Show learned NAND weights
    weights, bias = nand_neuron.get_weights()
    print(f"\nLearned NAND weights (single neuron): {weights}, bias: {bias:.4f}")
    
    # XOR example with multi-layer network
    print("\n" + "-" * 50)
    print("XOR PROBLEM EXAMPLE - MULTI-LAYER NETWORK")
    print("-" * 50)
    
    # Initialize multi-layer network with fixed random seed
    xor_network = MultiLayerNetwork(hidden_neurons=num_neurons, learning_rate=0.5, random_state=42)
    
    # Train the network on XOR (with animation if requested)
    if not no_animate:
        xor_network_errors, xor_network_weights = xor_network.train_batch(
            inputs, xor_targets, epochs=epoch_number, 
            verbose=verboseness, log_interval=log_interval
        )
        # Generate animation after training
        xor_network.animate_decision_boundary(
            inputs, xor_targets, xor_network_weights, 
            save_path="xor_network_boundary.gif", dpi=dpi, fps=5, log_interval=log_interval
        )
    else:
        xor_network_errors, _ = xor_network.train_batch(inputs, xor_targets, epochs=epoch_number, verbose=verboseness)
    
    # Print final predictions for XOR
    print("\nFinal XOR predictions (multi-layer network - " + str(xor_network.hidden_neurons) + " neurons - " + str(epoch_number) + " iterations):")
    for input_pair, target in zip(inputs, xor_targets):
        output, _ = xor_network.forward(input_pair)
        prediction = xor_network.predict(input_pair)
        print(f"Input: {input_pair}, Target: {target}, Output: {output:.4f}, Prediction: {prediction}")
    
    # Plot XOR error history
    plt.figure(figsize=(6, 4))
    plt.plot(xor_network_errors)
    plt.xlabel('Epoch')
    plt.ylabel('Mean Squared Error')
    plt.title('XOR Learning Curve (Multi-Layer Network)')
    plt.grid(True)
    plt.show()
    
    # Visualize XOR decision boundary
    xor_network.visualize_decision_boundary(inputs, xor_targets)

    # NAND example with multi-layer network
    print("\n" + "-" * 50)
    print("NAND PROBLEM EXAMPLE - MULTI-LAYER NETWORK")
    print("-" * 50)
    
    # Initialize multi-layer network with fixed random seed
    nand_network = MultiLayerNetwork(hidden_neurons=num_neurons, learning_rate=0.5, random_state=42)
    
    # Train the network on NAND (with animation if requested)
    if not no_animate:
        nand_network_errors, nand_network_weights = nand_network.train_batch(
            inputs, nand_targets, epochs=epoch_number, 
            verbose=verboseness, log_interval=log_interval
        )
        # Generate animation after training
        nand_network.animate_decision_boundary(
            inputs, nand_targets, nand_network_weights, 
            save_path="nand_network_boundary.gif", dpi=dpi, fps=5, log_interval=log_interval
        )
    else:
        nand_network_errors, _ = nand_network.train_batch(inputs, nand_targets, epochs=epoch_number, verbose=verboseness)
    
    # Print final predictions for NAND
    print("\nFinal NAND predictions (multi-layer network - " + str(nand_network.hidden_neurons) + " neurons - " + str(epoch_number) + " iterations):")
    for input_pair, target in zip(inputs, nand_targets):
        output, _ = nand_network.forward(input_pair)
        prediction = nand_network.predict(input_pair)
        print(f"Input: {input_pair}, Target: {target}, Output: {output:.4f}, Prediction: {prediction}")
    
    # Plot NAND error history
    plt.figure(figsize=(6, 4))
    plt.plot(nand_network_errors)
    plt.xlabel('Epoch')
    plt.ylabel('Mean Squared Error')
    plt.title('NAND Learning Curve (Multi-Layer Network)')
    plt.grid(True)
    plt.show()
    
    # Visualize NAND decision boundary
    nand_network.visualize_decision_boundary(inputs, nand_targets)
    
    # Compare results
    print("\n" + "-" * 50)
    print("COMPARISON OF RESULTS")
    print("-" * 50)
    print("Single Neuron XOR final MSE: {:.6f}".format(xor_errors[-1]))
    print("Multi-layer Network XOR final MSE: {:.6f}".format(xor_network_errors[-1]))
    print("Single Neuron NAND final MSE: {:.6f}".format(nand_errors[-1]))
    print("Multi-layer Network NAND final MSE: {:.6f}".format(nand_network_errors[-1]))
    print("\nNote: A single perceptron struggles with XOR but the multi-layer network can learn it well")
    print("Both types of networks can learn NAND, as it is linearly separable")


if __name__ == "__main__":
    example_usage()
# %%
