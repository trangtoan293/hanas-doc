
import logging
from typing import Dict, Any, List, Optional

import pyarrow as pa
from pyiceberg.catalog import load_catalog
import uuid
from datetime import datetime, timedelta
import json
import pandas as pd
import numpy as np
from pyiceberg.partitioning import PartitionSpec
from pyiceberg.transforms import DayTransform, IdentityTransform
import requests
from utils.oracle_utils import (convert_schema,
                                get_schema_from_oracle)
import oracledb

class IcebergTableManager:
    """Enhanced Apache Iceberg table management for chunk-based storage"""

    def __init__(self, catalog_config: Dict[str, str], OUTPUT_BUCKET: str = "data"):
        self.catalog_config = catalog_config
        self.catalog = None
        self.OUTPUT_BUCKET = OUTPUT_BUCKET
        self.partition_spec = PartitionSpec()

    def initialize_catalog(self):
        """Initialize Iceberg catalog connection"""
        try:
            self.catalog = load_catalog("minio_catalog", **self.catalog_config)
            logging.info("Iceberg catalog initialized successfully")
        except Exception as e:
            logging.error(f"Failed to initialize Iceberg catalog: {str(e)}")
            raise

    def create_chunk_table_if_not_exists(
        self, namespace: str = "integration_demo", table_name: str = "ocr_chunks"
    ):
        """Create enhanced OCR chunks table for individual chunk storage"""
        try:
            table_identifier = f"{namespace}.{table_name}"

            # Enhanced schema for chunk-based storage
            schema = pa.schema([
                # Document identification
                pa.field("document_id", pa.string()),
                pa.field("document_name", pa.string()),
                pa.field("document_path", pa.string()),
                
                # Chunk identification and content
                pa.field("chunk_id", pa.string()),
                pa.field("chunk_content", pa.string()),
                pa.field("chunk_length", pa.int32()),
                pa.field("chunk_type", pa.string()),  # section, paragraph, sentence
                
                # Position and context
                pa.field("position_in_document", pa.int32()),
                pa.field("context_preserved", pa.bool_()),
                
                # Section-specific fields
                pa.field("section_title", pa.string()),
                pa.field("section_level", pa.int32()),
                pa.field("page_id", pa.int32()),
                
                # Content metrics
                pa.field("paragraph_count", pa.int32()),
                pa.field("sentence_count", pa.int32()),
                pa.field("word_count", pa.int32()),
                
                # Embeddings and vectors (for future use)
                pa.field("embedding_vector", pa.string()),  # JSON string of vector
                pa.field("embedding_model", pa.string()),
                
                # Processing metadata
                pa.field("processing_timestamp", pa.timestamp("ms")),
                pa.field("processing_version", pa.string()),
                pa.field("api_metadata", pa.string()),  # JSON string
                
                # Partitioning fields
                pa.field("processing_date", pa.date32()),
                pa.field("chunk_type_partition", pa.string()),
                
                pa.field("inserted_date", pa.timestamp("ms"))
            ])

            # Check if table exists
            try:
                table = self.catalog.load_table(table_identifier)
                logging.info(f"Table {table_identifier} already exists")
                return table
            except:
                # Table doesn't exist, create it
                logging.info(f"Creating new table: {table_identifier}")

                location_path = (
                    f"s3a://{self.OUTPUT_BUCKET}/warehouse/{namespace}/{table_name}"
                )
                
                with self.catalog.create_table_transaction(
                    identifier=table_identifier,
                    schema=schema,
                    location=location_path,
                    partition_spec=self.partition_spec,
                ) as txn:
                    # Add partitioning within the transaction
                    with txn.update_spec() as update:
                        update.add_field("processing_date", transform=DayTransform())
                        
                        update.add_field("chunk_type_partition", transform=IdentityTransform())

                table = self.catalog.load_table(table_identifier)
                logging.info(f"Table {table_identifier} created successfully")
                return table

        except Exception as e:
            logging.error(f"Error creating/accessing OCR chunks table: {str(e)}")
            raise

    def insert_chunks_to_table(
        self, 
        chunks_data: List[Dict[str, Any]], 
        document_metadata: Dict[str, Any],
        table_name: str = "ocr_chunks",
        namespace: str = "integration_demo"
    ):
        """Insert individual chunks as separate rows into Iceberg table"""
        try:
            # Get or create table
            table = self.create_chunk_table_if_not_exists(namespace, table_name)
            
            # Prepare data for insertion
            rows_to_insert = []
            processing_timestamp = datetime.now()
            processing_date = processing_timestamp.date()
            document_id = str(uuid.uuid4())
            
            for chunk in chunks_data:
                # Calculate word count
                word_count = len(chunk.get('content', '').split())
                
                # Prepare row data
                row = {
                    'document_id': document_id,
                    'document_name': document_metadata.get('file_name', 'unknown'),
                    'document_path': document_metadata.get('file_path', ''),
                    'chunk_id': str(uuid.uuid4()),
                    'chunk_content': chunk.get('content', ''),
                    'chunk_length': chunk.get('length', 0),
                    'chunk_type': chunk.get('chunk_type', 'unknown'),
                    'position_in_document': chunk.get('position_in_document', 0),
                    'context_preserved': chunk.get('context_preserved', True),
                    'section_title': chunk.get('section_title', ''),
                    'section_level': 0 if pd.isna(chunk.get('section_level', 0)) else int(chunk.get('section_level', 0)),
                    'page_id': chunk.get('page_id', 0),
                    'paragraph_count': chunk.get('paragraph_count', 0),
                    'sentence_count': chunk.get('sentence_count', 0),
                    'word_count': word_count,
                    'embedding_vector': '',  # To be populated by embedding service
                    'embedding_model': '',
                    'processing_timestamp': processing_timestamp,
                    'processing_version': '1.0',
                    'api_metadata': json.dumps(document_metadata.get('api_metadata', {})),
                    'processing_date': processing_date,
                    'chunk_type_partition': chunk.get('chunk_type', 'unknown')
                }
                
                rows_to_insert.append(row)
            
            # Convert to PyArrow table
            df = pd.DataFrame(rows_to_insert)
            df['processing_timestamp'] = df['processing_timestamp'].astype('datetime64[ms]')
            df["inserted_date"] = pd.Timestamp.utcnow().replace(tzinfo=None)
            df = df.astype({col: 'int32' for col in df.select_dtypes(include='int64').columns})
            arrow_table = pa.Table.from_pandas(df)
            
            # Insert data
            table.append(arrow_table)
            
            logging.info(f"Successfully inserted {len(rows_to_insert)} chunks for document {document_id}")
            return document_id
            
        except Exception as e:
            logging.error(f"Error inserting chunks to table: {str(e)}")
            raise

    def query_chunks_by_document(self, document_id: str, table_name: str = "ocr_chunks", namespace: str = "integration_demo"):
        """Query all chunks for a specific document"""
        try:
            table_identifier = f"{namespace}.{table_name}"
            table = self.catalog.load_table(table_identifier)
            
            # Perform query (this is a simplified example)
            # In practice, you'd use a proper query engine like Spark or Trino
            scan = table.scan(
                filter=("document_id", "==", document_id)
            )
            
            return scan.to_arrow()
            
        except Exception as e:
            logging.error(f"Error querying chunks: {str(e)}")
            raise

    def create_document_summary_table_if_not_exists(
        self, namespace: str = "integration_demo", table_name: str = "document_summaries"
    ):
        """Create table for document-level summaries and metadata"""
        try:
            table_identifier = f"{namespace}.{table_name}"

            schema = pa.schema([
                pa.field("document_id", pa.string()),
                pa.field("document_name", pa.string()),
                pa.field("document_path", pa.string()),
                pa.field("total_chunks", pa.int32()),
                pa.field("total_characters", pa.int32()),
                pa.field("total_words", pa.int32()),
                pa.field("total_sections", pa.int32()),
                pa.field("total_tables", pa.int32()),
                pa.field("total_paragraphs", pa.int32()),
                pa.field("total_lists", pa.int32()),
                pa.field("document_summary", pa.string()),  # AI-generated summary
                pa.field("key_topics", pa.string()),  # JSON array of topics
                pa.field("processing_timestamp", pa.timestamp("ms")),
                pa.field("processing_date", pa.date32()),
            ])

            try:
                table = self.catalog.load_table(table_identifier)
                logging.info(f"Document summary table {table_identifier} already exists")
                return table
            except:
                logging.info(f"Creating document summary table: {table_identifier}")
                
                location_path = f"s3a://{self.OUTPUT_BUCKET}/warehouse/{namespace}/{table_name}"
                table = self.catalog.create_table(
                    identifier=table_identifier,
                    schema=schema,
                    location=location_path
                )
                logging.info(f"Document summary table {table_identifier} created successfully")
                return table

        except Exception as e:
            logging.error(f"Error creating document summary table: {str(e)}")
            raise
    
    def drop_table(self, table_identifier: str):
        """Drop an Iceberg table"""
        try:
            if not self.catalog:
                self.initialize_catalog()

            self.catalog.drop_table(table_identifier)
            logging.info(f"Table '{table_identifier}' dropped successfully.")
        except Exception as e:
            logging.error(f"Failed to drop table '{table_identifier}': {str(e)}")
            raise

    def create_table_if_not_exists(
        self,
        namespace: str = None,
        table_name: str = None,
        schema: Optional[pa.Schema] = None,
    ):
        """Create OCR results table if it doesn't exist"""
        try:
            table_identifier = f"{namespace}.{table_name}"

            # Check if table exists
            try:
                table = self.catalog.load_table(table_identifier)
                logging.info(f"Table {table_identifier} already exists")
                return table
            except:
                # Table doesn't exist, create it
                logging.info(f"Creating new table: {table_identifier}")
                table = self.catalog.create_table(
                    identifier=table_identifier,
                    schema=schema,
                    location=f"s3a://{self.OUTPUT_BUCKET}/warehouse/{namespace}/{table_name}",
                    partition_spec=self.partition_spec,  # Can add partitioning later if needed
                )
                logging.info(f"Table {table_identifier} created successfully")
                return table

        except Exception as e:
            logging.error(f"Error creating/accessing OCR table: {str(e)}")
            raise



