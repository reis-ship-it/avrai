"""
Dataset Registry

Registry of known personality datasets with metadata.
"""

from typing import Dict, List, Any, Optional

# Registry of known datasets
DATASETS: Dict[str, Dict[str, Any]] = {
    'big_five_kaggle': {
        'name': 'Big Five Personality Test (Kaggle)',
        'url': 'https://www.kaggle.com/datasets/tunguz/big-five-personality-test',
        'format': 'csv',
        'converter': 'big_five_to_spots',
        'columns': {
            'openness': ['openness', 'O', 'OPN', 'openness_score', 'open'],
            'conscientiousness': ['conscientiousness', 'C', 'CON', 'conscientiousness_score', 'conscientious'],
            'extraversion': ['extraversion', 'E', 'EXT', 'extraversion_score', 'extravert'],
            'agreeableness': ['agreeableness', 'A', 'AGR', 'agreeableness_score', 'agreeable'],
            'neuroticism': ['neuroticism', 'N', 'NEU', 'neuroticism_score', 'neurotic'],
        },
        'scale': '1-5',
        'description': '1M+ responses to Big Five personality test',
    },
    'ipip_neo': {
        'name': 'IPIP-NEO Personality Inventory',
        'url': 'https://openpsychometrics.org/_rawdata/',
        'format': 'csv',
        'converter': 'big_five_to_spots',
        'columns': {
            'openness': ['openness', 'O', 'OPN'],
            'conscientiousness': ['conscientiousness', 'C', 'CON'],
            'extraversion': ['extraversion', 'E', 'EXT'],
            'agreeableness': ['agreeableness', 'A', 'AGR'],
            'neuroticism': ['neuroticism', 'N', 'NEU'],
        },
        'scale': '1-5',
        'description': 'Open-source Big Five inventory',
    },
    'uci_personality': {
        'name': 'Personality Dataset (UCI ML Repository)',
        'url': 'https://archive.ics.uci.edu/ml/datasets/Personality+prediction',
        'format': 'csv',
        'converter': 'big_five_to_spots',
        'columns': {
            'openness': ['openness', 'O'],
            'conscientiousness': ['conscientiousness', 'C'],
            'extraversion': ['extraversion', 'E'],
            'agreeableness': ['agreeableness', 'A'],
            'neuroticism': ['neuroticism', 'N'],
        },
        'scale': 'auto',
        'description': 'Personality traits and behavioral data',
    },
}


def get_dataset_info(dataset_id: str) -> Optional[Dict[str, Any]]:
    """
    Get information about a registered dataset.
    
    Args:
        dataset_id: Dataset identifier
    
    Returns:
        Dataset information dict or None if not found
    """
    return DATASETS.get(dataset_id)


def list_datasets() -> List[str]:
    """
    List all registered dataset IDs.
    
    Returns:
        List of dataset IDs
    """
    return list(DATASETS.keys())


def register_dataset(dataset_id: str, info: Dict[str, Any]):
    """
    Register a new dataset.
    
    Args:
        dataset_id: Unique dataset identifier
        info: Dataset information dict
    """
    DATASETS[dataset_id] = info


def get_column_mappings(dataset_id: str) -> Optional[Dict[str, List[str]]]:
    """
    Get column name mappings for a dataset.
    
    Args:
        dataset_id: Dataset identifier
    
    Returns:
        Dict mapping Big Five dimensions to column name variations
    """
    dataset = get_dataset_info(dataset_id)
    if dataset:
        return dataset.get('columns')
    return None
