import logging
import sys

# Cấu hình logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(name)s - %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),  # Write log to console
    ],
)

# Tạo logger chung
logger = logging.getLogger("dbt_workflow")
