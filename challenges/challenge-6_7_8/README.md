# Challenge 6, 7, and 8

Challenges 6, 7, and 8 are all related to developing a perceptron, thus they will be contained in the same directory.

In Challenge 6, the goal is to implement a simple neuron that takes in two inputs and uses a sigmoid activation function. The two functions that the neuron needed to learn was NAND and XOR.

In Challenge 7, the goal is to visualize the neuron's line in 2D space and aminate it every step of the weight updated process.

In Challenge 8, the goal is to develop a multi-layer feed-forward perceptron network with backpropagation.

[Log for Challenge 6/7/8](https://docs.google.com/document/d/1fHLvWTa1VuwOcmNT2DHk5nrVDTTodrpD6BzS71KGAKU/edit?usp=sharing)

## Tasks for Challenge 6
    1. Implement a simple neuron (a.k.a. perceptron) with two inputs and a sigmoid activation function.     (DONE)
    2. Use the perceptron learning rule (Google or LLM it) to train the neuron to realize the following binary logic functions:
        a. NAND     (DONE)
        b. XOR      (DONE)

## Tasks for Challenge 7
    1. Visualize the learning process in a 2D-plane by representing the neuron’s “line” that separates the space.   (DONE)
    2. You can turn that in an animated visualization that illustrates every step of the weight updating process as you apply the perceptron rule. (DONE)


## Tasks for Challenge 8
    1. Implement a multi-layer feed-forward perceptron network. The network should have two input neurons, two hidden neurons, and one output neuron.   (DONE)
    2. Implement the backpropagation algorithm to train your network to solve the XOR logical function.     (DONE)

# Summary for Challenge 6/7/8

In this challenge, I was able to produce a working sigmoid neuron model in Python that can be instantiated for a single neuron, or with multiple layers of neurons. The two functions that were learned by the neurons was a NAND and a XOR function.

## Research

My knowledge in modeling neurons was still very to me. So prior to me going into the challenges right away, I first asked the LLM the following prompt:

    What is the sigmoid function that is used to model neurons?

![image](https://github.com/user-attachments/assets/89b14387-960c-4e53-aa42-5a26d7d9203c)

Based on the information provided, the sigmoid function has the following characteristics:

1. Any real-value input can be passed to the function.
2. Provides a value from 0 to 1, useful for binrary classification
3. Also, the function only contains 2 major computations: a division and a exponential computation.

From what I learned in class, neural networks are able to process any kind of input and produce an output from it. Since any real-value input can be passed to a sigmoid function, it fulfills this requirement. Also, the use of an output between 0 and 1 seems useful for the learning of gates since they provide an expected result that is either 1 or 0.

It is also good to look at the computations of the function which contain a division and exponential operation. This may be a heavy computation to perform on hardware, as it would require the use of a FPU to operate on these heavier operations.

With this basis in mind, I continued to Challenge 6

## C6: Single Sigmoid Neuron

## C7: Visualize Neuron's Line and Weights

## C8: Multi-layer Feed-Forward Neural Network







