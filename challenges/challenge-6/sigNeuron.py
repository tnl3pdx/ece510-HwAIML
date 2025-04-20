import numpy as np
import matplotlib.pyplot as plt
from typing import Union, List, Tuple


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
        plt.figure(figsize=(10, 8))
        plt.contourf(xx, yy, Z, alpha=0.3)
        plt.scatter(inputs[:, 0], inputs[:, 1], c=targets, edgecolors='k', marker='o')
        plt.xlabel('Input 1')
        plt.ylabel('Input 2')
        plt.title('Decision Boundary')
        plt.grid(True)
        plt.show()


def example_usage():
    """Example of how to use the SigmoidNeuron class for learning XOR."""
    # XOR problem inputs and targets
    inputs = np.array([
        [0, 0],
        [0, 1],
        [1, 0],
        [1, 1]
    ])
    
    targets = np.array([0, 1, 1, 0])
    
    print("XOR Problem: Note that a single perceptron cannot learn XOR perfectly")
    print("This example demonstrates the API usage")
    
    # Initialize neuron with fixed random seed
    neuron = SigmoidNeuron(learning_rate=0.2, random_state=42)
    
    # Train the neuron
    errors = neuron.train_batch(inputs, targets, epochs=5000, verbose=True)
    
    # Print final predictions
    print("\nFinal predictions:")
    for input_pair in inputs:
        output = neuron.forward(input_pair)
        prediction = neuron.predict(input_pair)
        print(f"Input: {input_pair}, Output: {output:.4f}, Prediction: {prediction}")
    
    # Plot error history
    plt.figure(figsize=(10, 6))
    plt.plot(errors)
    plt.xlabel('Epoch')
    plt.ylabel('Mean Squared Error')
    plt.title('Learning Curve')
    plt.grid(True)
    plt.show()
    
    # Visualize decision boundary
    neuron.visualize_decision_boundary(inputs, targets)
    
    # Show how to get and set weights
    weights, bias = neuron.get_weights()
    print(f"\nLearned weights: {weights}, bias: {bias:.4f}")


if __name__ == "__main__":
    example_usage()