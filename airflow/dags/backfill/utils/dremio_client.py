"""
Dremio API Client for creating views and reflections.
Handles authentication, view creation, and reflection management.
"""

import requests
import logging
from typing import Dict, List, Optional
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger(__name__)


class DremioClient:
    """Client for interacting with Dremio REST API."""
    
    def __init__(self, base_url: str, username: str, password: str, ssl_verify: bool = True):
        """
        Initialize Dremio client.
        
        Args:
            base_url: Base URL of Dremio API (e.g., http://10.10.101.54:9047)
            username: Dremio username
            password: Dremio password
            ssl_verify: Whether to verify SSL certificates
        """
        self.base_url = base_url.rstrip('/')
        self.api_base = f"{self.base_url}/api/v3"
        self.username = username
        self.password = password
        self.ssl_verify = ssl_verify
        self.token = None
        self.session = self._create_session()
        
    def _create_session(self) -> requests.Session:
        """Create a requests session with retry logic."""
        session = requests.Session()
        retry = Retry(
            total=3,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504],
        )
        adapter = HTTPAdapter(max_retries=retry)
        session.mount("http://", adapter)
        session.mount("https://", adapter)
        return session
        
    def login(self) -> str:
        """
        Authenticate with Dremio and get access token.
        
        Returns:
            str: Authentication token
        """
        url = f"{self.base_url}/apiv2/login"
        payload = {
            "userName": self.username,
            "password": self.password
        }
        
        logger.info(f"Logging in to Dremio at {url}")
        response = self.session.post(
            url,
            json=payload,
            verify=self.ssl_verify
        )
        response.raise_for_status()
        
        self.token = response.json()["token"]
        self.session.headers.update({"Authorization": f"_dremio{self.token}"})
        logger.info("Successfully authenticated with Dremio")
        return self.token
        
    def get_catalog_id(self, path: List[str]) -> Optional[str]:
        """
        Get catalog ID for a given path.
        
        Args:
            path: List representing the path (e.g., ["DATA_MART", "view_name"])
            
        Returns:
            Catalog ID if found, None otherwise
        """
        url = f"{self.api_base}/catalog/by-path/{'/'.join(path)}"
        
        try:
            response = self.session.get(url, verify=self.ssl_verify)
            response.raise_for_status()
            return response.json()["id"]
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 404:
                return None
            raise
            
    def create_vds(self, space: str, view_name: str, sql: str) -> Dict:
        """
        Create or replace a Virtual Dataset (VDS/View) in Dremio.
        
        Args:
            space: Space name (e.g., "DATA_MART")
            view_name: Name of the view to create
            sql: SQL query for the view
            
        Returns:
            Response JSON from Dremio API
        """
        # Check if view already exists
        view_path = [space, view_name]
        existing_id = self.get_catalog_id(view_path)
        
        if existing_id:
            logger.info(f"View {view_name} already exists, deleting before recreate")
            self._delete_vds_with_reflections(existing_id)
        
        logger.info(f"Creating new view {view_name}")
        return self._create_new_vds(space, view_name, sql)
    
    def _update_vds(self, view_id: str, space: str, view_name: str, sql: str) -> Dict:
        """Update an existing VDS in place."""
        import time
        url = f"{self.api_base}/catalog/{view_id}"
        
        try:
            # Get current view details for tag
            response = self.session.get(url, verify=self.ssl_verify)
            response.raise_for_status()
            current = response.json()
            tag = current.get("tag")
            
            # Update the view with new SQL
            payload = {
                "entityType": "dataset",
                "type": "VIRTUAL_DATASET",
                "path": [space, view_name],
                "sql": sql,
                "sqlContext": [space],
                "tag": tag
            }
            
            logger.info(f"Updating view {view_name} (ID: {view_id})")
            response = self.session.put(
                url,
                json=payload,
                verify=self.ssl_verify
            )
            response.raise_for_status()
            logger.info(f"Successfully updated view {view_name}")
            return response.json()
        except Exception as e:
            logger.warning(f"Failed to update view in place: {e}")
            logger.info(f"Attempting to delete and recreate view {view_name}")
            
            # Wait a bit for Dremio to stabilize
            time.sleep(2)
            
            # If update fails, try delete and recreate
            # Note: We need to refresh the view info before deleting
            try:
                self._delete_vds_with_reflections(view_id)
                return self._create_new_vds(space, view_name, sql)
            except Exception as delete_error:
                logger.error(f"Failed to delete and recreate view: {delete_error}")
                # Last resort: just try to create (might work if view was partially deleted)
                logger.info(f"Attempting direct creation as last resort")
                try:
                    return self._create_new_vds(space, view_name, sql)
                except:
                    # If all else fails, re-raise the original error
                    raise e
    
    def _delete_vds_with_reflections(self, view_id: str) -> None:
        """Delete an existing VDS and its reflections."""
        import time
        
        # First, try to delete all reflections for this dataset
        try:
            self._delete_reflections(view_id)
            # Wait for reflection deletion to complete
            time.sleep(1)
        except Exception as e:
            logger.warning(f"Error deleting reflections: {e}")
        
        # Now delete the view - refresh tag first
        url = f"{self.api_base}/catalog/{view_id}"
        
        try:
            # Refresh view details to get latest tag
            response = self.session.get(url, verify=self.ssl_verify)
            response.raise_for_status()
            current = response.json()
            tag = current.get("tag")
            
            # Delete the view
            logger.info(f"Deleting view with ID {view_id} (tag: {tag})")
            delete_url = f"{url}?tag={tag}" if tag else url
            response = self.session.delete(delete_url, verify=self.ssl_verify)
            response.raise_for_status()
            logger.info(f"Successfully deleted view")
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 409:
                logger.warning(f"View deletion conflict (409), it may have dependencies or be in use")
                logger.info(f"Waiting 3 seconds and retrying with fresh tag...")
                time.sleep(3)
                
                # Try one more time with a fresh tag
                try:
                    response = self.session.get(url, verify=self.ssl_verify)
                    response.raise_for_status()
                    current = response.json()
                    tag = current.get("tag")
                    delete_url = f"{url}?tag={tag}" if tag else url
                    response = self.session.delete(delete_url, verify=self.ssl_verify)
                    response.raise_for_status()
                    logger.info(f"Successfully deleted view on retry")
                except Exception as retry_error:
                    logger.error(f"Failed to delete view even after retry: {retry_error}")
                    raise
            else:
                logger.error(f"Error deleting view: {e}")
                raise
        except Exception as e:
            logger.error(f"Error deleting view: {e}")
            # If we still can't delete, try force deletion without tag
            logger.info(f"Attempting force deletion without tag verification")
            try:
                response = self.session.delete(url, verify=self.ssl_verify)
                if response.status_code in [200, 204]:
                    logger.info(f"Successfully force-deleted view")
                else:
                    logger.error(f"Force deletion also failed with status {response.status_code}")
                    raise
            except Exception as force_error:
                logger.error(f"Force deletion failed: {force_error}")
                raise
    
    def _delete_reflections(self, dataset_id: str) -> None:
        """Delete all reflections for a dataset."""
        url = f"{self.api_base}/reflection"
        
        try:
            # Get all reflections
            response = self.session.get(url, verify=self.ssl_verify)
            response.raise_for_status()
            reflections = response.json().get("data", [])
            
            logger.info(f"Found {len(reflections)} total reflections in Dremio")
            
            # Filter reflections for this dataset
            dataset_reflections = [r for r in reflections if r.get("datasetId") == dataset_id]
            
            logger.info(f"Found {len(dataset_reflections)} reflections for dataset {dataset_id}")
            
            # Delete each reflection
            for reflection in dataset_reflections:
                reflection_id = reflection.get("id")
                reflection_name = reflection.get("name", "Unknown")
                if reflection_id:
                    logger.info(f"Deleting reflection '{reflection_name}' (ID: {reflection_id})")
                    delete_url = f"{url}/{reflection_id}"
                    try:
                        self.session.delete(delete_url, verify=self.ssl_verify)
                        logger.info(f"Successfully deleted reflection {reflection_id}")
                    except Exception as e:
                        logger.warning(f"Failed to delete reflection {reflection_id}: {e}")
        except Exception as e:
            logger.warning(f"Error listing reflections: {e}")
            
    def _create_new_vds(self, space: str, view_name: str, sql: str) -> Dict:
        """Create a new VDS."""
        url = f"{self.api_base}/catalog"
        
        payload = {
            "entityType": "dataset",
            "type": "VIRTUAL_DATASET",
            "path": [space, view_name],
            "sql": sql,
            "sqlContext": [space]
        }
        
        logger.info(f"Creating view {view_name} in space {space}")
        try:
            response = self.session.post(
                url,
                json=payload,
                verify=self.ssl_verify
            )
            response.raise_for_status()
            logger.info(f"Successfully created view {view_name}")
            return response.json()
        except Exception as e:
            logger.error(f"Failed to create view {view_name}: {e}")
            if hasattr(e, 'response') and e.response is not None:
                try:
                    error_detail = e.response.json()
                    logger.error(f"Dremio error details: {error_detail}")
                except:
                    logger.error(f"Dremio response text: {e.response.text[:500]}")
            raise
        
    def create_raw_reflection(self, dataset_id: str, display_columns: List[str] = None) -> Dict:
        """
        Create a raw reflection for a dataset.
        
        Args:
            dataset_id: ID of the dataset
            display_columns: List of columns to display (None = all columns)
            
        Returns:
            Response JSON from Dremio API
        """
        url = f"{self.api_base}/reflection"
        
        # Check if reflections already exist for this dataset
        try:
            response = self.session.get(url, verify=self.ssl_verify)
            response.raise_for_status()
            reflections = response.json().get("data", [])
            
            # Check if there's already a raw reflection for this dataset
            existing_reflections = [r for r in reflections 
                                   if r.get("datasetId") == dataset_id 
                                   and r.get("type") == "RAW"]
            
            if existing_reflections:
                logger.info(f"Raw reflection already exists for dataset {dataset_id}, skipping creation")
                return existing_reflections[0]
        except Exception as e:
            logger.warning(f"Error checking existing reflections: {e}")
        
        # Get dataset details to extract columns if not provided
        if display_columns is None:
            dataset_url = f"{self.api_base}/catalog/{dataset_id}"
            response = self.session.get(dataset_url, verify=self.ssl_verify)
            response.raise_for_status()
            dataset = response.json()
            
            # Extract column names from dataset fields
            fields = dataset.get("fields", [])
            display_columns = [{"name": field["name"]} for field in fields]
        else:
            display_columns = [{"name": col} for col in display_columns]
        
        payload = {
            "type": "RAW",
            "datasetId": dataset_id,
            "enabled": True,
            "name": "Raw Reflection",
            "displayFields": display_columns,
            "partitionDistributionStrategy": "CONSOLIDATED"
        }
        
        logger.info(f"Creating raw reflection for dataset {dataset_id}")
        response = self.session.post(
            url,
            json=payload,
            verify=self.ssl_verify
        )
        response.raise_for_status()
        logger.info(f"Successfully created raw reflection")
        return response.json()
        
    def close(self):
        """Close the session."""
        if self.session:
            self.session.close()
