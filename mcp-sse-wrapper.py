#!/opt/conda/bin/python
"""Production SSE adapter for comfy-mcp.

Wraps the stdio comfy-mcp (mcp SDK 2.x) behind an SSE server. Uses the
official mcp SDK SseServerTransport + Server proxy pattern.

Architecture:
  LLM Client (opencode) <-> SSE <-> mcp-sse-wrapper (this) <-> stdio <-> comfy-mcp

This replaces mcp-proxy (which requires mcp<2 and is incompatible with
comfy-mcp's mcp 2.x dependency).
"""
import logging
import os
from starlette.applications import Starlette
from starlette.responses import JSONResponse, Response
from starlette.routing import Route, Mount
from starlette.types import Receive, Scope, Send

from mcp.server.sse import SseServerTransport
from mcp.server.lowlevel.server import Server
from mcp.server.models import InitializationOptions
from mcp.client.stdio import stdio_client, StdioServerParameters
from mcp.client.session import ClientSession
import anyio
import uvicorn

logging.basicConfig(level=logging.INFO)
COMFY_LOCAL_URL = os.environ.get("COMFY_LOCAL_URL", "http://127.0.0.1:8188")
COMFY_MCP_PATH = os.environ.get("COMFY_MCP_PATH", "/opt/conda/bin/comfy-mcp")

# ONE shared transport instance: keeps the per-session POST registry.
sse = SseServerTransport("/messages/")


def _unwrap(result):
    """mcp 2.x Session returns tuples like (result, cursor)/(result,); normalize."""
    if isinstance(result, tuple) and result:
        return result[0]
    return result


def _tool_names(result):
    """Accept mcp Tool objects, dicts, or raw names."""
    tools = getattr(result, "tools", result)
    if not isinstance(tools, (list, tuple)):
        return tools
    names = []
    for t in tools:
        if hasattr(t, "name"):
            names.append(t.name)
        elif isinstance(t, dict) and "name" in t:
            names.append(t["name"])
        else:
            names.append(str(t))
    return names


def _text_content(result):
    """Extract readable text from an mcp CallToolResult."""
    content = getattr(result, "content", None)
    if content is None and isinstance(result, dict):
        content = result.get("content")
    text = []
    if isinstance(content, list):
        for part in content:
            if isinstance(part, dict) and "text" in part:
                text.append(part["text"])
    return "\n".join(text)


async def handle_sse(request):
    """Starlette endpoint for GET / (mirrors SDK's own SSE example)."""
    async with sse.connect_sse(request.scope, request.receive, request._send) as streams:
        read_stream, write_stream = streams[0], streams[1]
        params = StdioServerParameters(
            command=COMFY_MCP_PATH,
            args=[],
            env={**os.environ, "COMFY_LOCAL_URL": COMFY_LOCAL_URL},
        )
        async with stdio_client(params) as (client_r, client_w):
            async with ClientSession(client_r, client_w) as session:
                await session.initialize()

                async def on_list_tools(ctx, params):
                    result = _unwrap(await session.list_tools())
                    print(f"[comfy-sse] proxied comfy tools: {_tool_names(result)}", flush=True)
                    return result

                async def on_call_tool(ctx, params):
                    try:
                        if params.name == "ping":
                            return {"content": [{"type": "text", "text": "pong"}], "isError": False}
                        result = _unwrap(await session.call_tool(params.name, params.arguments or {}))
                        print(f"[comfy-sse] call_tool({params.name}) -> {_text_content(result)}", flush=True)
                        return result
                    except Exception as e:
                        return {
                            "content": [{"type": "text", "text": f"ERROR: {e}"}],
                            "isError": True,
                        }

                server = Server(
                    "comfy-sse",
                    on_list_tools=on_list_tools,
                    on_call_tool=on_call_tool,
                )
                await server.run(
                    read_stream,
                    write_stream,
                    InitializationOptions(
                        server_name="comfy-sse",
                        server_version="0.1.0",
                        capabilities={},
                    ),
                )
    return Response()


async def handle_status(request):
    return JSONResponse({
        "status": "ok",
        "transport": "sse",
        "comfy_local": COMFY_LOCAL_URL,
    })


app = Starlette(
    routes=[
        Route("/", endpoint=handle_sse, methods=["GET"]),
        Route("/sse", endpoint=handle_sse, methods=["GET"]),
        Route("/status", endpoint=handle_status, methods=["GET"]),
        Mount("/messages/", app=sse.handle_post_message),
    ],
)


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8189, log_level="info")
