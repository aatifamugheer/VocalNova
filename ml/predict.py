import joblib
import pandas as pd

# Load trained model
model = joblib.load("ml/vocalnova_model.pkl")

# Example practice session
session = pd.DataFrame([{
    "session_duration": 7.5,
    "attempt_count": 10,
    "success_rate": 0.70,
    "skip_rate": 0.20,
    "practice_days_7d": 4,
    "difficulty_level": 2,
}])

# Predict practice pattern
prediction = model.predict(session)[0]

print("Predicted practice pattern:", prediction)

# Generate simple interpretable insights
print("\nPractice Insights:")

if session["success_rate"].iloc[0] >= 0.75:
    print("- Strong success rate.")
elif session["success_rate"].iloc[0] >= 0.50:
    print("- Moderate success rate.")
else:
    print("- Low success rate.")

if session["skip_rate"].iloc[0] <= 0.20:
    print("- Few exercises were skipped.")
elif session["skip_rate"].iloc[0] <= 0.50:
    print("- Some exercises were skipped.")
else:
    print("- Many exercises were skipped.")

if session["practice_days_7d"].iloc[0] >= 5:
    print("- Practice frequency is high.")
elif session["practice_days_7d"].iloc[0] >= 3:
    print("- Practice frequency is moderate.")
else:
    print("- Practice frequency is low.")