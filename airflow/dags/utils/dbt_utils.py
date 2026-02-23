import json 
import os
import logging
from datetime import datetime, timedelta
from airflow.exceptions import AirflowFailException


class DBTUtils:
    @staticmethod
    def data_result_to_file(data:json=None, save_path:str="/tmp/dbt_results", name_file:str="run_results.json"):
        file_path= os.path.join(save_path, name_file)

        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4, ensure_ascii=False)
        
        return f"Write result data to file {save_path}/{name_file}"
        
    @staticmethod
    def cp_file_metadata_dbt(list_name_file=["manifest.json", "catalog.json"], path_file="/tmp/dbt_results/", path_folder_destination="/opt/airflow/sharedatahub/"):
        cp_command = " && ".join([f"cp {path_file}{file_name} {path_folder_destination}" for file_name in list_name_file])
        print(cp_command)
        return cp_command

    @staticmethod
    def get_params_dbt(**kwargs):
        dag_conf = kwargs.get('dag_run').conf or {}

        if "datavault_run" not in dag_conf:
            raise AirflowFailException("[FAILED] --- Not found 'datavault_run' in params input.")
        
        elif not dag_conf.get('datavault_run'):
            raise AirflowFailException("[FAILED] --- Params 'datavault_run' cannot be empty.")
        
        return "run_rawvault" if "datavault_run" in dag_conf else "end"

    @staticmethod
    def parse_log(data):
        """ Parser log data result model and return structure results. """
        log_model_dict = [
            {
                "table_name": item['unique_id'],
                "status": item['status'],
                "log_message": item['message'],
                "execution_time": item['execution_time']
            }
            for item in data['results']
        ]

        for item in log_model_dict:
            log_model = f"Model creating sql {item['status']} table {item['table_name']} [{item['log_message']} IN {item['execution_time']}]"
            logging.info(log_model)

        return log_model_dict
