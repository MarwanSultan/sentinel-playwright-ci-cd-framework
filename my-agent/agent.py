import os

from managed_deepagents import define_deep_agent
from langchain_openai import ChatOpenAI

# LangSmith Gateway serves this model on your workspace's Gateway Credits, so
# the agent needs no model provider key of its own — only a LangSmith one.
#
# The key is read from LANGSMITH_GATEWAY_API_KEY rather than LANGSMITH_API_KEY:
# the latter is reserved by the platform, so `mda deploy` never forwards it, and
# the one a deployment is issued cannot reach the gateway. Put your own
# LangSmith API key under both names in `.env`.
api_key = os.environ.get(
    "LANGSMITH_GATEWAY_API_KEY",
    "missing-langsmith-gateway-api-key",
)

# The gateway speaks the OpenAI API, which is why an OpenAI client addresses it.
base_url = "https://gateway.smith.langchain.com/v1"

agent = define_deep_agent(
    name="my-agent",
    model=ChatOpenAI(
        model="moonshotai/Kimi-K3",
        api_key=api_key,
        base_url=base_url,
    ),
)
