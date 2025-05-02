import hashlib
import os
import sys
import argparse
from typing import List, Tuple, Optional 
import time

class SPHINCSPlus:
    """
    A full implementation of the SPHINCS+ signature scheme.
    
    SPHINCS+ is a stateless hash-based signature scheme with post-quantum security.
    It combines WOTS+ (Winternitz One-Time Signature) scheme with a hypertree structure
    and FORS (Forest of Random Subsets) few-time signatures.
    """
    
    def __init__(self, 
                 n: int = 16,         # Security parameter (bytes)
                 h: int = 64,         # Total tree height
                 d: int = 8,          # Hypertree layers
                 k: int = 10,         # FORS trees
                 w: int = 16,         # Winternitz parameter
                 t: int = 2**6,       # FORS tree size
                 robust: bool = True, # Robust variant
                 hash_function: str = "shake_256"):
        """
        Initialize SPHINCS+ with configurable parameters.
        
        Args:
            n: Security parameter (in bytes)
            h: Total tree height
            d: Number of hypertree layers
            k: Number of FORS trees
            w: Winternitz parameter
            t: FORS tree size
            robust: Whether to use the robust variant
            hash_function: Hash function to use ("shake_256" or "sha256")
        """
        # Core parameters
        self.n = n                      # Security parameter in bytes
        self.h = h                      # Total tree height
        self.d = d                      # Number of hypertree layers
        self.k = k                      # FORS parameter (number of trees)
        self.w = w                      # Winternitz parameter
        self.t = t                      # FORS tree size (leaves per tree)
        self.robust = robust            # Use robust variant
        self.hash_function = hash_function
        
        # Derived parameters
        self.wots_logw = self._log2(self.w)
        self.wots_len1 = int((8 * self.n) / self.wots_logw)
        self.wots_len2 = int(self._log2(self.wots_len1 * (self.w - 1)) / self.wots_logw) + 1
        self.wots_len = self.wots_len1 + self.wots_len2
        
        # Tree parameters
        self.tree_height = int(self.h / self.d)
        self.fors_height = self._log2(self.t)
        self.fors_trees = self.k
        
        # Derived message format
        self.message_digest_len = int(self.k * self.fors_height / 8)
        
        # Context for domain separation
        self.context = b"SPHINCS+"
        
        print(f"Initialized SPHINCS+ with parameters:")
        print(f"  n = {self.n} bytes (security parameter)")
        print(f"  h = {self.h} (tree height)")
        print(f"  d = {self.d} (hypertree layers)")
        print(f"  k = {self.k} (FORS trees)")
        print(f"  w = {self.w} (Winternitz parameter)")
        print(f"  t = {self.t} (FORS tree size)")
        print(f"  robust = {self.robust}")

    def _log2(self, value: int) -> int:
        """Calculate integer log2 with ceiling."""
        # bit_length gives the position of the highest set bit, effectively calculating ceil(log2(value))
        return (value - 1).bit_length()
        
    def _hash(self, data: bytes, n: Optional[int] = None) -> bytes:
        """Hash function wrapper."""
        if n is None:
            n = self.n
            
        if self.hash_function == "shake_256":
            return hashlib.shake_256(data).digest(n)
        elif self.hash_function == "sha256":
            h = hashlib.sha256(data).digest()
            # Truncate or pad as necessary
            if len(h) == n:
                return h
            elif len(h) > n:
                return h[:n]
            else:
                return h + bytes(n - len(h))
        else:
            raise ValueError(f"Unsupported hash function: {self.hash_function}")
    
    def _prf(self, key: bytes, addr: bytes, msg: Optional[bytes] = None) -> bytes:
        """Pseudorandom function."""
        if msg is None:
            data = key + addr
        else:
            data = key + addr + msg
        return self._hash(data)
    
    def _h_msg(self, r: bytes, pk_seed: bytes, pk_root: bytes, msg: bytes) -> bytes:
        """Hash function for message compression."""
        data = r + pk_seed + pk_root + msg
        return self._hash(data, self.message_digest_len)
    
    def _thash(self, left: bytes, right: bytes, pk_seed: bytes, addr: bytes) -> bytes:
        """Tweakable hash function for tree nodes."""
        data = pk_seed + addr + left + right
        if self.robust:
            # XOR with a mask derived from pk_seed and addr
            mask = self._prf(pk_seed, addr + b'\x00')
            left_masked = bytes(a ^ b for a, b in zip(left, mask))
            
            mask = self._prf(pk_seed, addr + b'\x01')
            right_masked = bytes(a ^ b for a, b in zip(right, mask))
            
            data = pk_seed + addr + left_masked + right_masked
            
        return self._hash(data)
    
    def _f(self, in_data: bytes, pk_seed: bytes, addr: bytes) -> bytes:
        """Tweakable hash function for chain values."""
        data = pk_seed + addr + in_data
        if self.robust:
            mask = self._prf(pk_seed, addr + b'\x00')
            masked = bytes(a ^ b for a, b in zip(in_data, mask))
            data = pk_seed + addr + masked
            
        return self._hash(data)
    
    def _chain(self, x: bytes, i: int, steps: int, pk_seed: bytes, addr: bytes) -> bytes:
        """Apply chain function steps times starting from x."""
        if steps == 0:
            return x
            
        if i + steps > self.w:
            raise ValueError("Chain index out of bounds")
            
        out = x
        for j in range(i, i + steps):
            addr_j = addr + j.to_bytes(1, 'big')  # Add chain position to address
            out = self._f(out, pk_seed, addr_j)
        return out
        
    # WOTS+ Functions
    def _wots_sk_gen(self, sk_seed: bytes, addr: bytes) -> List[bytes]:
        """Generate WOTS+ private key (list of n-byte values)."""
        sk = []
        for i in range(self.wots_len):
            # Add chain index to address
            chain_addr = addr + i.to_bytes(2, 'big')
            sk.append(self._prf(sk_seed, chain_addr))
        return sk
    
    def _wots_pk_gen(self, sk_seed: bytes, pk_seed: bytes, addr: bytes) -> bytes:
        """Generate WOTS+ public key."""
        sk_list = self._wots_sk_gen(sk_seed, addr)
        pk_list = []
        
        for i in range(self.wots_len):
            chain_addr = addr + i.to_bytes(2, 'big')
            pk_list.append(self._chain(sk_list[i], 0, self.w - 1, pk_seed, chain_addr))
            
        return b''.join(pk_list)
    
    def _wots_sign(self, msg: bytes, sk_seed: bytes, pk_seed: bytes, addr: bytes) -> bytes:
        """Generate WOTS+ signature for message."""
        # Convert message to base w
        msg_base_w = self._base_w(msg)
        
        # Compute checksum
        csum = 0
        for v in msg_base_w:
            csum += self.w - 1 - v
            
        # Convert checksum to base w
        csum_base_w = []
        for i in range(self.wots_len2):
            csum_base_w.append((csum >> (self.wots_logw * i)) & (self.w - 1))
            
        # Concatenate message and checksum in base w representation
        lengths = msg_base_w + csum_base_w
        
        # Generate private key
        sk_list = self._wots_sk_gen(sk_seed, addr)
        
        # Generate signature by chaining private key elements
        sig_list = []
        for i in range(self.wots_len):
            chain_addr = addr + i.to_bytes(2, 'big')
            sig_list.append(self._chain(sk_list[i], 0, lengths[i], pk_seed, chain_addr))
            
        return b''.join(sig_list)
        
    def _wots_pk_from_sig(self, sig: bytes, msg: bytes, pk_seed: bytes, addr: bytes) -> bytes:
        """Derive WOTS+ public key from signature."""
        # Convert message to base w
        msg_base_w = self._base_w(msg)
        
        # Compute checksum
        csum = 0
        for v in msg_base_w:
            csum += self.w - 1 - v
            
        # Convert checksum to base w
        csum_base_w = []
        for i in range(self.wots_len2):
            csum_base_w.append((csum >> (self.wots_logw * i)) & (self.w - 1))
            
        # Concatenate message and checksum in base w representation
        lengths = msg_base_w + csum_base_w
        
        # Extract signature components
        sig_components = []
        for i in range(self.wots_len):
            sig_components.append(sig[i*self.n:(i+1)*self.n])
            
        # Derive public key components from signature
        pk_list = []
        for i in range(self.wots_len):
            chain_addr = addr + i.to_bytes(2, 'big')
            pk_list.append(self._chain(
                sig_components[i], 
                lengths[i], 
                self.w - 1 - lengths[i], 
                pk_seed, 
                chain_addr
            ))
            
        return b''.join(pk_list)
        
    def _base_w(self, msg: bytes) -> List[int]:
        """Convert byte string to base w representation."""
        result = []
        bits_per_digit = self.wots_logw
        total_digits = self.wots_len1
        bit_mask = (1 << bits_per_digit) - 1  # Mask for extracting bits_per_digit bits

        # Flatten the message into a single integer for easier bit manipulation
        msg_int = int.from_bytes(msg, byteorder='big')

        for i in range(total_digits):
            # Extract the next `bits_per_digit` bits
            shift_amount = (total_digits - 1 - i) * bits_per_digit
            digit = (msg_int >> shift_amount) & bit_mask
            result.append(digit)

        return result
    
    # FORS Functions
    def _fors_sk_gen(self, sk_seed: bytes, addr: bytes) -> bytes:
        """Generate a FORS private key value."""
        return self._prf(sk_seed, addr)
    
    def _fors_pk_gen(self, sk_seed: bytes, pk_seed: bytes, addr: bytes) -> bytes:
        """Generate FORS public key."""
        # For each FORS tree
        roots = []
        
        for tree_idx in range(self.k):
            # Set tree index in address
            tree_addr = addr + b'tree' + tree_idx.to_bytes(1, 'big')
            
            # Initialize leaf nodes
            leaves = []
            for leaf_idx in range(self.t):
                # Generate leaf private key
                leaf_addr = tree_addr + b'leaf' + leaf_idx.to_bytes(2, 'big')
                sk = self._fors_sk_gen(sk_seed, leaf_addr)
                
                # Hash to get leaf node value
                leaf = self._f(sk, pk_seed, leaf_addr + b'hash')
                leaves.append(leaf)
            
            # Build tree
            root = self._compute_root(leaves, pk_seed, tree_addr + b'node')
            roots.append(root)
            
        # Compress roots to get FORS public key
        return self._hash(b''.join(roots))
    
    def _compute_root(self, nodes: List[bytes], pk_seed: bytes, addr: bytes) -> bytes:
        """Compute Merkle tree root from leaf nodes."""
        if len(nodes) == 1:
            return nodes[0]
            
        next_level = []
        for i in range(0, len(nodes), 2):
            # If odd number of nodes, duplicate the last one
            if i+1 >= len(nodes):
                next_level.append(nodes[i])
                continue
                
            # Hash pair of nodes
            node_addr = addr + i.to_bytes(2, 'big')
            parent = self._thash(nodes[i], nodes[i+1], pk_seed, node_addr)
            next_level.append(parent)
            
        return self._compute_root(next_level, pk_seed, addr + b'up')
        
    def _compute_auth_path(self, leaf_idx: int, nodes: List[bytes], pk_seed: bytes, addr: bytes) -> List[bytes]:
        """Compute authentication path for a leaf node."""
        if len(nodes) == 1:
            return []
            
        auth_path = []
        auth_idx = leaf_idx ^ 1  # Sibling index

        if auth_idx < len(nodes):
            auth_path.append(nodes[auth_idx])
        else:
            # If sibling doesn't exist, use the node itself (should not happen in balanced tree)
            print(f"Warning: Sibling index {auth_idx} out of bounds, using node itself.")
            auth_path.append(nodes[leaf_idx])
            
        # Compute indices for next level
        next_level = []
        for i in range(0, len(nodes), 2):
            if i+1 >= len(nodes):
                next_level.append(nodes[i])
                continue
                
            node_addr = addr + i.to_bytes(2, 'big')
            parent = self._thash(nodes[i], nodes[i+1], pk_seed, node_addr)
            next_level.append(parent)
            
        # Recurse to next level
        next_leaf_idx = leaf_idx // 2
        auth_path.extend(
            self._compute_auth_path(next_leaf_idx, next_level, pk_seed, addr + b'up')
        )
        
        return auth_path
        
    def _fors_sign(self, msg: bytes, sk_seed: bytes, pk_seed: bytes, addr: bytes) -> bytes:
        """Generate FORS signature for message."""
        # Split message into k parts for tree indices
        indices = []
        total_bits = len(msg) * 8
        bits_per_tree = self.fors_height

        if self.k * bits_per_tree > total_bits:
            raise ValueError("Message is too short to extract all tree indices")

        for i in range(self.k):
            # Extract log(t) bits for each tree
            start_bit = i * bits_per_tree
            end_bit = start_bit + bits_per_tree

            # Handle remaining bits if message is not evenly distributed
            if end_bit > total_bits:
                end_bit = total_bits

            # Convert bits to index
            idx = 0
            for j in range(start_bit, end_bit):
                byte_idx = j // 8
                bit_idx = j % 8
                bit = (msg[byte_idx] >> (7 - bit_idx)) & 1
                idx = (idx << 1) | bit

            idx = idx % self.t  # Ensure index is valid
            indices.append(idx)

        # Handle any remaining message bytes if k * bits_per_tree < total_bits
        remaining_bits = total_bits - self.k * bits_per_tree
        if remaining_bits > 0:
            print(f"Warning: {remaining_bits} bits of the message were not used.")
            
        # Generate signature parts
        signature = bytearray()
        
        for i in range(self.k):
            tree_addr = addr + b'tree' + i.to_bytes(1, 'big')
            leaf_idx = indices[i]
            
            # Add secret key to signature
            leaf_addr = tree_addr + b'leaf' + leaf_idx.to_bytes(2, 'big')
            sk = self._fors_sk_gen(sk_seed, leaf_addr)
            signature.extend(sk)
            
            # Build tree for authentication path
            leaves = []
            for j in range(self.t):
                if j == leaf_idx:
                    # We already have this one
                    leaves.append(self._f(sk, pk_seed, leaf_addr + b'hash'))
                else:
                    # Generate other leaves
                    j_addr = tree_addr + b'leaf' + j.to_bytes(2, 'big')
                    j_sk = self._fors_sk_gen(sk_seed, j_addr)
                    leaves.append(self._f(j_sk, pk_seed, j_addr + b'hash'))
            
            # Generate authentication path
            auth_path = self._compute_auth_path(leaf_idx, leaves, pk_seed, tree_addr + b'node')
            
            # Add authentication path to signature
            for node in auth_path:
                signature.extend(node)
                
        return bytes(signature)
        
    def _fors_verify(self, msg: bytes, signature: bytes, pk_seed: bytes, addr: bytes) -> bytes:
        """Verify FORS signature and return computed root."""
        # Split message into k parts for tree indices
        indices = []
        for i in range(self.k):
            # Extract log(t) bits for each tree
            start_bit = i * self.fors_height
            end_bit = (i+1) * self.fors_height
            
            # Convert bits to index
            idx = 0
            for j in range(start_bit, end_bit):
                byte_idx = j // 8
                bit_idx = j % 8
                bit = (msg[byte_idx] >> (7 - bit_idx)) & 1
                idx = (idx << 1) | bit
                
            idx = idx % self.t  # Ensure index is valid
            indices.append(idx)
            
        # Extract roots from signature
        roots = []
        sig_idx = 0
        
        for i in range(self.k):
            tree_addr = addr + b'tree' + i.to_bytes(1, 'big')
            leaf_idx = indices[i]
            
            # Get leaf value from signature (secret key)
            sk = signature[sig_idx:sig_idx+self.n]
            sig_idx += self.n
            
            # Compute leaf node
            leaf_addr = tree_addr + b'leaf' + leaf_idx.to_bytes(2, 'big')
            node = self._f(sk, pk_seed, leaf_addr + b'hash')
            
            # Extract authentication path
            auth_path = []
            for j in range(self._log2(self.t)):
                auth_path.append(signature[sig_idx:sig_idx+self.n])
                sig_idx += self.n
                
            # Compute root using authentication path
            root = self._compute_root_from_auth(leaf_idx, node, auth_path, pk_seed, tree_addr + b'node')
            roots.append(root)
            
        # Compress roots to get FORS public key
        return self._hash(b''.join(roots))
        
    def _compute_root_from_auth(self, leaf_idx: int, leaf: bytes, auth_path: List[bytes],
                               pk_seed: bytes, addr: bytes) -> bytes:
        """Compute root from leaf and authentication path."""
        node_idx = leaf_idx
        node = leaf
        
        for i, auth_node in enumerate(auth_path):
            node_addr = addr + ((node_idx >> i) & ~1).to_bytes(2, 'big')
            
            if (node_idx >> i) & 1:
                # node is right child, auth_node is left
                node = self._thash(auth_node, node, pk_seed, node_addr)
            else:
                # node is left child, auth_node is right
                node = self._thash(node, auth_node, pk_seed, node_addr)
                
        return node

    # SPHINCS+ Main Functions
    def generate_keypair(self) -> Tuple[bytes, bytes]:
        """Generate a SPHINCS+ key pair."""
        start_time = time.time()
        print("Generating SPHINCS+ keypair...")
        
        # Generate random seeds
        sk_seed = os.urandom(self.n)
        sk_prf = os.urandom(self.n)
        pk_seed = os.urandom(self.n)
        
        # Set address for public key
        addr = b"SPHINCS+_root"
        
        # Generate top-level trees root
        root = self._fors_pk_gen(sk_seed, pk_seed, addr)
        
        # Public key is (pk_seed || root)
        public_key = pk_seed + root
        
        # Private key is (sk_seed || sk_prf || pk_seed || root)
        private_key = sk_seed + sk_prf + public_key
        
        print(f"Key generation completed in {time.time() - start_time:.2f} seconds")
        return private_key, public_key
        
    def sign(self, message: bytes, private_key: bytes) -> bytes:
        """Sign a message using a private key."""
        start_time = time.time()
        print(f"Signing message of {len(message)} bytes...")
        
        # Extract key components
        sk_seed = private_key[:self.n]
        sk_prf = private_key[self.n:2*self.n]
        pk_seed = private_key[2*self.n:3*self.n]
        root = private_key[3*self.n:4*self.n]
        
        # Generate randomized digest
        r = self._prf(sk_prf, b'randomized', message)
        message_digest = self._h_msg(r, pk_seed, root, message)
        
        # Start building signature with randomizer r
        signature = bytearray(r)
        
        # FORS signature
        fors_addr = b"SPHINCS+_fors"
        fors_sig = self._fors_sign(message_digest, sk_seed, pk_seed, fors_addr)
        signature.extend(fors_sig)
        
        # Verify and get public key
        fors_pk = self._fors_verify(message_digest, fors_sig, pk_seed, fors_addr)
        
        # WOTS+ signature on FORS public key
        wots_addr = b"SPHINCS+_wots"
        wots_sig = self._wots_sign(fors_pk, sk_seed, pk_seed, wots_addr)
        signature.extend(wots_sig)
        
        print(f"Signing completed in {time.time() - start_time:.2f} seconds")
        print(f"Signature size: {len(signature)} bytes")
        return bytes(signature)
        
    def verify(self, message: bytes, signature: bytes, public_key: bytes) -> bool:
        """Verify a signature on a message using a public key."""
        start_time = time.time()
        print(f"Verifying signature of {len(signature)} bytes...")
        
        # Extract key components
        pk_seed = public_key[:self.n]
        root = public_key[self.n:2*self.n]
        
        # Extract randomizer from signature
        r = signature[:self.n]
        sig_idx = self.n
        
        # Compute message digest
        message_digest = self._h_msg(r, pk_seed, root, message)
        
        # Extract FORS signature
        fors_sig_len = self.k * (1 + self._log2(self.t)) * self.n
        fors_sig = signature[sig_idx:sig_idx+fors_sig_len]
        sig_idx += fors_sig_len
        
        # Verify FORS signature
        fors_addr = b"SPHINCS+_fors"
        fors_pk = self._fors_verify(message_digest, fors_sig, pk_seed, fors_addr)
        
        # Extract WOTS+ signature
        wots_sig_len = self.wots_len * self.n
        wots_sig = signature[sig_idx:sig_idx+wots_sig_len]
        
        # Verify WOTS+ signature
        wots_addr = b"SPHINCS+_wots"
        wots_pk = self._wots_pk_from_sig(wots_sig, fors_pk, pk_seed, wots_addr)
        
        # Convert WOTS+ public key to node
        wots_root = self._hash(wots_pk)
        
        # Final verification - check if root matches
        valid = wots_root == root
        
        print(f"Verification completed in {time.time() - start_time:.2f} seconds")
        print(f"Signature is {'valid' if valid else 'invalid'}")
        return valid
        
    def save_keypair(self, private_key: bytes, public_key: bytes, 
                   sk_filename: str = "sphincs_private.key", 
                   pk_filename: str = "sphincs_public.key") -> None:
        """Save a key pair to files."""
        with open(sk_filename, 'wb') as f:
            f.write(private_key)
            
        with open(pk_filename, 'wb') as f:
            f.write(public_key)
            
        print(f"Private key saved to: {sk_filename}")
        print(f"Public key saved to: {pk_filename}")
        
    def load_keypair(self, sk_filename: str = "sphincs_private.key", 
                   pk_filename: str = "sphincs_public.key") -> Tuple[bytes, bytes]:
        """Load a key pair from files."""
        with open(sk_filename, 'rb') as f:
            private_key = f.read()
            
        with open(pk_filename, 'rb') as f:
            public_key = f.read()
            
        print(f"Private key loaded from: {sk_filename}")
        print(f"Public key loaded from: {pk_filename}")
        return private_key, public_key

    def test_fors_functions(self):
        """Test FORS sign and verify functions."""
        print("Testing FORS functions...")
        
        # Use deterministic seeds for testing
        sk_seed = b"A" * self.n
        pk_seed = b"B" * self.n
        addr = b"SPHINCS+_test_fors"
        
        # Create a test message
        message = bytes([i % 256 for i in range(self.message_digest_len)])
        
        # Generate the original FORS public key directly
        original_pk = self._fors_pk_gen(sk_seed, pk_seed, addr)
        
        # Sign the message
        fors_sig = self._fors_sign(message, sk_seed, pk_seed, addr)
        
        # Verify the signature
        verified_pk = self._fors_verify(message, fors_sig, pk_seed, addr)
        
        # Check if the verification produces the correct public key
        if original_pk == verified_pk:
            print("✓ FORS functions are working correctly!")
            print(f"  Signature size: {len(fors_sig)} bytes")
        else:
            print("✗ FORS verification failed - public keys don't match")
            print(f"  Original PK: {original_pk.hex()[:20]}...")
            print(f"  Verified PK: {verified_pk.hex()[:20]}...")
        
        return original_pk == verified_pk

    def test_wots_functions(self):
        """Test WOTS+ sign and verify functions."""
        print("Testing WOTS+ functions...")
        
        # Use deterministic seeds for testing
        sk_seed = b"W" * self.n
        pk_seed = b"O" * self.n
        addr = b"SPHINCS+_test_wots"
        
        # Create a test message (same size as n to ensure proper handling)
        message = bytes([i % 256 for i in range(self.n)])
        
        # Generate the original WOTS+ public key
        original_pk = self._wots_pk_gen(sk_seed, pk_seed, addr)
        
        # Sign the message
        wots_sig = self._wots_sign(message, sk_seed, pk_seed, addr)
        
        # Derive public key from the signature
        derived_pk = self._wots_pk_from_sig(wots_sig, message, pk_seed, addr)
        
        # Compare the original and derived public keys
        if original_pk == derived_pk:
            print("✓ WOTS+ functions are working correctly!")
            print(f"  Message: {message.hex()[:20]}...")
            print(f"  Signature size: {len(wots_sig)} bytes")
        else:
            print("✗ WOTS+ verification failed - public keys don't match")
            print(f"  Original PK: {original_pk.hex()[:20]}...")
            print(f"  Derived PK: {derived_pk.hex()[:20]}...")
        
        return original_pk == derived_pk
        
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
    parser.add_argument('--test', action='store_true',
                       help='Run test for FORS functions')

    
    # SPHINCS+ parameters
    parser.add_argument('--n', type=int, default=32, 
                       help='Security parameter (bytes)')
    parser.add_argument('--h', type=int, default=64,
                       help='Total tree height') 
    parser.add_argument('--d', type=int, default=8,
                       help='Hypertree layers')
    parser.add_argument('--k', type=int, default=14,
                       help='FORS trees')
    parser.add_argument('--w', type=int, default=16,
                       help='Winternitz parameter')
    parser.add_argument('--t', type=int, default=2**4,
                       help='FORS tree size')
    
    args = parser.parse_args()
    
    # Create SPHINCS+ instance
    sphincs = SPHINCSPlus(
        n=args.n,
        h=args.h,
        d=args.d,
        k=args.k,
        w=args.w,
        t=args.t
    )
    
    if args.keygen:
        private_key, public_key = sphincs.generate_keypair()
        sphincs.save_keypair(private_key, public_key, args.sk, args.pk)
        
    elif args.sign:
        if not args.input:
            parser.error("--sign requires --input")
            
        print(f"Reading file: {args.input}")
        with open(args.input, 'rb') as f:
            message = f.read()
            
        # Load private key
        try:
            private_key, _ = sphincs.load_keypair(args.sk, args.pk)
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
            _, public_key = sphincs.load_keypair(args.sk, args.pk)
        except FileNotFoundError:
            print(f"Error: Key files not found. Generate keys first with --keygen")
            return 1
            
        # Verify signature
        if sphincs.verify(message, signature, public_key):
            print("Signature is VALID")
            return 0
        else:
            print("Signature is INVALID")
            return 1
    elif args.test:
        print("Running test for FORS functions...")
        if sphincs.test_fors_functions():
            print("FORS Test passed!")
        else:
            print("FORS Test failed!")
        if sphincs.test_wots_functions():
            print("WOTS Test passed!")
        else:
            print("WOTS Test failed!")
    else:
        parser.print_help()
        
    return 0

if __name__ == "__main__":
    sys.exit(main())