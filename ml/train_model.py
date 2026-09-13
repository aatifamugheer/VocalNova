import pandas as pd

df = pd.read_csv("ml/data/practice_sessions.csv")

print(df.head())
print("\nShape:", df.shape)
features = [
    "session_duration",
    "attempt_count",
    "success_rate",
    "skip_rate",
    "practice_days_7d",
    "difficulty_level",
]

X = df[features]
y = df["pattern"]

print("\nFeatures:")
print(X.head())

print("\nTarget:")
print(y.head())

from sklearn.model_selection import train_test_split

children = df["child_id"].unique()

train_children, test_children = train_test_split(
    children,
    test_size=0.20,
    random_state=42
)

train_df = df[df["child_id"].isin(train_children)]
test_df = df[df["child_id"].isin(test_children)]

X_train = train_df[features]
y_train = train_df["pattern"]

X_test = test_df[features]
y_test = test_df["pattern"]

print("\nTraining rows:", len(X_train))
print("Testing rows:", len(X_test))
print("Training children:", len(train_children))
print("Testing children:", len(test_children))
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression

model = Pipeline([
    ("scaler", StandardScaler()),
    ("classifier", LogisticRegression(max_iter=1000))
])

model.fit(X_train, y_train)

print("\nModel trained successfully!")
model.fit(X_train, y_train)

print("\nModel trained successfully!")

from sklearn.metrics import accuracy_score, classification_report

y_pred = model.predict(X_test)

accuracy = accuracy_score(y_test, y_pred)

print("\nLogistic Regression Accuracy:", round(accuracy, 4))
print("\nClassification Report:")
print(classification_report(y_test, y_pred))

from sklearn.tree import DecisionTreeClassifier

tree_model = DecisionTreeClassifier(
    max_depth=5,
    random_state=42
)

tree_model.fit(X_train, y_train)

tree_pred = tree_model.predict(X_test)

tree_accuracy = accuracy_score(y_test, tree_pred)

print("\nDecision Tree Accuracy:", round(tree_accuracy, 4))
print("\nDecision Tree Classification Report:")
print(classification_report(y_test, tree_pred))

from sklearn.ensemble import RandomForestClassifier

forest_model = RandomForestClassifier(
    n_estimators=100,
    max_depth=5,
    random_state=42
)

forest_model.fit(X_train, y_train)

import joblib

joblib.dump(forest_model, "ml/vocalnova_model.pkl")

print("\nRandom Forest model saved successfully!")

forest_pred = forest_model.predict(X_test)

forest_accuracy = accuracy_score(y_test, forest_pred)

print("\nRandom Forest Accuracy:", round(forest_accuracy, 4))
print("\nRandom Forest Classification Report:")
print(classification_report(y_test, forest_pred))

print("\nFeatures used by Random Forest:")
print(features)