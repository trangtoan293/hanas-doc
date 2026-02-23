from airflow.models import BaseOperator
from airflow.utils.decorators import apply_defaults

from io import BytesIO
import logging
import smtplib
import json 
import os 

import signal
from airflow.exceptions import AirflowException

class CustomDbtOperator(BaseOperator):
    """ Custom DBT Operator Airflow to Trigger DBT task"""
    
    @apply_defaults
    def __init__(self, 
                 dbt_task,
                 command=None,
                 *args,
                 **kwargs):
        super().__init__(*args, **kwargs)
        self.dbt_task = dbt_task
        self.command = command
    
    
        
    def execute(self, context):
        logger = logging.getLogger("airflow.task")
        logger.info(f"Starting DBT workflow with config ---- {self.command}")
            
        # def signal_handler(signum, frame):
        #     logger.info("[WARNING] TASK MANUALLY MASKED FAILED FROM UI")
        #     # Cleanup logic ở đây
        #     raise AirflowException("Task manually failed")
        
        # signal.signal(signal.SIGTERM, signal_handler)
        try:
            
            result = self.dbt_task.task_run(self.command)
            
            #info_model_run = parse_log(data=result['result'])
            
            logger.info("DBT run completed.")
            #logger.info(run_results_to_file(data=result['result']))

            return {"info_model": result}
        # except AirflowException:
        #     # Handle manual fail
        #     raise
        except Exception as e:
            raise Exception(f"DBTWorkflowOperator failed: {str(e)}")
    

def parse_log(data):
    """ Parser log data and return structured results."""
    log_message_dict = [
        {   "Table": item['unique_id'],
            "Status": item['status'],
            "Message": item['message'],
            "Execution_Time": item['execution_time']
        }
        for item in data['results']
    ]
    for item in log_message_dict:
        log_message = f"Model creating sql {item['Status']} table {item['Table']} [{item['Message']} IN {item['Execution_Time']}]"
        logging.info(log_message)
    
    return log_message_dict

def run_results_to_file(data:json=None, save_path:str="/tmp/dbt_results", name_file:str="run_results.json"):
    file_path = os.path.join(save_path, name_file)
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
    
    return f"Write result data to file {save_path}/{name_file}"


def config_to_email(email_to:str, subject:str, body:str, 
                      EMAIL_SENDER:str, EMAIL_PASSWORD:str,
                      SMTP_SERVER:str = "smtp.gmail.com", SMTP_PORT:int = 587):
    try:
        message = f"""Subject: {subject}
                   {body}
        """

        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(EMAIL_SENDER, EMAIL_PASSWORD)
            server.sendmail(EMAIL_SENDER, email_to, message)
            server.quit()

        logging.info(" Email sent successfully!")

    except Exception as e:
        logging.error(f" Error sending email: {e}")

def send_email(context=None, status_type:str=None, email_to:str=None, email_sender:str=None, email_pass:str=None):
    
    if status_type == "fail":
        email_subject = "DBT Workflow Failed"
        email_body = f"""{context}"""
        
        config_to_email(CONTEXT=email_body)
        
    email_subject = "DBT Workflow Success"
    email_body = f"""{context}"""
    
    config_to_email(email_to=email_to, subject=email_subject, body=email_body, EMAIL_SENDER=email_sender, EMAIL_PASSWORD=email_pass)