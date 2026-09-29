from abc import ABC, abstractmethod

from speech_ai.models.speech_result import SpeechResult


class SpeechService(ABC):

    @abstractmethod
    def analyze(
        self,
        attempt_id: str,
        target_word: str,
        audio_path: str
    ) -> SpeechResult:
        """
        Analyze recorded speech and return a SpeechResult.
        """
        pass