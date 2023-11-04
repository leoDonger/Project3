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

    def __len__(self):
        return self.length

    def __iter__(self):
        return iter(self.values)
    
    def __mul__(self, other):
        if isinstance(other, Vector):
            if self.length != other.length:
                raise ValueError("Vectors must have the same dimensions for dot product")
            return sum(a * b for a, b in zip(self.values, other.values))
        elif isinstance(other, (int, float)):
            return Vector([a * other for a in self.values])
        elif isinstance(other, Matrix):
            raise ValueError("Vector-matrix multiplication isn't defined in this order. Use matrix-vector multiplication instead.")
        else:
            raise ValueError("Multiplication with type {} not supported.".format(type(other)))
        
    def __add__(self, other):
        if isinstance(other, Vector):
            if self.length != other.length:
                raise ValueError("Vectors must have the same dimensions for dot product")
            return Vector([float(a) + float(b) for a, b in zip(self.values, other.values)])
        elif isinstance(other, Matrix):
            raise ValueError("Vector-matrix multiplication isn't defined in this order. Use matrix-vector multiplication instead.")
        else:
            raise ValueError("Multiplication with type {} not supported.".format(type(other)))
    
    def __sub__(self, other):
        if isinstance(other, Vector):
            if self.length != other.length:
                raise ValueError("Vectors must have the same dimensions for subtraction")
            return Vector([float(a) - float(b) for a, b in zip(self.values, other.values)])
        elif isinstance(other, Matrix):
            raise ValueError("Vector-matrix subtraction isn't defined.")
        else:
            raise ValueError("Subtraction with type {} not supported.".format(type(other)))
    
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
    
    
    def ab_sum(self):
        total = 0.0
        for value in self.values:
            total += abs(float(value))
        return total
    
    def __str__(self):
        vector_str = ','.join(str(value) for value in self.values)
        return f"[{vector_str}]"
        
class Matrix:
    def __init__(self, vectors: list[Vector]|list[list]) -> None:
        self.vectors = vectors if isinstance(vectors[0], Vector) else list(Vector(v) for v in vectors)
        self.length = len(vectors)
        self.shape = (self.length, len(vectors[0]))
    
    def __iter__(self):
        return iter(self.vectors)
    
    def __len__(self):
        return self.length
        
    def __add__(self, other):
        if isinstance(other, (int, float)):
            result = [[value + other for value in vector.values] for vector in self.vectors]
            return Matrix(result)
        if isinstance(other, Matrix):
            if len(self.vectors) != len(other.vectors) or len(self.vectors[0].values) != len(other.vectors[0].values):
                raise ValueError("Matrices must have the same dimensions for addition.")
            result = []
            for v1, v2 in zip(self.vectors, other.vectors):
                result.append(v1 + v2)
            return Matrix(result)
        else:
            raise ValueError("Addition with type {} not supported.".format(type(other)))
        
    def __sub__(self, other):
        if isinstance(other, Matrix):
            if len(self.vectors) != len(other.vectors) or len(self.vectors[0].values) != len(other.vectors[0].values):
                raise ValueError("Matrices must have the same dimensions for addition.")
            result = []
            for v1, v2 in zip(self.vectors, other.vectors):
                result.append(v1 - v2)
            return Matrix(result)
        else:
            raise ValueError("Addition with type {} not supported.".format(type(other)))
        
    def __mul__(self, other):
        if isinstance(other, (int, float)):
            result = [[value * other for value in vector.values] for vector in self.vectors]
            return Matrix(result)
        if isinstance(other, Vector):
            if len(self.vectors[0].values) != len(other.values):
                raise ValueError("Number of matrix columns must match vector dimension for multiplication.")
            result = [Vector(row.values) * other for row in self.vectors]
            return Vector(result)
        elif isinstance(other, Matrix):
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
        
    def transpose(self): 
        transposed_data = list(zip(*[vector.values for vector in self.vectors]))
        return Matrix([Vector(list(row)) for row in transposed_data])

    def squared(self):
        squared_vectors = [Vector([value ** 2 for value in vector.values]) for vector in self.vectors]
        return Matrix(squared_vectors)
    
    def sqrt(self):
        sqrt_vectors = [Vector([math.sqrt(value) for value in vector.values]) for vector in self.vectors]
        return Matrix(sqrt_vectors)
    
    def inv(self):
        inv_vectors = [Vector([1 / value for value in vector.values]) for vector in self.vectors]
        return Matrix(inv_vectors)
    
    def divide(self, other):
        inv_vectors = [Vector([v1 / v2 for v1, v2 in zip(vs1.values, vs2.values)]) for vs1, vs2 in zip(self.vectors, other.vectors)]
        return Matrix(inv_vectors)
    
    def relu(self):
        return Matrix([v.relu() for v in self.vectors])
    
    def ab_sum(self):
        total =  0.0
        for vector in self.vectors:
            total += vector.ab_sum()
        return total
    
    def __str__(self):
        matrix_str = ','.join(str(vector) for vector in self.vectors)
        return f"[{matrix_str}]"
        
