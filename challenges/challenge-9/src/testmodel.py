import os
import argparse
import numpy as np
import gymnasium as gym
from stable_baselines3 import PPO, SAC
from stable_baselines3.common.vec_env import DummyVecEnv, VecFrameStack

def parse_arguments():
    parser = argparse.ArgumentParser(description="Evaluate a trained RL model for car racing")
    parser.add_argument('--model_path', type=str, default='car_racing_model.zip',
                        help='Path to the trained model file')
    parser.add_argument('--episodes', type=int, default=5,
                        help='Number of episodes to run')
    parser.add_argument('--render', action='store_true',
                        help='Render the environment')
    parser.add_argument('--model', type=str, default='PPO',
                        choices=['PPO', 'SAC'],
                        help='Model type to use for evaluation')
    return parser.parse_args()

def make_env():
    def _init():
        env = gym.make("CarRacing-v3", domain_randomize=True, render_mode="human")
        return env
    return _init

def main():
    args = parse_arguments()
    
    # Get the directory of the script
    model_dir = os.path.dirname(os.path.abspath(__file__))
    model_path = os.path.join(model_dir, args.model_path)
    
    if not os.path.exists(model_path):
        print(f"Model file not found: {model_path}")
        return
    
    print(f"Loading model from {model_path}...")
    
    # Create environment
    env = DummyVecEnv([make_env()])
    env = VecFrameStack(env, n_stack=4)  # Same stack as during training
    
    # Load the trained model
    if args.model == 'PPO':
        model = PPO.load(model_path, env=env)
    elif args.model == 'SAC':
        # If using SAC, ensure the environment is compatible
        model = SAC.load(model_path, env=env)
    
    # Run the model
    total_rewards = []
    for i in range(args.episodes):
        obs = env.reset()
        done = False
        episode_reward = 0
        step = 0
        
        print(f"Running episode {i+1}/{args.episodes}...")
        
        while not done:
            action, _ = model.predict(obs, deterministic=True)
            obs, reward, done, info = env.step(action)
            episode_reward += reward[0]
            step += 1
            done = done[0]
            
            if step % 100 == 0:
                print(f"Step: {step}, Reward so far: {episode_reward}")
        
        total_rewards.append(episode_reward)
        print(f"Episode {i+1} finished with reward: {episode_reward}")
        
    env.close()
    
    print(f"Average reward over {args.episodes} episodes: {np.mean(total_rewards)}")

if __name__ == "__main__":
    main()