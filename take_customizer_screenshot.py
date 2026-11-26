import base64
import json
import shutil
import os
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # Capture screen with camera showing the plot, shops, and the Customizer UI
    res = client.call_tool("screen_capture", {
        "studio_id": sid,
        "capture_id": "customizer_engine_verified",
        "camera_position": [-10.0, 16.0, 48.0],
        "look_at_position": [-22.0, 8.0, 8.0]
    })

    if res.get("isError"):
        print("Capture error:", res)
    else:
        for item in res.get("content", []):
            if item.get("type") == "image":
                img_bytes = base64.b64decode(item.get("data", ""))
                out_path = "customizer_verified.png"
                with open(out_path, "wb") as f:
                    f.write(img_bytes)
                print(f"Captured {out_path} ({len(img_bytes)} bytes)")
                
                # Copy to artifact directory
                artifact_dir = r"C:\Users\Monster\.gemini\antigravity\brain\03546efd-d2fd-4681-99a5-598800761051"
                artifact_path = os.path.join(artifact_dir, "customizer_verified.png")
                shutil.copyfile(out_path, artifact_path)
                print(f"Copied to artifact path: {artifact_path}")
                break

    client.close()

if __name__ == "__main__":
    main()
