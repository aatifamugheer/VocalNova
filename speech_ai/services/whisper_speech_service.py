import os
from datetime import datetime
from difflib import SequenceMatcher

from faster_whisper import WhisperModel

from speech_ai.models.speech_result import SpeechResult
from speech_ai.services.speech_service import SpeechService
from speech_ai.utils.feedback import generate_feedback


class WhisperSpeechService(SpeechService):

    def __init__(self):
        # CPU + INT8 keeps the prototype lightweight.
        self.model = WhisperModel(
            "tiny.en",
            device="cpu",
            compute_type="int8",
        )

    def analyze(
        self,
        attempt_id: str,
        target_word: str,
        audio_path: str,
    ) -> SpeechResult:

        try:
            if not os.path.isfile(audio_path):
                raise FileNotFoundError(
                    f"Audio file not found: {audio_path}"
                )

            segments, info = self.model.transcribe(
                audio_path,
                language="en",
                beam_size=5,
                vad_filter=True,
            )

            recognized_text = " ".join(
                segment.text.strip()
                for segment in segments
                if segment.text.strip()
            ).lower().strip()

            target = target_word.strip().lower()

            score = self._calculate_score(
                target,
                recognized_text,
            )

            confidence = self._calculate_confidence(
                target,
                recognized_text,
            )

            feedback_type, feedback_message = (
                generate_feedback(
                    score=score,
                    recognized_text=recognized_text,
                    target_word=target_word,
                    confidence=confidence,
                )
            )

            return SpeechResult(
                attempt_id=attempt_id,
                target_word=target_word,
                recognized_text=recognized_text,
                speech_score=score,
                confidence=confidence,
                feedback_type=feedback_type,
                feedback_message=feedback_message,
                timestamp=datetime.now(),
            )

        except Exception as e:
            return SpeechResult(
                attempt_id=attempt_id,
                target_word=target_word,
                recognized_text="",
                speech_score=0,
                confidence=0,
                feedback_type="SERVICE_ERROR",
                feedback_message="Let's try that again.",
                timestamp=datetime.now(),
                error=str(e),
            )

    @staticmethod
    def _calculate_score(
        target_word: str,
        recognized_text: str,
    ) -> float:

        if not recognized_text:
            return 0.0

        # Look for the target as a complete word.
        recognized_words = recognized_text.split()

        if target_word in recognized_words:
            return 100.0

        # Otherwise compare against the closest recognized word.
        best_similarity = 0.0

        for word in recognized_words:
            similarity = SequenceMatcher(
                None,
                target_word,
                word,
            ).ratio()

            best_similarity = max(
                best_similarity,
                similarity,
            )

        return round(
            best_similarity * 100,
            2,
        )

    @staticmethod
    def _calculate_confidence(
        target_word: str,
        recognized_text: str,
    ) -> float:

        if not recognized_text:
            return 0.0

        recognized_words = recognized_text.split()

        if target_word in recognized_words:
            return 1.0

        best_similarity = 0.0

        for word in recognized_words:
            similarity = SequenceMatcher(
                None,
                target_word,
                word,
            ).ratio()

            best_similarity = max(
                best_similarity,
                similarity,
            )

        return round(
            best_similarity,
            2,
        )