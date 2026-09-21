import subprocess
import json
import time
import os
import sys

bat_path = os.path.expandvars(r"%LOCALAPPDATA%\Roblox\mcp.bat")

class RobloxStudioMCPClient:
    def __init__(self):
        self.proc = subprocess.Popen(
            ["cmd.exe", "/c", bat_path],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace",
            bufsize=0
        )
        self.msg_id = 0
        self._init()

    def _send(self, obj):
        line = json.dumps(obj) + "\n"
        self.proc.stdin.write(line)
        self.proc.stdin.flush()

    def _read(self):
        return json.loads(self.proc.stdout.readline())

    def _init(self):
        self.msg_id += 1
        self._send({
            "jsonrpc": "2.0",
            "id": self.msg_id,
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "antigravity", "version": "1.0.0"}
            }
        })
        self._read()
        self._send({"jsonrpc": "2.0", "method": "notifications/initialized"})
    def get_studio_id(self, timeout=10):
        start = time.time()
        while time.time() - start < timeout:
            res = self.call_tool("list_roblox_studios")
            txt = res.get("content", [{}])[0].get("text", "")
            try:
                data = json.loads(txt)
                studios = data.get("studios", [])
                if studios:
                    return studios[0]["id"]
            except Exception:
                pass
            time.sleep(0.5)
        raise RuntimeError("No connected Roblox Studio instance found within timeout")

    def call_tool(self, name, args={}):
        self.msg_id += 1
        self._send({
            "jsonrpc": "2.0",
            "id": self.msg_id,
            "method": "tools/call",
            "params": {
                "name": name,
                "arguments": args
            }
        })
        res = self._read()
        return res.get("result", {})

    def close(self):
        self.proc.terminate()

if __name__ == "__main__":
    client = RobloxStudioMCPClient()
    tool_name = sys.argv[1]
    if len(sys.argv) > 2:
        arg_str = sys.argv[2]
        if arg_str.startswith("@") and os.path.exists(arg_str[1:]):
            with open(arg_str[1:], "r", encoding="utf-8") as f:
                args = json.load(f)
        else:
            args = json.loads(arg_str)
    else:
        args = {}
    res = client.call_tool(tool_name, args)
    print(json.dumps(res, indent=2))
    client.close()
