import math

def sigmoid(x):
    return 1 / (1 + math.exp(-1))

def sigmoid_loss(output, target):
    assert(len(output) == len(target)), "Sizes do not match"
    sig_o = [sigmoid(o) for o in output] 
    diff = [(sig_o[i] - target[i]) ** 2 for i in range(len(target))]
    loss = sum(diff) / len(diff)
    return loss

def L1_loss(output, target):
    diff = [abs(output[i] - target[i]) for i in range(len(target))]
    loss = sum(diff) / len(diff)
    return loss

def MSE_loss(output, target):
    diff = [(output[i] - target[i]) **2 for i in range(len(target))]
    loss = sum(diff) / len(diff)
    return loss

class Vector:
    def __init__(self, values: list) -> None:
        self.values = values
        self.length = len(values)
        # self.index = 0

    def __len__(self):
        return self.length

    def __iter__(self):
        return iter(self.values)
    
    def __mul__(self, other):
        if isinstance(other, Vector):
            if self.length != other.length:
                raise ValueError("Vectors must have the same dimensions for dot product")
            return sum(a * b for a, b in zip(self.values, other.values))
        elif isinstance(other, Matrix):
            raise ValueError("Vector-matrix multiplication isn't defined in this order. Use matrix-vector multiplication instead.")
        else:
            raise ValueError("Multiplication with type {} not supported.".format(type(other)))
        
    def __add__(self, other):
        if isinstance(other, Vector):
            if self.length != other.length:
                raise ValueError("Vectors must have the same dimensions for dot product")
            # for a, b in zip(self.values, other.values):
            #     print(a, b)
            #     print(float(a) + float(b))
            return Vector([float(a) + float(b) for a, b in zip(self.values, other.values)])
        elif isinstance(other, Matrix):
            raise ValueError("Vector-matrix multiplication isn't defined in this order. Use matrix-vector multiplication instead.")
        else:
            raise ValueError("Multiplication with type {} not supported.".format(type(other)))
    
    def __rmul__(self, other):
        if isinstance(other, Matrix):
            if other.vectors.length != self.length:
                raise ValueError("Number of matrix columns must match vector dimension for multiplication.")
            result = [vector * self for vector in other.vectors]
            return Vector(result)
        else:
            raise ValueError("Multiplication with type {} not supported.".format(type(other)))
        
    def relu(self):
        return Vector([max(0, v) for v in self.values])
    
    def backward(self, output_gradient):
        # Assuming output_gradient is a Vector of the same size as self.values
        # This would compute the derivative of the upstream gradient with respect to this Vector's values
        return self * output_gradient
    
    def __str__(self):
        vector_str = ','.join(str(value) for value in self.values)
        return f"[{vector_str}]"
        
class Matrix:
    def __init__(self, vectors: list[Vector]|list[list]) -> None:
        self.vectors = vectors if isinstance(vectors[0], Vector) else list(Vector(v) for v in vectors)
        self.length = len(vectors)
        # self.index = 0
    
    def __iter__(self):
        return iter(self.vectors)
    
    def __len__(self):
        return self.length
        
    def __add__(self, other):
        if isinstance(other, Matrix):
            # Matrix-Matrix addition
            if len(self.vectors) != len(other.vectors) or len(self.vectors[0].values) != len(other.vectors[0].values):
                raise ValueError("Matrices must have the same dimensions for addition.")
            result = []
            for v1, v2 in zip(self.vectors, other.vectors):
                result.append(v1 + v2)
            return Matrix(result)
        else:
            raise ValueError("Addition with type {} not supported.".format(type(other)))
        
    def __mul__(self, other):
        if isinstance(other, Vector):
            # Matrix-vector multiplication
            if len(self.vectors[0].values) != len(other.values):
                raise ValueError("Number of matrix columns must match vector dimension for multiplication.")
            result = [Vector(row.values) * other for row in self.vectors]
            return Vector(result)
        elif isinstance(other, Matrix):
            # Matrix-matrix multiplication
            if len(self.vectors[0].values) != len(other.vectors):
                raise ValueError("Number of columns in first matrix must match number of rows in second matrix.")
            result = []
            other_transposed = list(zip(*[vector.values for vector in other.vectors]))
            for row in self.vectors:
                new_row = [Vector(row.values) * Vector(column) for column in other_transposed]
                result.append(Vector(new_row))
            return Matrix(result)
        else:
            raise ValueError("Multiplication with type {} not supported.".format(type(other)))
        
    def relu(self):
        return Matrix([v.relu() for v in self.vectors])
    
    def __str__(self):
        matrix_str = ','.join(str(vector) for vector in self.vectors)
        return f"[{matrix_str}]"
        
class Network_layer:
    # [weight] [input] + [bias]
    def __init__(self, input, weight: Vector|Matrix, bias: Vector|Matrix, relu: bool) -> None:
        self.layer = weight * input.output + bias if isinstance(input, Network_layer) else weight * input + bias
        self.output = self.layer.relu() if relu else self.layer 
        self.use_relu = relu
        self.input = input
        self.weight = weight
        self.bias = bias
    
    def __str__(self):
        return f"Relu({str(self.weight)} \n* \n{str(self.input)} \n+ \n{str(self.bias)}) \n= \n{str(self.output)}" if self.use_relu else f"({str(self.weight)} \n* \n{str(self.input)} \n+ \n{str(self.bias)}) \n= \n{str(self.output)}"  

    def compute_loss(self, target, loss):
        return loss(self.output, target)
    
    def backward(self, target, input_layer):
        grad_wrt_weight = input_layer.weight 
        grad_wrt_act = 1 if input_layer.use_relu else 0
        grad_wrt_loss = 2 * (self.output - target)      # Hard code MSE
         
# class Activation:
#     def __init__(self, value: Network_layer) -> None:
#         # self.activation = lambda x : max(0, x) if relu else x
#         self.output = value.relu() if isinstance(value, Vector, Matrix) else max(0, value)

class Network:
    def __init__(self, data: dict) -> None:
    # def __init__(self, num_of_layers: int, data: str, layers: [Network_layer], do_activations: [bool]) -> None:
        # self.layers = layers
        # self.do_activations = do_activations
        self.data = data
        self.num_of_layers = data['Layers']
        self.output_layers = []
        
    def build(self):
        for i in range(int(self.num_of_layers)):
            if (i == 0):
                input_layer = Network_layer(Matrix(self.data['Example_Input']), Matrix(self.data[f'Weights{i+1}']), Matrix(self.data[f'Biases{i+1}']), self.data[f'Relu{i+1}'].lower() == 'true')
            else:
                input_layer = Network_layer(self.output_layers[i-1].output, Matrix(self.data[f'Weights{i+1}']), Matrix(self.data[f'Biases{i+1}']), self.data[f'Relu{i+1}'].lower() == 'true')
            self.output_layers.append(input_layer)
            
    def __str__(self):
        # output = ""
        # for output_layer in self.output_layers:
        #     print(str(output_layer))
        #     print("----------------")
            
        network_layer_str = '\nlayer:\n'.join(str(output_layer) for output_layer in self.output_layers)
        return network_layer_str
    
    def output(self):
        return (self.output_layers[-1].output)
    
    
def grad(layer: Network_layer):
    grad = layer.weight