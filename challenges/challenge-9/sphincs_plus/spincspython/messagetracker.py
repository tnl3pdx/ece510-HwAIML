import os
import json
from datetime import datetime

class MessageLengthTracker:
    """Container to track message lengths for SHA-256 operations"""
    def __init__(self, output_dir="msg_length_stats"):
        self.lengths = []
        self.max_length = 0
        self.max_message = b''
        self.total_messages = 0
        self.output_dir = output_dir
        
        # Create output directory if it doesn't exist
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
            
        # Generate default filename with timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.default_filename = f"message_stats_{timestamp}"
    
    def record(self, message, print_long=False):
        """Record a new message length"""
        length = len(message)
        self.lengths.append(length)
        self.total_messages += 1
        
        if length > self.max_length:
            self.max_length = length
            self.max_message = message
            if print_long:
                print(f"New longest message: {length} bytes: {message.hex()}\n")
    
    def get_stats(self):
        """Return statistics about recorded message lengths"""
        if not self.lengths:
            return {"max": 0, "min": 0, "avg": 0, "total_msgs": 0}
            
        return {
            "max": self.max_length,
            "min": min(self.lengths),
            "avg": sum(self.lengths) / len(self.lengths),
            "total_msgs": self.total_messages,
            "unique_lengths": len(set(self.lengths)),
            "length_histogram": {str(length): self.lengths.count(length) 
                               for length in set(sorted(self.lengths))}
        }
    
    def print_summary(self, also_save=True, filename=None):
        """Print a summary of message length statistics and optionally save to file"""
        stats = self.get_stats()
        
        # Print to console
        print("\n===== Message Length Statistics =====")
        print(f"Total messages processed: {stats['total_msgs']}")
        print(f"Maximum length: {stats['max']} bytes")
        print(f"Minimum length: {stats['min']} bytes")
        print(f"Average length: {stats['avg']:.2f} bytes")
        print(f"Unique lengths: {stats['unique_lengths']}")
        if self.max_length > 0:
            print(f"Longest message: {self.max_message.hex()[:64]}...")
        print("=====================================\n")
        
        # Save to file if requested
        if also_save:
            self.save_stats(filename)
    
    def save_stats(self, filename=None):
        """Save statistics to a file"""
        if filename is None:
            filename = self.default_filename
            
        # Ensure the filename has a proper extension
        if not filename.endswith('.json'):
            filename += '.json'
            
        filepath = os.path.join(self.output_dir, filename)
        
        # Prepare data for saving
        stats = self.get_stats()
        save_data = {
            "statistics": stats,
            "longest_message_hex": self.max_message.hex() if self.max_length > 0 else ""
        }
        
        # Save to file
        with open(filepath, 'w') as f:
            json.dump(save_data, f, indent=2)
            
        print(f"Statistics saved to {filepath}")
    
    def save_all_lengths(self, filename=None):
        """Save all recorded message lengths to a file for detailed analysis"""
        if filename is None:
            filename = f"{self.default_filename}_all_lengths"
            
        # Ensure the filename has a proper extension
        if not filename.endswith('.txt'):
            filename += '.txt'
            
        filepath = os.path.join(self.output_dir, filename)
        
        # Save all lengths to file
        with open(filepath, 'w') as f:
            f.write("Message Lengths (in bytes):\n")
            for idx, length in enumerate(self.lengths):
                f.write(f"{idx+1}: {length}\n")
                
        print(f"All message lengths saved to {filepath}")