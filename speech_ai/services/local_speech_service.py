import json
import os
import wave
from difflib import SequenceMatcher
from datetime import datetime

from vosk import Model, KaldiRecognizer

from speech_ai.models.speech_result import SpeechResult
from speech_ai.services.speech_service import SpeechService
from speech_ai.utils.feedback import generate_feedback


class LocalSpeechService(SpeechService):

    def __init__(self):
        project_root = os.path.abspath(
            os.path.join(
                os.path.dirname(__file__),
                "..",
                "..",
            )
        )

        self.model_path = os.path.join(
            project_root,
            "speech_models",
            "vosk-model-small-en-us-0.15",
        )

        if not os.path.isdir(self.model_path):
            raise ValueError(
                f"Vosk model not found: {self.model_path}"
            )

        self.model = Model(self.model_path)

    def analyze(
        self,
        attempt_id: str,
        target_word: str,
        audio_path: str,
    ) -> SpeechResult:

        try:
            with wave.open(audio_path, "rb") as audio:

                if audio.getnchannels() != 1:
                    raise ValueError(
                        "Audio must be mono."
                    )

                if audio.getsampwidth() != 2:
                    raise ValueError(
                        "Audio must use 16-bit PCM."
                    )

                sample_rate = audio.getframerate()

                recognizer = KaldiRecognizer(
                    self.model,
                    sample_rate,
                    json.dumps([target_word]),
                )

                recognizer.SetWords(True)

                partial_results = []

                while True:
                    data = audio.readframes(4000)

                    if not data:
                        break

                    if recognizer.AcceptWaveform(data):
                        partial_results.append(
                            json.loads(
                                recognizer.Result()
                            )
                        )

                result = json.loads(
                    recognizer.FinalResult()
                )

            if not result.get("text"):
                for partial in reversed(partial_results):
                    if partial.get("text"):
                        result = partial
                        break

            recognized_text = (
                result.get("text", "")
                .strip()
                .lower()
            )

            target = target_word.strip().lower()

            score = self._calculate_score(
                target,
                recognized_text,
            )

            confidence = (
                1.0 if recognized_text else 0.0
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

        similarity = SequenceMatcher(
            None,
            target_word,
            recognized_text,
        ).ratio()

        return round(
            max(
                0.0,
                min(
                    100.0,
                    similarity * 100,
                ),
            ),
            2,
        )