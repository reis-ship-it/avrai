"""
JSON Dataset Loader

Loads personality datasets from JSON files.
"""

import json
from pathlib import Path
from typing import List, Dict, Any, Union


class JSONLoader:
    """Loads personality datasets from JSON files."""
    
    @staticmethod
    def load(file_path: Path, encoding: str = 'utf-8') -> List[Dict[str, Any]]:
        """
        Load JSON file with personality data.
        
        Handles different JSON structures:
        - List of profiles: [{"user_id": "...", ...}, ...]
        - Dict with 'profiles' key: {"profiles": [...]}
        - Dict with 'data' key: {"data": [...]}
        - Single profile: {"user_id": "...", ...}
        
        Args:
            file_path: Path to JSON file
            encoding: File encoding (default: utf-8)
        
        Returns:
            List of profile dictionaries
        """
        with open(file_path, 'r', encoding=encoding) as f:
            data = json.load(f)
        
        # Handle different JSON structures
        if isinstance(data, list):
            return data
        elif isinstance(data, dict):
            if 'profiles' in data:
                return data['profiles']
            elif 'data' in data:
                return data['data']
            else:
                # Assume it's a single profile
                return [data]
        else:
            return []
    
    @staticmethod
    def save(
        data: Union[List[Dict[str, Any]], Dict[str, Any]],
        file_path: Path,
        indent: int = 2,
        encoding: str = 'utf-8'
    ):
        """
        Save data to JSON file.
        
        Args:
            data: Data to save (list or dict)
            file_path: Output JSON file path
            indent: JSON indentation (default: 2)
            encoding: File encoding (default: utf-8)
        """
        with open(file_path, 'w', encoding=encoding) as f:
            json.dump(data, f, indent=indent, ensure_ascii=False)
