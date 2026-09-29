import os
import json
from datetime import datetime

import azure.cognitiveservices.speech as speechsdk
from dotenv import load_dotenv

from speech_ai.models.speech_result import SpeechResult
from speech_ai.services.speech_service import SpeechService
from speech_ai.services.mock_speech_service import MockSpeechService
from speech_ai.utils.feedback import generate_feedback


load_dotenv()


class AzureSpeechService(SpeechService):

    def __init__(self):

        self.speech_key = os.getenv(
            "AZURE_SPEECH_KEY"
        )

        self.speech_region = os.getenv(
            "AZURE_SPEECH_REGION"
        )

        if not self.speech_key:

            raise ValueError(
                "AZURE_SPEECH_KEY is missing"
            )

        if not self.speech_region:

            raise ValueError(
                "AZURE_SPEECH_REGION is missing"
            )

        # Safe demo fallback.
        self.mock_service = MockSpeechService()


    def analyze(
        self,
        attempt_id: str,
        target_word: str,
        audio_path: str
    ) -> SpeechResult:

        try:

            # -------------------------------------------------
            # 1. Azure configuration
            # -------------------------------------------------

            speech_config = speechsdk.SpeechConfig(
                subscription=self.speech_key,
                region=self.speech_region
            )

            speech_config.speech_recognition_language = (
                "en-US"
            )


            # -------------------------------------------------
            # 2. Audio configuration
            # -------------------------------------------------

            audio_config = speechsdk.audio.AudioConfig(
                filename=audio_path
            )


            # -------------------------------------------------
            # 3. Speech recognizer
            # -------------------------------------------------

            recognizer = speechsdk.SpeechRecognizer(
                speech_config=speech_config,
                audio_config=audio_config
            )


            # -------------------------------------------------
            # 4. Pronunciation assessment
            # -------------------------------------------------

            pronunciation_config = (
                speechsdk.PronunciationAssessmentConfig(
                    reference_text=target_word,
                    grading_system=(
                        speechsdk
                        .PronunciationAssessmentGradingSystem
                        .HundredMark
                    ),
                    granularity=(
                        speechsdk
                        .PronunciationAssessmentGranularity
                        .Phoneme
                    ),
                    enable_miscue=False
                )
            )

            pronunciation_config.apply_to(
                recognizer
            )


            # -------------------------------------------------
            # 5. Recognize speech
            # -------------------------------------------------

            result = (
                recognizer
                .recognize_once_async()
                .get()
            )


            # -------------------------------------------------
            # 6. Successful recognition
            # -------------------------------------------------

            if (
                result.reason
                == speechsdk.ResultReason.RecognizedSpeech
            ):

                recognized_text = (
                    result.text or ""
                )


                # ---------------------------------------------
                # Pronunciation score
                # ---------------------------------------------

                assessment = (
                    speechsdk.PronunciationAssessmentResult(
                        result
                    )
                )

                score = float(
                    assessment.pronunciation_score or 0
                )


                # ---------------------------------------------
                # Recognition confidence
                # ---------------------------------------------

                confidence = 0.0

                try:

                    data = json.loads(
                        result.json
                    )

                    if data.get("NBest"):

                        confidence = float(
                            data["NBest"][0].get(
                                "Confidence",
                                0.0
                            )
                        )

                except Exception:

                    confidence = 0.0


                # ---------------------------------------------
                # Child-friendly feedback
                # ---------------------------------------------

                feedback_type, feedback_message = (
                    generate_feedback(
                        score=score,
                        recognized_text=recognized_text,
                        target_word=target_word,
                        confidence=confidence
                    )
                )


                # ---------------------------------------------
                # Standardized result
                # ---------------------------------------------

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


            # -------------------------------------------------
            # 7. No speech recognized
            # -------------------------------------------------

            elif (
                result.reason
                == speechsdk.ResultReason.NoMatch
            ):

                return SpeechResult(
                    attempt_id=attempt_id,
                    target_word=target_word,
                    recognized_text="",
                    speech_score=0,
                    confidence=0,
                    feedback_type="NO_SPEECH",
                    feedback_message=(
                        "I didn't hear you. Try again!"
                    ),
                    timestamp=datetime.now(),
                    error="NO_MATCH"
                )


            # -------------------------------------------------
            # 8. Azure cancellation
            # -------------------------------------------------

            elif (
                result.reason
                == speechsdk.ResultReason.Canceled
            ):

                cancellation = (
                    speechsdk.CancellationDetails(
                        result
                    )
                )

                return self._fallback_result(
                    attempt_id=attempt_id,
                    target_word=target_word,
                    error=cancellation.error_details
                )


            # -------------------------------------------------
            # 9. Unknown response
            # -------------------------------------------------

            else:

                return self._fallback_result(
                    attempt_id=attempt_id,
                    target_word=target_word,
                    error="Unknown Azure Speech result"
                )


        # -----------------------------------------------------
        # 10. Unexpected error
        # -----------------------------------------------------

        except Exception as e:

            return self._fallback_result(
                attempt_id=attempt_id,
                target_word=target_word,
                error=str(e)
            )


    # =========================================================
    # SAFE DEMO FALLBACK
    # =========================================================

    def _fallback_result(
        self,
        attempt_id: str,
        target_word: str,
        error: str
    ) -> SpeechResult:

        fallback = self.mock_service.analyze(
            attempt_id=attempt_id,
            target_word=target_word,
            audio_path="",
            scenario="retry"
        )


        fallback.feedback_type = (
            "FALLBACK_RETRY"
        )

        fallback.feedback_message = (
            "Let's try that again."
        )

        fallback.error = (
            "Azure unavailable. "
            "Demo fallback used. "
            f"Reason: {error}"
        )

        return fallback