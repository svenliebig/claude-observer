"""Tests for observer-hook.py summarize_tool_input function."""
import os


def summarize_tool_input(tool_name, tool_input):
    """Copy of the hook function for testing. Must stay in sync."""
    if not tool_input or not isinstance(tool_input, dict):
        return ""
    if tool_name == "Bash":
        return tool_input.get("command", "")
    if tool_name in ("Edit", "Write", "Read"):
        path = tool_input.get("file_path", "")
        home = os.path.expanduser("~")
        if path.startswith(home):
            path = "~" + path[len(home):]
        return path
    if tool_name in ("Glob", "Grep"):
        return tool_input.get("pattern", "")
    if tool_name == "WebFetch":
        return tool_input.get("url", "")
    if tool_name == "WebSearch":
        return tool_input.get("query", "")
    if tool_name == "AskUserQuestion":
        questions = tool_input.get("questions", [])
        if questions and isinstance(questions, list):
            return questions[0].get("question", "")
        return ""
    for v in tool_input.values():
        if isinstance(v, str) and v:
            return v[:80]
    return ""


def test_ask_user_question():
    tool_input = {
        "questions": [
            {
                "question": "Which approach do you prefer?",
                "header": "Approach",
                "options": [
                    {"label": "Option A", "description": "First approach"},
                    {"label": "Option B", "description": "Second approach"},
                ],
                "multiSelect": False,
            }
        ]
    }
    result = summarize_tool_input("AskUserQuestion", tool_input)
    assert result == "Which approach do you prefer?", f"Got: {result}"


def test_ask_user_question_empty():
    result = summarize_tool_input("AskUserQuestion", {"questions": []})
    assert result == "", f"Got: {result}"


def test_ask_user_question_no_questions():
    result = summarize_tool_input("AskUserQuestion", {})
    assert result == "", f"Got: {result}"


def test_bash_command():
    result = summarize_tool_input("Bash", {"command": "npm run test"})
    assert result == "npm run test"


def test_write_file_path():
    result = summarize_tool_input("Write", {"file_path": "/Users/test/file.ts"})
    assert result == "/Users/test/file.ts"


def test_web_search():
    result = summarize_tool_input("WebSearch", {"query": "python async"})
    assert result == "python async"


def test_unknown_tool_fallback():
    result = summarize_tool_input("CustomTool", {"arg": "some value"})
    assert result == "some value"


def test_empty_input():
    result = summarize_tool_input("Bash", {})
    assert result == ""


def test_none_input():
    result = summarize_tool_input("Bash", None)
    assert result == ""


if __name__ == "__main__":
    test_ask_user_question()
    test_ask_user_question_empty()
    test_ask_user_question_no_questions()
    test_bash_command()
    test_write_file_path()
    test_web_search()
    test_unknown_tool_fallback()
    test_empty_input()
    test_none_input()
    print("All tests passed.")
