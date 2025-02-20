import os
import dotenv
from dotenv import load_dotenv
from mistralai import Mistral
from langchain_core.prompts import ChatPromptTemplate
from langchain_mistralai import ChatMistralAI
from pathlib import Path
load_dotenv()

api_key = os.environ["MISTRAL_API_KEY"]
model = "mistral-small-latest"
client = Mistral(api_key=api_key)

def validate_request(purpose: str):
    folder_dir = Path.cwd() / "ai_src" / "prompts"
    with open(folder_dir / "system_prompt.txt", "r", encoding="utf-8") as sp:
        system_prompt = sp.read()
    with open(folder_dir / "human_prompt.txt", "r", encoding="utf-8") as hp:
        human_prompt = hp.read()

    # Replace placeholders in the human prompt
    human_prompt = human_prompt.replace("{purpose}", purpose)

    chat_response = client.chat.complete(
        model = model,
        messages = [
            {
                "role": "system",
                "content": system_prompt
            },
            {
                "role": "user",
                "content": human_prompt,
            },
        ]
    )

    return chat_response.choices[0].message.content


def extract_decision(response):
    if "True" in response:
        return True
    elif "False" in response:
        return False
    else:
        return "No Decision"