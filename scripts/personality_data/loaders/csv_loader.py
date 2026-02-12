"""
CSV Dataset Loader

Loads personality datasets from CSV files.
"""

import csv
from pathlib import Path
from typing import List, Dict, Any


class CSVLoader:
    """Loads personality datasets from CSV files."""
    
    @staticmethod
    def load(file_path: Path, encoding: str = 'utf-8') -> List[Dict[str, Any]]:
        """
        Load CSV file with personality data.
        
        Args:
            file_path: Path to CSV file
            encoding: File encoding (default: utf-8)
        
        Returns:
            List of profile dictionaries (one per row)
        """
        profiles = []
        
        with open(file_path, 'r', encoding=encoding) as f:
            reader = csv.DictReader(f)
            for row in reader:
                profiles.append(dict(row))
        
        return profiles
    
    @staticmethod
    def save(data: List[Dict[str, Any]], file_path: Path, encoding: str = 'utf-8'):
        """
        Save data to CSV file.
        
        Args:
            data: List of dictionaries to save
            file_path: Output CSV file path
            encoding: File encoding (default: utf-8)
        """
        if not data:
            return
        
        with open(file_path, 'w', newline='', encoding=encoding) as f:
            writer = csv.DictWriter(f, fieldnames=data[0].keys())
            writer.writeheader()
            writer.writerows(data)
