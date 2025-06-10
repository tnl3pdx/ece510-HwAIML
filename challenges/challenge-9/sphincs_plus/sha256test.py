from spincspython.profiler import Profiler
import sys
import hashlib

prof_tool = Profiler(output_dir="shaTest")

@prof_tool.profile_decorator()
def sha256_hash(input_string):
    """
    Computes the SHA-256 hash of the input string.
    
    Args:
        input_string (str): The string to hash
    
    Returns:
        str: The hexadecimal representation of the hash
    """
    print(f"Input string length: {len(input_string)}")
    return hashlib.sha256(input_string.encode('utf-8')).hexdigest()


def main():
    """
    Main function to demonstrate SHA-256 hashing.
    
    This function reads an input string from the user, computes its SHA-256 hash,
    and prints the result.
    """
    #input_string = "rem ipsum dolor sit amet, consectetur adipiscing elit. Nunc feugiat purus at odio pretium, et condimentum enim interdum. Ut faucibus placerat arcu, ac mollis enim tincidunt a. Mauris sed gravida massa, vel aliquam enim. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Lorem ipsum dolor sit amet, consectetur adipiscing elit. In hac habitasse platea dictumst. Duis at faucibus nisi. Integer leo ipsum, lobortis ac leo vel, fringilla vestibulum turpis. Donec aliquam cursus odio ac viverra. Quisque sollicitudin, est non aliquet laoreet, felis ligula viverra arcu, sed ultricies mi urna at mi.  Vivamus vel commodo turpis. Sed hendrerit commodo est et tempor. Donec fermentum enim at malesuada dictum. Nulla blandit ullamcorper pellentesque. Pellentesque id finibus mauris. Morbi congue est vel purus congue maximus. Donec ac ipsum pharetra, commodo ante a, luctus ipsum. Ut aliquam libero erat, at porta metus viverra id. In ac diam et odio placerat vestibulum. Pdddddddddddddd"
    #input_string = "test string for SHA-256 hashing"
    input_string = "_Lb+K/-}H5ZGqw5vnaViQ:1te5tX_%wagDn{=vD8=MZZcE!;(Ux(?KV049frB9cd"
    
    print(f"Input string: {input_string}")
    
    # Compute the SHA-256 hash
    hash_result = sha256_hash(input_string)
    
    print(f"SHA-256 Hash: {hash_result}")
    return 0


if __name__ == "__main__":
    sys.exit(main())