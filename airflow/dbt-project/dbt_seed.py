#!/usr/bin/env python3
"""
Simple dbt Seed Script
Load CSV files từ thư mục seeds/ vào database
"""

import os
import sys
import json
import logging
import argparse
import subprocess
from pathlib import Path

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


def main():
    """Load seed data vào database"""
    
    # Parse arguments
    parser = argparse.ArgumentParser(description='Simple dbt seed script')
    parser.add_argument('--select', '-s', help='Select specific seeds to load')
    parser.add_argument('--vars', help='dbt variables in JSON format')
    parser.add_argument('--target', '-t', help='dbt target profile')
    parser.add_argument('--full-refresh', action='store_true', help='Drop and recreate seed tables')
    
    args, unknown_args = parser.parse_known_args()
    
    # Set up dbt project directory
    dbt_project_dir = str(Path(__file__).resolve().parent)
    logger.info(f"📂 Working directory: {dbt_project_dir}")
    
    # Change to dbt project directory
    os.chdir(dbt_project_dir)
    
    # Set environment variables
    os.environ['DBT_PROFILES_DIR'] = dbt_project_dir
    os.environ['DBT_PROJECT_DIR'] = dbt_project_dir
    
    # Install dbt dependencies first if packages.yml exists
    packages_file = Path('packages.yml')
    if packages_file.exists():
        logger.info("📦 Found packages.yml, installing dependencies...")
        deps_cmd = ['ktl_dbt', 'deps']
        
        try:
            deps_process = subprocess.Popen(
                deps_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True,
            )
            
            for line in deps_process.stdout:
                print(line, end='')
            
            deps_return_code = deps_process.wait()
            
            if deps_return_code != 0:
                logger.error(f"❌ ktl_dbt deps failed with return code: {deps_return_code}")
                sys.exit(1)
            
            logger.info("✅ Dependencies installed successfully")
            
        except Exception as e:
            logger.error(f"❌ Error installing dependencies: {str(e)}")
            sys.exit(1)
    else:
        logger.info("📦 No packages.yml found, skipping dependency installation")
    
    # Build dbt seed command
    cmd = ['ktl_dbt', 'seed']
    
    if args.select:
        cmd.extend(['--select', args.select])
        logger.info(f"🎯 Selecting seeds: {args.select}")
    
    if args.vars:
        cmd.extend(['--vars', args.vars])
        logger.info(f"📝 Using vars: {args.vars}")
    
    if args.target:
        cmd.extend(['--target', args.target])
        logger.info(f"🎯 Using target: {args.target}")
    
    if args.full_refresh:
        cmd.append('--full-refresh')
        logger.info(f"🔄 Full refresh enabled")
    
    # Add any unknown args
    cmd.extend(unknown_args)
    
    logger.info(f"🚀 Running command: {' '.join(cmd)}")
    
    # Run dbt seed via subprocess
    logger.info("🌱 Running ktl_dbt seed...")
    
    try:
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            universal_newlines=True,
        )
        
        # Print output in real-time
        for line in process.stdout:
            print(line, end='')
        
        # Wait for process to complete
        return_code = process.wait()
        
        if return_code != 0:
            logger.error(f"❌ ktl_dbt seed failed with return code: {return_code}")
            sys.exit(1)
        
        logger.info("✅ ktl_dbt seed completed successfully")
        
    except FileNotFoundError:
        logger.error("❌ Command not found: ktl_dbt")
        logger.error("Make sure ktl_dbt is installed and available in PATH")
        sys.exit(1)
    except Exception as e:
        logger.error(f"❌ Error running ktl_dbt seed: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
