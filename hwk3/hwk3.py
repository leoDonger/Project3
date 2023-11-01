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

for i, network in enumerate(networks):
    print(f"Network #{i+1}")
    data = parse_network(network)
    my_network = Network(data)
    my_network.build()
    print(my_network)
    # print(my_network.output())
    print("***************************************")
    
initial_guess = []
    