def write_to_iceberg_table_chunks(
    chunks_data: List[Dict[str, Any]], 
    document_metadata: Dict[str, Any],
    ICEBERG_CATALOG_CONFIG, **context
):
    """Write processed results to Apache Iceberg table chunks (enhanced for new API)"""
    if not chunks_data:
        logging.info("No results to write to Iceberg table")
        return
    try:
        iceberg_manager = IcebergTableManager(ICEBERG_CATALOG_CONFIG)
        iceberg_manager.initialize_catalog()
        
        # Insert chunks data and metadat into table
        table = iceberg_manager.insert_chunks_to_table(chunks_data=chunks_data, document_metadata=document_metadata)
        
        logging.info(
            f"Successfully wrote {len(chunks_data)} records to Iceberg table"
        )
    except Exception as e:
        logging.error(f"Error writing to Iceberg table: {str(e)}")
        raise
    


def write_to_iceberg_table(
    dsn:str,
    user:str,
    password:str, table_name_oracle:str, schema_oracle:str,
    ICEBERG_CATALOG_CONFIG,
    **context
):
    try:
        conn = oracledb.connect(user=user, password=password, dsn=dsn)
        query = f"SELECT * FROM {schema_oracle}.{table_name_oracle}"
        
        schema_oracle_table = get_schema_from_oracle(f"{table_name_oracle}", f"{schema_oracle}")
        schema_iceberg_table = convert_schema(schema_oracle_table)
        
        Iceberg_client = IcebergTableManager(catalog_config=ICEBERG_CATALOG_CONFIG)
        Iceberg_client.initialize_catalog()
        table = Iceberg_client.create_table_if_not_exists(namespace="phat_demo", table_name=table_name_oracle, schema=schema_iceberg_table)

        df = pd.read_sql(query, conn)
        df.columns = [col.lower() for col in df.columns]  # make it match arrow_schema
        for col in df.columns:
            if df[col].dtype == "datetime64[ns]":
                df[col] = df[col].astype("datetime64[ms]")
            elif df[col].dtype == "int64":
                df[col] = df[col].astype(np.int32)
                
        arrow_table = pa.Table.from_pandas(df)

        table.append(arrow_table)
    except Exception as e:
        logging.error(f"Error processing Oracle to Iceberg:{e}")
        raise 


def request_upload_text(url, data_content, file_name, author_upload):
    try:
        payload = {
            'text': data_content,
            'name': f'{file_name}',
            'semantic_chunking': 'true'
            }
        headers = {
        'Authorization': f'Bearer {author_upload}'
        }
        files = []
        response = requests.request("POST", url, headers=headers, data=payload, files=files)
        
        logging.info(f"Response from {url}: {response.status_code} - {response.text}")
    except requests.RequestException as e:
        logging.error(f"Error uploading text to {url}: {e}")