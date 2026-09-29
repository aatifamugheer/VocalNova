import os
import shutil
import subprocess


# ---------------------------------------------------------
# FFmpeg executable
# ---------------------------------------------------------

def get_ffmpeg_path() -> str:
    """
    Find FFmpeg even when it is not available in the
    PATH inherited by the FastAPI/Python process.
    """

    # First try normal PATH
    ffmpeg_path = shutil.which("ffmpeg")

    if ffmpeg_path:
        return ffmpeg_path

    # Then search the Windows WinGet installation directory
    winget_root = os.path.expandvars(
        r"%LOCALAPPDATA%\Microsoft\WinGet\Packages"
    )

    if os.path.isdir(winget_root):

        for root, _, files in os.walk(winget_root):

            for file in files:

                if file.lower() == "ffmpeg.exe":
                    return os.path.join(root, file)

    raise FileNotFoundError(
        "FFmpeg executable was not found."
    )


# ---------------------------------------------------------
# Audio conversion
# ---------------------------------------------------------

def convert_to_wav(
    input_path: str,
    output_path: str
) -> str:

    """
    Convert an audio file into WAV format.

    Output:
        - WAV
        - PCM 16-bit
        - 16 kHz
        - Mono

    Returns:
        Path of the converted WAV file.
    """

    # -----------------------------------------------------
    # Check input file
    # -----------------------------------------------------

    if not os.path.exists(input_path):

        raise FileNotFoundError(
            f"Input audio file not found: {input_path}"
        )

    # -----------------------------------------------------
    # Find FFmpeg
    # -----------------------------------------------------

    ffmpeg_path = get_ffmpeg_path()

    # -----------------------------------------------------
    # Create output directory if required
    # -----------------------------------------------------

    output_directory = os.path.dirname(
        os.path.abspath(output_path)
    )

    if output_directory:

        os.makedirs(
            output_directory,
            exist_ok=True
        )

    # -----------------------------------------------------
    # FFmpeg conversion
    # -----------------------------------------------------

    command = [
        ffmpeg_path,
        "-y",
        "-i",
        input_path,
        "-ar",
        "16000",
        "-ac",
        "1",
        "-c:a",
        "pcm_s16le",
        output_path
    ]

    process = subprocess.run(
        command,
        capture_output=True,
        text=True
    )

    # -----------------------------------------------------
    # Check conversion result
    # -----------------------------------------------------

    if process.returncode != 0:

        raise RuntimeError(
            "Audio conversion failed.\n\n"
            f"{process.stderr}"
        )

    # -----------------------------------------------------
    # Verify output
    # -----------------------------------------------------

    if not os.path.exists(output_path):

        raise RuntimeError(
            "FFmpeg finished, but output WAV file "
            "was not created."
        )

    return output_path