
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
                   verbose: bool = False) -> List[float]:
        """
        Train the neuron on multiple examples.
        
        Args:
            inputs: 2D array of input pairs
            targets: Array of target values
            epochs: Number of training iterations
            verbose: Whether to print progress
            
        Returns:
            List of mean squared errors for each epoch
        """
        error_history = []
        
        for epoch in range(epochs):
            errors = []
            for x, y in zip(inputs, targets):
                error = self.train(x, y)
                errors.append(error ** 2)  # squared error
            
            mse = np.mean(errors)
            error_history.append(mse)
            
            if verbose and epoch % 100 == 0:
                print(f"Epoch {epoch}, MSE: {mse:.4f}")
        
        return error_history
    
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
                   verbose: bool = False) -> List[float]:
        """
        Train the network on multiple examples.
        
        Args:
            inputs: 2D array of input pairs
            targets: Array of target values
            epochs: Number of training iterations
            verbose: Whether to print progress
            
        Returns:
            List of mean squared errors for each epoch
        """
        error_history = []
        
        for epoch in range(epochs):
            errors = []
            for x, y in zip(inputs, targets):
                error = self.train(x, y)
                errors.append(error ** 2)  # squared error
            
            mse = np.mean(errors)
            error_history.append(mse)
            
            if verbose and epoch % 100 == 0:
                print(f"Epoch {epoch}, MSE: {mse:.4f}")
        
        return error_history
    
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


def example_usage():
    """Example of how to use the SigmoidNeuron and MultiLayerNetwork classes for learning XOR and NAND."""

    # Parse command line arguments
    
    parser = argparse.ArgumentParser(description="Neural Network Learning Examples")
    parser.add_argument("-f", "--fff", help="a dummy argument to fool ipython", default="1")
    parser.add_argument("--epochs", type=int, default=5000, help="Number of training epochs")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose output during training")
    parser.add_argument("--neurons", type=int, default=3, help="Number of hidden neurons in multi-layer network")
    
    args = parser.parse_args()
    
    epoch_number = args.epochs
    verboseness = args.verbose
    num_neurons = args.neurons

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
    
    # Train the neuron on XOR
    xor_errors = xor_neuron.train_batch(inputs, xor_targets, epochs=epoch_number, verbose=verboseness)
    
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
    
    # Train the neuron on NAND
    nand_errors = nand_neuron.train_batch(inputs, nand_targets, epochs=epoch_number, verbose=verboseness)
    
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
    
    # XOR example with multi-layer network (2 hidden neurons)
    print("\n" + "-" * 50)
    print("XOR PROBLEM EXAMPLE - MULTI-LAYER NETWORK")
    print("-" * 50)
    
    # Initialize multi-layer network with fixed random seed
    xor_network = MultiLayerNetwork(hidden_neurons=num_neurons, learning_rate=0.5, random_state=42)
    
    # Train the network on XOR
    xor_network_errors = xor_network.train_batch(inputs, xor_targets, epochs=epoch_number, verbose=verboseness)
    
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

    # NAND example with multi-layer network (2 hidden neurons)
    print("\n" + "-" * 50)
    print("NAND PROBLEM EXAMPLE - MULTI-LAYER NETWORK")
    print("-" * 50)
    
    # Initialize multi-layer network with fixed random seed
    nand_network = MultiLayerNetwork(hidden_neurons=num_neurons, learning_rate=0.5, random_state=42)
    
    # Train the network on NAND
    nand_network_errors = nand_network.train_batch(inputs, nand_targets, epochs=epoch_number, verbose=verboseness)
    
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
