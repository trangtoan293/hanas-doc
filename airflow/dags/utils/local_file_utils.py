# import os

# def get_sqltext_from_sqlfile(filename):
#     try:
#         f = open(filename, 'r')
#         text_content = f.read()
#     except FileNotFoundError:
#         print(f"Error: File '{filename}' not found.")
#         return None
#     finally:
#         f.close()  # Ensure file is always closed

#     return text_content

# def fetch_data_from_local_folder(folder_locate, filter_filenames):
#     fetched_data = []
#     try:
#         filenames = os.listdir(folder_locate)
#         for filename in filenames:
#             filename_without_extention = filename.split('.')[0]
            
#             if filename_without_extention not in filter_filenames:
#                 continue
            
#             job = {}
#             job["entity_name"] = filename_without_extention.split('_')[1]
#             job["operation"] = filename_without_extention.split('_')[1]
#             job["sql_text"] = get_sqltext_from_sqlfile(folder_locate+'/'+filename)
#             job["src_table"] = filename_without_extention.split('_')[-1]
#             job["tgt_table"] = 'hub_toantt_customer'
            
#             fetched_data.append(job)
            
#     except FileNotFoundError:
#         print(f"Error: Folder '{folder_locate}' not found.")
#     finally:
#         return fetched_data
        
        
        