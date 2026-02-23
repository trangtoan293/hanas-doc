import datetime
import os
import yaml
import uuid

def get_default_crdfile_folder_locate():
    # # Define the path to the 'dags' directory relative to the current working directory
    # dags_path = "/opt/airflow/dags"

    # # Get a list of all directories in the 'dags' directory
    # dirs_in_dags = [d for d in os.listdir(dags_path) if os.path.isdir(os.path.join(dags_path, d))]

    # # Sort the list of directories by length in descending order
    # sorted_dirs = sorted(dirs_in_dags, key=len, reverse=True)

    # # Get the longest folder name
    # longest_folder_name = sorted_dirs[0]

    # # Construct the desired path
    # # desired_path = os.path.join(dags_path, longest_folder_name, "/dags/crd_file")
    # desired_path = f"{dags_path}/{longest_folder_name}/dags/crd_file"
    desired_path = os.getcwd()+'/dags/crd_file/batch'
    print("Desired Path:", desired_path)
    return desired_path

def get_default_pyspark_crd_dict(p_yaml_file_path=None):
    if p_yaml_file_path is None:
        # yaml_file_path = get_default_crdfile_folder_locate()+'/pyspark-batch-crd-template.yaml'
        yaml_file_path = '/opt/airflow/dags/repo/dags/crd_file/batch/pyspark-batch-crd-template.yaml'
        if not os.path.exists(yaml_file_path):
            raise Exception("Sorry, bug",yaml_file_path)
        
    else:
        yaml_file_path = p_yaml_file_path
    with open(yaml_file_path, 'r') as file:
        yaml_content_dict = yaml.safe_load(file)
    return yaml_content_dict

def generate_yaml_string(yaml_content_dict):
    yaml_string = yaml.dump(yaml_content_dict, default_flow_style=False)
    return yaml_string

def generate_crd_pod_name(yaml_content_dict:dict):
    unique_id = str(uuid.uuid4())
    current_time_str = datetime.datetime.now().strftime('%Y%m%d-%H%M%S%f')
    pod_name = yaml_content_dict['metadata']['name']
    pod_name = 'py-'+current_time_str
    # pod_name = pod_name+'-'+current_time_str
    # pod_name='submit'+unique_id
    return pod_name

def generate_crd_with_submission_file(yaml_content_dict:dict, submit_file_locate:str):
    
    # Define mainApplicationFile with submit_file_locate
    submit_mainApplicationFile = submit_file_locate
    
    yaml_content_dict['spec']['mainApplicationFile'] = f'{submit_mainApplicationFile}'
    
    # Define pod_name with submit_file name
    pod_name = yaml_content_dict['metadata']['name']
    
    ## Get sub_file_name without extension
    submit_file_name = submit_file_locate.split("/")[-1].split(".")[0]
    submit_file_name = submit_file_name.replace("_","-")
    # pod_name = pod_name+'-'+submit_file_name
    
    # yaml_content_dict['metadata']['name'] = pod_name
    
    return yaml_content_dict
