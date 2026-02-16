#!/usr/bin/env python3
import asyncio
import time
import sys
import threading
import json
import urllib.request
import urllib.error
import types
from pathlib import Path
from unittest.mock import patch, MagicMock

# Add repository root to path
ROOT_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT_DIR))

# Import wbabd components
# Load wbabd module using exec, avoiding main execution
wbabd_path = ROOT_DIR / "tools/wbabd"
if not wbabd_path.exists():
    print(f"Error: {wbabd_path} not found", file=sys.stderr)
    sys.exit(1)

with open(str(wbabd_path)) as f:
    code = f.read()
    code = code.replace('if __name__ == "__main__":', 'if False:')
    wbabd = types.ModuleType("wbabd")
    wbabd.__file__ = str(wbabd_path)
    exec(code, wbabd.__dict__)
    sys.modules["wbabd"] = wbabd

def make_request_sync(port, op_id):
    url = f"http://127.0.0.1:{port}/run"
    data = json.dumps({
        "op_id": op_id,
        "verb": "doctor", # doctor is a valid verb
        "args": []
    }).encode()

    start_time = time.time()
    try:
        req = urllib.request.Request(url, data=data, method="POST")
        req.add_header("Content-Type", "application/json")
        # Wait up to 10 seconds.
        with urllib.request.urlopen(req, timeout=10) as response:
            _resp_body = response.read()
    except Exception as e:
        print(f"Request error for {op_id}: {e}")
        return 0

    end_time = time.time()
    return end_time - start_time

async def make_request(port, op_id):
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(None, make_request_sync, port, op_id)

def run_server(port, stop_event):
    # Patch wbabd.Executor.run to be slow
    with patch.object(wbabd.Executor, 'run') as mock_run:
        def side_effect(plan):
            # Simulate work
            time.sleep(2)
            return {"status": "succeeded", "result": "ok"}

        mock_run.side_effect = side_effect

        # Setup mocks for dependencies
        store = MagicMock()
        store.get_instance_id.return_value = "test-instance"
        planner = wbabd.Planner()
        audit = MagicMock()
        executor = wbabd.Executor(ROOT_DIR, store, audit=audit)

        # We need to run the async server in a loop
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        async def run():
            server = await asyncio.start_server(
                lambda r, w: wbabd._handle_http(r, w, store, planner, executor, "off", "", None, audit, 1024*1024),
                "127.0.0.1", port
            )

            # Serve until stopped
            async def check_stop():
                while not stop_event.is_set():
                    await asyncio.sleep(0.1)
                server.close()
                await server.wait_closed()

            stop_task = asyncio.create_task(check_stop())

            # Start serving
            await server.serve_forever()

            await stop_task

        try:
            loop.run_until_complete(run())
        except asyncio.CancelledError:
            pass
        except Exception:
            pass # Server closed
        finally:
            loop.close()

async def main():
    port = 8789 # Use a different port just in case
    stop_event = threading.Event()

    server_thread = threading.Thread(target=run_server, args=(port, stop_event))
    server_thread.start()

    # Wait for server to start
    await asyncio.sleep(2)

    print("Sending two requests concurrently...")

    start_total = time.time()
    # Run two requests concurrently
    task1 = asyncio.create_task(make_request(port, "op1"))
    task2 = asyncio.create_task(make_request(port, "op2"))

    results = await asyncio.gather(task1, task2)
    end_total = time.time()

    total_time = end_total - start_total
    print(f"Request 1 duration: {results[0]:.2f}s")
    print(f"Request 2 duration: {results[1]:.2f}s")
    print(f"Total time for both requests: {total_time:.2f}s")

    stop_event.set()
    server_thread.join()

    # If requests run concurrently, total time should be roughly max of durations (2s)
    # If sequentially, roughly sum (4s)

    if total_time >= 3.8:
        print("FAIL: Requests ran sequentially (blocking). Total time >= 3.8s")
        sys.exit(1)
    else:
        print("SUCCESS: Requests ran concurrently. Total time < 3.8s")
        sys.exit(0)

if __name__ == "__main__":
    asyncio.run(main())
