from datetime import datetime

from speech_ai.models.speech_result import SpeechResult
from speech_ai.services.speech_service import SpeechService
from speech_ai.utils.feedback import generate_feedback


class MockSpeechService(SpeechService):

    def analyze(
        self,
        attempt_id: str,
        target_word: str,
        audio_path: str = "",
        scenario: str = "good"
    ) -> SpeechResult:

        if scenario == "good":
            recognized_text = target_word
            score = 92
            confidence = 0.94

        elif scenario == "retry":
            recognized_text = "wabbit"
            score = 65
            confidence = 0.82

        elif scenario == "bad":
            recognized_text = "abbit"
            score = 45
            confidence = 0.70

        elif scenario == "silent":
            recognized_text = ""
            score = 0
            confidence = 0.0

        else:
            recognized_text = ""
            score = 0
            confidence = 0.0

        feedback_type, feedback_message = generate_feedback(
            score,
            recognized_text,
            target_word
        )

        return SpeechResult(
            attempt_id=attempt_id,
            target_word=target_word,
            recognized_text=recognized_text,
            speech_score=score,
            confidence=confidence,
            feedback_type=feedback_type,
            feedback_message=feedback_message,
            timestamp=datetime.now()
        )