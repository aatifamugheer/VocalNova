import os
import shutil
import tempfile
from pathlib import Path

from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# from speech_ai.services.azure_speech_service import AzureSpeechService
from speech_ai.services.whisper_speech_service import WhisperSpeechService
from speech_ai.utils.audio_converter import convert_to_wav


# =========================================================
# FastAPI application
# =========================================================

app = FastAPI(
    title="VocalNova Speech AI API",
    description="Speech analysis backend for VocalNova",
    version="1.0.0"
)


# =========================================================
# CORS
# =========================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =========================================================
# Speech service
# =========================================================

speech_service = WhisperSpeechService()


# =========================================================
# Root endpoint
# =========================================================

@app.get("/")
def root():

    return {
        "status": "online",
        "service": "VocalNova Speech AI API",
        "version": "1.0.0"
    }


# =========================================================
# Health endpoint
# =========================================================

@app.get("/health")
def health():

    return {
        "status": "healthy"
    }


# =========================================================
# Speech analysis endpoint
# =========================================================

@app.post("/analyze-speech")
async def analyze_speech(
    targetWord: str = Form(...),
    attemptId: str = Form(...),
    language: str = Form("en-US"),
    audio: UploadFile = File(...)
):

    # -----------------------------------------------------
    # Validate target word
    # -----------------------------------------------------

    target_word = targetWord.strip()

    if not target_word:

        return JSONResponse(
            status_code=400,
            content={
                "error": "targetWord cannot be empty."
            }
        )


    # -----------------------------------------------------
    # Validate attempt ID
    # -----------------------------------------------------

    attempt_id = attemptId.strip()

    if not attempt_id:

        return JSONResponse(
            status_code=400,
            content={
                "error": "attemptId cannot be empty."
            }
        )


    # -----------------------------------------------------
    # Validate language
    # -----------------------------------------------------

    if not language.strip():

        language = "en-US"


    # -----------------------------------------------------
    # Validate uploaded audio
    # -----------------------------------------------------

    if not audio.filename:

        return JSONResponse(
            status_code=400,
            content={
                "error": "Audio file is required."
            }
        )


    # -----------------------------------------------------
    # Create temporary directory
    # -----------------------------------------------------

    temp_directory = tempfile.mkdtemp(
        prefix="vocalnova_"
    )


    try:

        # -------------------------------------------------
        # Determine file extension
        # -------------------------------------------------

        original_filename = audio.filename

        extension = Path(
            original_filename
        ).suffix.lower()

        if not extension:

            extension = ".audio"


        # -------------------------------------------------
        # Save uploaded file
        # -------------------------------------------------

        input_path = os.path.join(
            temp_directory,
            f"input{extension}"
        )

        with open(
            input_path,
            "wb"
        ) as buffer:

            shutil.copyfileobj(
                audio.file,
                buffer
            )


        # -------------------------------------------------
        # Convert to standard WAV
        # -------------------------------------------------

        wav_path = os.path.join(
            temp_directory,
            "converted.wav"
        )

        convert_to_wav(
            input_path=input_path,
            output_path=wav_path
        )


        # -------------------------------------------------
        # Analyze speech
        # -------------------------------------------------

        result = speech_service.analyze(
            attempt_id=attempt_id,
            target_word=target_word,
            audio_path=wav_path
        )


        # -------------------------------------------------
        # Return standardized result
        # -------------------------------------------------

        return {
            "attemptId": result.attempt_id,
            "targetWord": result.target_word,
            "recognizedText": result.recognized_text,
            "speechScore": result.speech_score,
            "confidence": result.confidence,
            "feedbackType": result.feedback_type,
            "feedbackMessage": result.feedback_message,
            "timestamp": result.timestamp.isoformat(),
            "error": result.error
        }


    except Exception as e:

        return JSONResponse(
            status_code=500,
            content={
                "attemptId": attempt_id,
                "targetWord": target_word,
                "recognizedText": "",
                "speechScore": 0,
                "confidence": 0,
                "feedbackType": "SERVICE_ERROR",
                "feedbackMessage": "Let's try that again.",
                "timestamp": None,
                "error": str(e)
            }
        )


    finally:

        # -------------------------------------------------
        # Delete temporary uploaded audio
        # -------------------------------------------------

        shutil.rmtree(
            temp_directory,
            ignore_errors=True
        )
