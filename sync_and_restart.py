import time
from roblox_mcp_client import RobloxStudioMCPClient
import sync_to_studio

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("Found Studio:", studio_id)

    # 1. Stop play if running
    print("Stopping play mode if active...")
    try:
        res = client.call_tool("start_stop_play", {
            "studio_id": studio_id,
            "is_start": False
        })
        print("Stop play response:", res)
    except Exception as e:
        print("Error stopping play:", e)

    time.sleep(1.5)
    client.close()

    # 2. Sync all scripts to Studio in Edit datamodel
    print("\n--- Synchronizing scripts to Studio ---")
    sync_to_studio.main()

    # 3. Restart play mode
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("\nStarting play mode...")
    res = client.call_tool("start_stop_play", {
        "studio_id": studio_id,
        "is_start": True
    })
    print("Start play response:", res)
    client.close()

    print("\n--- Done! ---")

if __name__ == "__main__":
    main()
