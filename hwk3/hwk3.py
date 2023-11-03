from my_neural_network import *
import ast

path = "networks.txt"
with open(path, "r") as file:
    networks = file.read().split('\n\n')
    
def parse_list(str):
    try:
        result = ast.literal_eval(str)
        if isinstance(result, list) and all(isinstance(sublist, list) for sublist in result):
            return result
        else:
            raise ValueError("Input string is not a list of lists.")
    except (SyntaxError, ValueError):
        return str

def parse_network(text):
    dict = {}
    kvs = text.split('\n')
    for kv in kvs:
        if (len(kv) > 0):
            # print(kv)
            kv = kv.replace(" ", '').split(':')
            dict[kv[0]] = parse_list(kv[1])

    return dict


initial_lr=0.001 
initial_momentum=0.9
initial_scale=1.0

class Optimizer:
    def __init__(self, initial_lr, initial_momentum, initial_scale):
        self.lr = initial_lr
        self.momentum = initial_momentum
        self.scale = initial_scale
        self.initial_lr = initial_lr
        self.initial_momentum = initial_momentum
        self.initial_scale = initial_scale
        self.previous_loss = float('inf')
        self.lr_decay = 0.01 
        self.momentum_increase = 0.01
        self.scale_adjustment_factor = 0.1

    def update_parameters(self, current_loss):
        if current_loss < self.previous_loss:
            self.lr *= (1 - self.lr_decay)
            self.momentum -= self.momentum_increase
            self.momentum = min(self.momentum, 0)
        else:
            self.lr *= (1 + self.lr_decay)
            self.scale *= (1 + self.scale_adjustment_factor)

        self.previous_loss = current_loss


threshold = 1e-2
# lr = 0.05
# momentum_para = 0.99
# scale_para = 0.05
max_itr = 100
initial_guess = []
losses = []

for i, network in enumerate(networks):
    print(f"Network #{i+1}")
    data = parse_network(network)
    my_network = Network(data)
    my_network.build()
    previous_loss = my_network.output.ab_sum()
    previous_input = my_network.Input_guess()
    count = 0
    min_loss = float('inf')
    min_input = None
    optimizer = Optimizer(initial_lr=0.01, initial_momentum=0.1, initial_scale=.5)
    
    for j in range(max_itr):
        # print("Iteration #:", j+1)
        my_network.backPropagation(optimizer.lr, optimizer.momentum, optimizer.scale)
        my_network.forwardPropagation()
        current_loss = my_network.output.ab_sum()
        if (min_loss > current_loss):
            min_loss = current_loss
            min_input = my_network.Input_guess()
        # print(my_network)
        if current_loss < threshold:
            # print("loss =", current_loss)
            # print("output =", my_network.output)
            # print("-----------------------------")
            # initial_guess.append(my_network.Input_guess())
            # losses.append(my_network.loss())
            break
        optimizer.update_parameters(current_loss)

    initial_guess.append(min_input)
    losses.append(min_loss)
    print("***************************************")
    
with open("inputs.txt", 'w') as file:
    for guess in initial_guess:
        file.write(str(guess) + '\n')
    
with open("losses.txt", 'w') as file:
    for loss in losses:
        file.write(str(loss) + '\n')








# from my_neural_network import *
# import ast

# path = "networks.txt"
# with open(path, "r") as file:
#     networks = file.read().split('\n\n')
    
# def parse_list(str):
#     try:
#         result = ast.literal_eval(str)
#         if isinstance(result, list) and all(isinstance(sublist, list) for sublist in result):
#             return result
#         else:
#             raise ValueError("Input string is not a list of lists.")
#     except (SyntaxError, ValueError):
#         return str

# def parse_network(text):
#     dict = {}
#     kvs = text.split('\n')
#     for kv in kvs:
#         if (len(kv) > 0):
#             # print(kv)
#             kv = kv.replace(" ", '').split(':')
#             dict[kv[0]] = parse_list(kv[1])

#     return dict

# # for i, network in enumerate(networks):
# #     print(f"Network #{i+1}")
# #     data = parse_network(network)
# #     my_network = Network(data)
# #     my_network.build()
# #     print(my_network)
# #     # print(my_network.output())
# #     print("***************************************")
# threshold = 1e-2  # Define a small threshold value for comparison
# lr = 0.01
# max_itr = 500
# initial_guess = []
# loss = []

# for i, network in enumerate(networks):
#     print(f"Network #{i+1}")
#     data = parse_network(network)
#     my_network = Network(data)
#     my_network.build()
#     # print(my_network)
#     # print(my_network.output())
#     for j in range(max_itr):
#         # print("Iteration #:", j+1)
#         my_network.backPropagation(lr)
#         my_network.forwardPropagation()
#         # print(my_network)
#         # print("loss =", my_network.output.ab_sum())
#         # print("-----------------------------")
#         if my_network.output.ab_sum() < threshold:
#             print("loss =", my_network.output.ab_sum())
#             print("-----------------------------")
#             initial_guess.append(my_network.Input_guess())
#             loss.append(my_network.output.ab_sum())
#             break
#         elif j == max_itr-1:
#             print("loss =", my_network.output.ab_sum())
#             print("-----------------------------")

#     print("***************************************")
    

    
    