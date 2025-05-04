from spincspython.sphincs import Sphincs
from spincspython.profiler import Profiler
from typing import Tuple
import sys
import argparse
import time

def save_keypair(private_key: bytes, public_key: bytes, 
                sk_filename: str = "sphincs_private.key", 
                pk_filename: str = "sphincs_public.key") -> None:
    """Save a key pair to files."""
    with open(sk_filename, 'wb') as f:
        f.write(private_key)
        
    with open(pk_filename, 'wb') as f:
        f.write(public_key)
        
    print(f"Private key saved to: {sk_filename}")
    print(f"Public key saved to: {pk_filename}")
    
def load_keypair(sk_filename: str = "sphincs_private.key", 
            pk_filename: str = "sphincs_public.key") -> Tuple[bytes, bytes]:
    """Load a key pair from files."""
    with open(sk_filename, 'rb') as f:
        private_key = f.read()
        
    with open(pk_filename, 'rb') as f:
        public_key = f.read()
        
    print(f"Private key loaded from: {sk_filename}")
    print(f"Public key loaded from: {pk_filename}")
    return private_key, public_key
    
def main():
    """Main function to handle command line arguments."""
    parser = argparse.ArgumentParser(
        description='SPHINCS+ Signature Scheme Implementation',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    
    parser.add_argument('--keygen', action='store_true', 
                       help='Generate a new SPHINCS+ key pair')
    parser.add_argument('--sign', action='store_true', 
                       help='Sign a file')
    parser.add_argument('--verify', action='store_true', 
                       help='Verify a signature')
    parser.add_argument('--input', type=str, 
                       help='Input file to sign or verify')
    parser.add_argument('--signature', type=str, default='signature.bin',
                       help='File to store/read signature')
    parser.add_argument('--sk', type=str, default='sphincs_private.key',
                       help='Private key file')
    parser.add_argument('--pk', type=str, default='sphincs_public.key',
                       help='Public key file')
    parser.add_argument('-p', '--profile', action='store_true',
                       help='Enable profiler for performance analysis')

    
    # SPHINCS+ parameters
    parser.add_argument('--n', type=int, default=16, 
                       help='Security parameter (bytes)')
    parser.add_argument('--w', type=int, default=16,
                       help='Winternitz parameter')    
    parser.add_argument('--h', type=int, default=64,
                       help='Total tree height') 
    parser.add_argument('--d', type=int, default=8,
                       help='Hypertree layers')
    parser.add_argument('--k', type=int, default=10,
                       help='FORS trees')
    parser.add_argument('--a', type=int, default=15,
                       help='FORS height')
    
    args = parser.parse_args()
    
    # Create SPHINCS+ instance
    sphincs = Sphincs(args.profile)
    
    print(f"Profiler: " + ("Enabled" if args.profile == True else "Disabled"))
    
    sphincs.set_n(args.n)
    sphincs.set_w(args.w)
    sphincs.set_h(args.h)
    sphincs.set_d(args.d)
    sphincs.set_k(args.k)
    sphincs.set_a(args.a)
    
    # Log current time
    current_time = time.time()
    
    if args.keygen:
        private_key, public_key = sphincs.generate_key_pair()
        save_keypair(private_key, public_key, args.sk, args.pk)
        
    elif args.sign:
        if not args.input:
            parser.error("--sign requires --input")
            
        print(f"Reading file: {args.input}")
        with open(args.input, 'rb') as f:
            message = f.read()
            
        # Load private key
        try:
            private_key, _ = load_keypair(args.sk, args.pk)
        except FileNotFoundError:
            print(f"Error: Key files not found. Generate keys first with --keygen")
            return 1
            
        # Sign message
        signature = sphincs.sign(message, private_key)
        
        # Save signature
        with open(args.signature, 'wb') as f:
            f.write(signature)
            
        print(f"Signature saved to: {args.signature}")
        
    elif args.verify:
        if not args.input:
            parser.error("--verify requires --input")
            
        print(f"Reading file: {args.input}")
        with open(args.input, 'rb') as f:
            message = f.read()
            
        # Load signature
        try:
            with open(args.signature, 'rb') as f:
                signature = f.read()
        except FileNotFoundError:
            print(f"Error: Signature file not found: {args.signature}")
            return 1
            
        # Load public key
        try:
            _, public_key = load_keypair(args.sk, args.pk)
        except FileNotFoundError:
            print(f"Error: Key files not found. Generate keys first with --keygen")
            return 1
            
        # Verify signature
        if sphincs.verify(message, signature, public_key):
            print("Signature is VALID")
        else:
            print("Signature is INVALID")
            return 1
    else:
        parser.print_help()
    
    # Log elapsed time
    elapsed_time = time.time() - current_time
    print(f"Elapsed time of program execution: {elapsed_time:.4f} seconds")
        
        
    return 0

if __name__ == "__main__":
    sys.exit(main())