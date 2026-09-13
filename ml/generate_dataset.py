import csv
import random
from datetime import datetime, timedelta

random.seed(42)

NUM_CHILDREN = 100
SESSIONS_PER_CHILD = 10
PATTERNS = [
    "Low",
    "Medium",
    "High",
]
rows = []

for child_number in range(1, NUM_CHILDREN + 1):
    child_id = f"C{child_number:03d}"

    pattern = PATTERNS[(child_number - 1) % 3]

    start_date = datetime.now() - timedelta(days=30)
    
    session_dates = []

    for session_number in range(SESSIONS_PER_CHILD):
        if pattern == "Low":
            day_offset = random.randint(0, 6)

        elif pattern == "Medium":
            day_offset = random.randint(0, 14)

        else:
            day_offset = random.randint(0, 30)

        session_date = start_date + timedelta(days=day_offset)
        
        session_dates.append(session_date)
        
        assigned_exercises = random.randint(3, 8)

        attempt_count = random.randint(4, 15)

        if pattern == "Low":
            skip_count = random.randint(0, 1)
            success_rate_base = random.uniform(0.75, 1.00)
            session_duration = random.uniform(5, 12)

        elif pattern == "Medium":
            skip_count = random.randint(1, 3)
            success_rate_base = random.uniform(0.50, 0.80)
            session_duration = random.uniform(4, 10)

        else:
            skip_count = random.randint(2, assigned_exercises)
            success_rate_base = random.uniform(0.30, 0.65)
            session_duration = random.uniform(2, 8)

        success_count = round(
            attempt_count * success_rate_base
        )

        success_count = max(
            1,
            min(success_count, attempt_count)
        )

        session_duration = round(session_duration, 1)

        difficulty_level = random.randint(1, 3)
        success_rate = round(
            success_count / attempt_count, 2
        )

        skip_rate = round(
            skip_count / assigned_exercises, 2
        )

        practice_days_7d = 0
        
        recent_dates = [
            date for date in session_dates
            if date <= session_date
            and (session_date - date).days < 7
        ]

        practice_days_7d = len({
            date.date()
            for date in recent_dates
        })
        
        rows.append({
            "child_id": child_id,
            "session_date": session_date.strftime("%Y-%m-%d"),
            "session_duration": session_duration,
            "attempt_count": attempt_count,
            "success_count": success_count,
            "skip_count": skip_count,
            "assigned_exercises": assigned_exercises,
            "practice_days_7d": practice_days_7d,
            "difficulty_level": difficulty_level,
            "success_rate": success_rate,
            "skip_rate": skip_rate,
            "pattern": pattern,
        })
output_file = "ml/data/practice_sessions.csv"

fieldnames = [
    "child_id",
    "session_date",
    "session_duration",
    "attempt_count",
    "success_count",
    "skip_count",
    "assigned_exercises",
    "practice_days_7d",
    "difficulty_level",
    "success_rate",
    "skip_rate",
    "pattern",
]

with open(output_file, "w", newline="") as file:
    writer = csv.DictWriter(file, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)


print(f"Dataset created: {output_file}")
print(f"Total rows: {len(rows)}")