class Network_layer:
    # [weight] [input] + [bias]
    def __init__(self, input, weight: Vector|Matrix, bias: Vector|Matrix, relu: bool) -> None:
        self.layer = weight * input.output + bias if isinstance(input, Network_layer) else weight * input + bias
        self.output = self.layer.relu() if relu else self.layer     # forward
        self.use_relu = relu
        self.input = input
        self.weight = weight
        self.bias = bias
        self.grad = None
        self.scale = None
    
    def __str__(self):
        return f"Relu({str(self.weight)} \n* \n{str(self.input)} \n+ \n{str(self.bias)}) \n= \n{str(self.output)}" if self.use_relu else f"({str(self.weight)} \n* \n{str(self.input)} \n+ \n{str(self.bias)}) \n= \n{str(self.output)}"  

    def compute_loss(self, target, loss):
        return loss(self.output, target)

    def forward(self, input):
        self.layer = self.weight * input.output + self.bias if isinstance(input, Network_layer) else self.weight * input + self.bias
        self.output = self.layer.relu() if self.use_relu else self.layer
        
    def backward(self, target, input_layer, lr, momentum_para, scale_para):
        grad_wrt_input = self.weight
        grad_wrt_loss = (self.output - target)  *2 
        if (self.use_relu):
            new_grad_wrt_loss = []
            for loss, output in zip(grad_wrt_loss.vectors, self.output.vectors):
                loss = loss * 0 if float(output.values[0]) <= 0 else loss
                new_grad_wrt_loss.append(loss)
            grad_wrt_loss = Matrix(new_grad_wrt_loss)
        cur_grad = grad_wrt_input.transpose() * grad_wrt_loss
        if self.grad == None:
            self.grad = cur_grad
        else:
            self.grad = self.grad * momentum_para + cur_grad * (1 - momentum_para)
            
        if self.scale == None:
            self.scale = self.grad.squared()
        else:
            self.scale = self.scale * scale_para + self.grad.squared()  * (1 - scale_para)
            
        input = input_layer.output - (self.grad * lr).divide((self.scale + 0.00001).sqrt()) if isinstance(input_layer, Network_layer) else input_layer - (self.grad  * lr).divide((self.scale + 0.00001).sqrt())
        return input

class Network:
    def __init__(self, data: dict) -> None:
        self.data = data
        self.num_of_layers = data['Layers']
        self.layers = []
        self.output = None
        
    def build(self):
        for i in range(int(self.num_of_layers)):
            if (i == 0):
                input_layer = Network_layer(Matrix(self.data['Example_Input']), Matrix(self.data[f'Weights{i+1}']), Matrix(self.data[f'Biases{i+1}']), self.data[f'Relu{i+1}'].lower() == 'true')
            else:
                input_layer = Network_layer(self.layers[i-1].output, Matrix(self.data[f'Weights{i+1}']), Matrix(self.data[f'Biases{i+1}']), self.data[f'Relu{i+1}'].lower() == 'true')
            self.layers.append(input_layer)
        self.output = self.layers[-1].output
        
    def forwardPropagation(self):
        if self.layers == []:
            self.build()
        else:
            for i in range(int(self.num_of_layers)):
                if (i == 0):
                    self.layers[i].forward(self.layers[i].input)
                else:
                    self.layers[i].forward(self.layers[i-1].output)
            self.output = self.layers[-1].output
            
    def __str__(self):
        network_layer_str = '\nlayer:\n'.join(str(output_layer) for output_layer in self.layers)
        return network_layer_str
    
    def backPropagation(self, lr, momentum_para, scale_para):
        target = Matrix(list([0] for i in range(len(self.output))))
        for i in range(int(self.num_of_layers)-1, -1, -1):
            if i != 0:
                new_target = self.layers[i].backward(target, self.layers[i-1], lr, momentum_para, scale_para)
                target = new_target
            else:
                new_target = self.layers[i].backward(target, self.layers[i].input, lr, momentum_para, scale_para)
                self.layers[i].input = new_target
                target = new_target
    
    def Input_guess(self):
        return self.layers[0].input
    
    def loss(self):
        target = Matrix(list([0] for i in range(len(self.output))))
        diff = [(o - t) * (o - t) for o, t in zip(self.output, target)]
        loss = sum(diff) / len(diff)
        return loss