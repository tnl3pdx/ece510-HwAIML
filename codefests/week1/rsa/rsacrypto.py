import rsa
import os

def generate_keys():
    (pubkey, privkey) = rsa.newkeys(2048)
    return pubkey, privkey

def encrypt_file(filename, pubkey):
    try:
        filename = os.path.abspath(filename)
        print(f"Encrypting file: {filename}")  # Debug print
        with open(filename, 'rb') as infile:
            data = infile.read()
        encrypted_data = rsa.encrypt(data, pubkey)
        with open(filename + '.enc', 'wb') as outfile:
            outfile.write(encrypted_data)
        print("File encrypted successfully.")
    except FileNotFoundError:
        print("File not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def decrypt_file(filename, privkey):
    try:
        filename = os.path.abspath(filename)
        print(f"Decrypting file: {filename}")  # Debug print
        with open(filename, 'rb') as infile:
            encrypted_data = infile.read()
        decrypted_data = rsa.decrypt(encrypted_data, privkey)
        base_filename = filename[:-4] if filename.endswith('.enc') else filename
        with open(base_filename, 'wb') as outfile:
            outfile.write(decrypted_data)
        print("File decrypted successfully.")
    except FileNotFoundError:
        print("File not found.")
    except rsa. DecryptionError:
        print("Decryption failed.  Incorrect key or file.")
    except Exception as e:
        print(f"An error occurred: {e}")

def save_key(key, filename):
    try:
        with open(filename, 'wb') as outfile:
            outfile.write(key.save_pkcs1('PEM'))
        print(f"Key saved to {filename}")
    except Exception as e:
        print(f"An error occurred: {e}")

def load_key(filename, key_type):
    try:
        filename = os.path.abspath(filename)
        print(f"Loading key from: {filename}")  # Debug print
        with open(filename, 'rb') as infile:
            keydata = infile.read()
        if key_type == "private":
            key = rsa.PrivateKey.load_pkcs1(keydata)
        elif key_type == "public":
            key = rsa.PublicKey.load_pkcs1(keydata)
        return key
    except FileNotFoundError:
        print("File not found.")
        return None
    except Exception as e:
        print(f"An error occurred: {e}")
        return None

def main():
    while True:
        print("\nRSA Tool Menu:")
        print("1. Generate Public and Private Keys")
        print("2. Encrypt File")
        print("3. Decrypt File")
        print("4. Exit")

        choice = input("Enter your choice (1-4): ")

        if choice == '1':
            pubkey, privkey = generate_keys()
            save_key(pubkey, 'public.pem')
            save_key(privkey, 'private.pem')
        elif choice == '2':
            filename = input("Enter the filename to encrypt: ")
            filename = os.path.abspath(filename)  # Convert to absolute path
            pubkey_file = input("Enter the public key filename: ")
            pubkey_file = os.path.abspath(pubkey_file)  # Convert to absolute path
            pubkey = load_key(pubkey_file, "public")
            if pubkey:
                encrypt_file(filename, pubkey)
        elif choice == '3':
            filename = input("Enter the filename to decrypt: ")
            filename = os.path.abspath(filename)  # Convert to absolute path
            privkey_file = input("Enter the private key filename: ")
            privkey_file = os.path.abspath(privkey_file)  # Convert to absolute path
            privkey = load_key(privkey_file, "private")
            if privkey:
                decrypt_file(filename, privkey)
        elif choice == '4':
            print("Exiting...")
            break
        else:
            print("Invalid choice. Please enter a number between 1 and 4.")

if __name__ == "__main__":
    main()
