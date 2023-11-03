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

# for i, network in enumerate(networks):
#     print(f"Network #{i+1}")
#     data = parse_network(network)
#     my_network = Network(data)
#     my_network.build()
#     print(my_network)
#     # print(my_network.output())
#     print("***************************************")
threshold = 1e-2  # Define a small threshold value for comparison
lr = 0.01
max_itr = 100
initial_guess = []
loss = []

for i, network in enumerate(networks):
    print(f"Network #{i+1}")
    data = parse_network(network)
    my_network = Network(data)
    my_network.build()
    # print(my_network)
    # print(my_network.output())
    for j in range(max_itr):
        print("Iteration #:", j+1)
        my_network.backPropagation(lr)
        my_network.forwardPropagation()
        # print(my_network)
        print("output =", my_network.output.ab_sum())
        print("-----------------------------")
        if my_network.output.ab_sum() < threshold:
            initial_guess.append(my_network.Input_guess())
            loss.append(my_network.loss())
            break

    print("***************************************")
    
# data = parse_network(networks[0])
# my_network = Network(data)
# my_network.build()
# for i in range(10):
#     print("run #:", i+1)
#     my_network.backPropagation(lr)
#     my_network.forwardPropagation()
#     # print(my_network)
#     print("output =", my_network.output.sum())
#     print("***************************************")
#     if my_network.output.sum() < threshold:
#         break
    
    
    