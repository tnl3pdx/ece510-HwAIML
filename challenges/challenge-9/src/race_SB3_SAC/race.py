import os
import argparse
import numpy as np
from stable_baselines3 import SAC  # Changed from PPO to SAC
from stable_baselines3.common.vec_env import DummyVecEnv, VecFrameStack
from stable_baselines3.common.callbacks import CheckpointCallback
import gymnasium as gym

def parse_arguments():
    parser = argparse.ArgumentParser(description="Train an RL model for car racing")
    parser.add_argument('--timesteps', type=int, default=100000,
                        help='Number of timesteps to train the model')
    parser.add_argument('--model_name', type=str, default='car_racing_model',
                        help='Name of the output model file')
    parser.add_argument('--checkpoint_freq', type=int, default=10000,
                        help='Frequency to save checkpoints during training')
    return parser.parse_args()

def make_env():
    def _init():
        env = gym.make("CarRacing-v3", domain_randomize=True)
        return env
    return _init

def main():
    args = parse_arguments()
    
    print(f"Creating CarRacing environment...")
    # Create vectorized environment for stability
    env = DummyVecEnv([make_env()])
    env = VecFrameStack(env, n_stack=4)  # Stack frames for temporal information
    
    # Define model directory
    model_dir = os.path.dirname(os.path.abspath(__file__))
    checkpoint_dir = os.path.join(model_dir, "checkpoints")
    os.makedirs(checkpoint_dir, exist_ok=True)
    
    # Setup callback for saving checkpoints
    checkpoint_callback = CheckpointCallback(
        save_freq=args.checkpoint_freq,
        save_path=checkpoint_dir,
        name_prefix=args.model_name
    )
    
    print(f"Initializing SAC model...")  # Changed from PPO to SAC
    model = SAC(  # Changed from PPO to SAC
        "CnnPolicy",
        env,
        verbose=1,
        learning_rate=3e-4,
        buffer_size=50000,         # SAC specific parameter
        learning_starts=1000,      # SAC specific parameter
        batch_size=64,
        tau=0.005,                 # SAC specific parameter
        gamma=0.99,
        train_freq=1,              # SAC specific parameter
        gradient_steps=1,          # SAC specific parameter
        ent_coef="auto",           # SAC specific parameter
        tensorboard_log=os.path.join(model_dir, "tensorboard_logs")
    )
    
    print(f"Training model for {args.timesteps} timesteps...")
    model.learn(
        total_timesteps=args.timesteps,
        callback=checkpoint_callback
    )
    
    # Save the final model
    model_path = os.path.join(model_dir, f"{args.model_name}.zip")
    model.save(model_path)
    print(f"Model saved to {model_path}")
    
    # Close environment
    env.close()

if __name__ == "__main__":
    main()

