from pyvi import ViTokenizer
import errno
import fileinput
import re

def preprocess_vietnamese_for_pals(text):
    """Préprocesse le texte vietnamien pour le format PALS"""
    
    # tokenisation 
    tokenized = ViTokenizer.tokenize(text.strip())
    
    if not tokenized.strip():
        return ""
    
    # détection des fins de phrases (. ! ?)
    sentence_endings = re.split(r'([.!?]+)', tokenized)
    
    result = []
    
    for part in sentence_endings:
        if re.match(r'^[.!?]+$', part):
            # fin de phrase : ajouter le marqueur puis une ligne vide
            result.append(part.strip())
            result.append("")  # ligne vide pour séparer les phrases
        elif part.strip():
            # nettoyer et séparer les mots
            # supprimer la ponctuation inutile
            cleaned = re.sub(r'[^\w\s_]', ' ', part)
            # Séparer les tokens
            words = cleaned.split()
            
            for word in words:
                if word and len(word) > 1:  # pas de mots d'une seule lettre
                    # garder underscores pour les mots composés vietnamiens
                    result.append(word.lower())
    
    return '\n'.join(result)

try:
    for line in fileinput.input():
        processed = preprocess_vietnamese_for_pals(line)
        if processed:
            print(processed)
            
except IOError as e:
    if e.errno != errno.EPIPE:
        raise