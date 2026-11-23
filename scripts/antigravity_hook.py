#!/usr/bin/env python3
import sys
import json
import os
from datetime import datetime, timezone

def main():
    event = sys.argv[1] if len(sys.argv) > 1 else ""

    payload = {}
    try:
        raw_input = sys.stdin.read()
        if raw_input.strip():
            payload = json.loads(raw_input)
    except Exception:
        pass

    dave_dir = os.path.expanduser("~/.dave")
    os.makedirs(dave_dir, exist_ok=True)
    status_file = os.path.join(dave_dir, "status.json")

    cid = payload.get("conversationId", "")
    task = payload.get("lastUserInput", "")
    timestamp = datetime.now(timezone.utc).isoformat()

    out_response = {}

    if event == "pre_invocation":
        status_data = {
            "isBusy": True,
            "state": "debugging",
            "task": task,
            "statusText": "收到任务，正在深入思考与规划方案... 🧠",
            "conversationId": cid,
            "updatedAt": timestamp
        }
        try:
            if os.path.exists(status_file):
                with open(status_file, "r", encoding="utf-8") as rf:
                    existing = json.load(rf)
                    if "action" in existing:
                        status_data["action"] = existing["action"]
            with open(status_file, "w", encoding="utf-8") as f:
                json.dump(status_data, f, ensure_ascii=False, indent=2)
        except Exception:
            pass
        out_response = {}

    elif event == "pre_tool_use":
        tool_call = payload.get("toolCall", {})
        tool_name = tool_call.get("name", "")
        args = tool_call.get("args", {})
        summary = args.get("toolSummary", "")
        if isinstance(summary, str):
            summary = summary.strip("\"' ")

        if tool_name in ["edit_file", "write_file"]:
            state = "coding"
            text = f"正在修改代码: {summary}" if summary else "正在疯狂码字编写代码... 💻"
        elif tool_name == "run_command":
            state = "coding"
            text = f"正在执行指令: {summary}" if summary else "正在执行命令 / 构建测试... ⚙️"
        elif tool_name in ["read_file", "search_web", "search_marketplace", "read_resource", "list_resources"]:
            state = "debugging"
            text = f"正在查阅分析: {summary}" if summary else "正在抓虫思考 / 查阅资料... 🔍"
        else:
            state = "coding"
            text = f"正在调用工具: {tool_name} ⚡️"

        status_data = {
            "isBusy": True,
            "state": state,
            "tool": tool_name,
            "task": task,
            "statusText": text,
            "conversationId": cid,
            "updatedAt": timestamp
        }
        try:
            if os.path.exists(status_file):
                with open(status_file, "r", encoding="utf-8") as rf:
                    existing = json.load(rf)
                    if "action" in existing:
                        status_data["action"] = existing["action"]
            with open(status_file, "w", encoding="utf-8") as f:
                json.dump(status_data, f, ensure_ascii=False, indent=2)
        except Exception:
            pass
        out_response = {"decision": "allow"}

    elif event == "post_tool_use":
        out_response = {}

    elif event == "stop":
        reason = payload.get("terminationReason", "")
        error_msg = payload.get("error", "")
        is_error = reason in ["ERROR", "USER_CANCELED"] or bool(error_msg)
        state = "debugging" if is_error else "celebrating"
        text = f"任务遇到异常中断: {error_msg}" if (is_error and error_msg) else ("哎呀，任务遇到网络或异常问题中断了 ⚠️" if is_error else "搞定啦！Antigravity 任务已顺利完成！🎉✨")

        status_data = {
            "isBusy": False,
            "isError": is_error,
            "state": state,
            "task": task,
            "statusText": text,
            "conversationId": cid,
            "updatedAt": timestamp
        }
        try:
            if os.path.exists(status_file):
                with open(status_file, "r", encoding="utf-8") as rf:
                    existing = json.load(rf)
                    if "action" in existing:
                        status_data["action"] = existing["action"]
            with open(status_file, "w", encoding="utf-8") as f:
                json.dump(status_data, f, ensure_ascii=False, indent=2)
        except Exception:
            pass
        out_response = {}

    print(json.dumps(out_response))

if __name__ == "__main__":
    main()
