def generate_feedback(
    score: float,
    recognized_text: str,
    target_word: str,
    confidence: float = 1.0
):
    """
    Convert speech analysis into child-friendly feedback.

    These thresholds are prototype/product rules,
    NOT clinical speech-therapy standards.

    Low-confidence recognition is handled conservatively:
    the child is asked to try again instead of being
    confidently marked as incorrect.
    """

    # -----------------------------------------------------
    # 1. No speech detected
    # -----------------------------------------------------

    if not recognized_text.strip():

        return (
            "NO_SPEECH",
            "I didn't hear you. Try again!"
        )


    # -----------------------------------------------------
    # 2. Low recognition confidence
    # -----------------------------------------------------
    #
    # Do NOT confidently judge the child when the speech
    # recognizer itself is uncertain.
    #

    if confidence < 0.60:

        return (
            "LOW_CONFIDENCE_RETRY",
            "I wasn't quite sure. Let's try that again!"
        )


    # -----------------------------------------------------
    # 3. Very good attempt
    # -----------------------------------------------------

    if score >= 80:

        return (
            "GOOD",
            "Great job!"
        )


    # -----------------------------------------------------
    # 4. Partially correct attempt
    # -----------------------------------------------------

    if score >= 60:

        return (
            "RETRY",
            "Good try! Let's say it again."
        )


    # -----------------------------------------------------
    # 5. Low pronunciation score
    # -----------------------------------------------------

    return (
        "REMODEL_AND_RETRY",
        "Let's try that word together!"
    )