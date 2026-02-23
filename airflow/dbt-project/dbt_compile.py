#!/usr/bin/env python3
"""
Simple dbt Compile Script
Compile dbt models và in ra toàn bộ compiled SQL code
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
    """Compile dbt models và in compiled SQL"""
    
    # Parse arguments
    parser = argparse.ArgumentParser(description='Simple dbt compile script')
    parser.add_argument('--select', '-s', help='Select specific models to compile')
    parser.add_argument('--vars', help='dbt variables in JSON format')
    parser.add_argument('--target', '-t', help='dbt target profile')
    
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
    
    # Build dbt compile command
    cmd = ['ktl_dbt', 'compile']
    
    if args.select:
        cmd.extend(['--select', args.select])
        logger.info(f"🎯 Selecting models: {args.select}")
    
    if args.vars:
        cmd.extend(['--vars', args.vars])
        logger.info(f"📝 Using vars: {args.vars}")
    
    if args.target:
        cmd.extend(['--target', args.target])
        logger.info(f"🎯 Using target: {args.target}")
    
    # Add any unknown args
    cmd.extend(unknown_args)
    
    # Force no partial parse to ensure fresh compilation
    cmd.append('--no-partial-parse')
    
    logger.info(f"🚀 Running command: {' '.join(cmd)}")
    
    # Run dbt compile via subprocess
    logger.info("🔨 Running ktl_dbt compile...")
    
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
            logger.error(f"❌ ktl_dbt compile failed with return code: {return_code}")
            sys.exit(1)
        
        logger.info("✅ ktl_dbt compile completed successfully")
        
    except FileNotFoundError:
        logger.error("❌ Command not found: ktl_dbt")
        logger.error("Make sure ktl_dbt is installed and available in PATH")
        sys.exit(1)
    except Exception as e:
        logger.error(f"❌ Error running ktl_dbt compile: {str(e)}")
        sys.exit(1)
    
    # Read manifest.json to get compiled SQL
    target_dir = os.environ.get('DBT_TARGET_PATH', '/tmp/dbt_target')
    manifest_path = Path(target_dir) / 'manifest.json'
    
    if not manifest_path.exists():
        logger.error(f"❌ manifest.json not found at {manifest_path}")
        logger.error(f"💡 This usually means no models were compiled. Check:")
        logger.error(f"   1. Model selection criteria (--select argument)")
        logger.error(f"   2. Model names and paths in your dbt project")
        logger.error(f"   3. Whether models are enabled in dbt_project.yml")
        sys.exit(1)
    
    logger.info(f"📖 Reading manifest from {manifest_path}")
    
    with open(manifest_path, 'r', encoding='utf-8') as f:
        manifest = json.load(f)
    
    # Print compiled SQL for all models
    nodes = manifest.get('nodes', {})
    
    # Count models first
    model_nodes = {uid: node for uid, node in nodes.items() if node.get('resource_type') == 'model'}
    
    if not model_nodes:
        logger.warning("⚠️  No models found in manifest. This means dbt didn't compile any models.")
        logger.warning("💡 Check your model selection criteria and ensure models exist.")
        sys.exit(0)
    
    print("\n" + "="*80)
    print("COMPILED SQL CODE")
    print("="*80 + "\n")
    
    model_count = 0
    for unique_id, node in model_nodes.items():
        resource_type = node.get('resource_type')
        
        # Only process models
        if resource_type != 'model':
            continue
        
        model_count += 1
        model_name = node.get('name')
        database = node.get('database', '')
        schema = node.get('schema', '')
        alias = node.get('alias', model_name)
        
        # Get compiled SQL
        compiled_sql = node.get('compiled_code') or node.get('compiled_sql', '')
        
        # Print model info and SQL
        print(f"\n{'─'*80}")
        print(f"📄 Model: {model_name}")
        print(f"🗂️  Table: {database}.{schema}.{alias}")
        print(f"🆔 ID: {unique_id}")
        print(f"{'─'*80}\n")
        
        if compiled_sql:
            print(compiled_sql)
        else:
            print("⚠️  No compiled SQL found")
        
        print("\n")
    
    print("="*80)
    print(f"✅ Total models compiled: {model_count}")
    print("="*80)


if __name__ == "__main__":
    main()
