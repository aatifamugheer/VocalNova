from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class SpeechResult:
    attempt_id: str
    target_word: str
    recognized_text: str
    speech_score: float
    confidence: float
    feedback_type: str
    feedback_message: str
    timestamp: datetime
    error: Optional[str] = None