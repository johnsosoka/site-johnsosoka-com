---
layout: post
title: "Using LangChain to Build Custom Tools for LLMs: A Themed Spotify Playlist Generator"
category: blog
tags: LangChain AI chatGPT custom tools spotify spotipy themed playlist generator
---

Large Language Models (LLMs) have showcased an incredible capacity for tool usage. ChatGPT does a great job of formatting
responses to fit a spec if you define it. For example, we can politely ask chatGPT to format its response as a json string,
which makes it very easy to toggle back-and-fourth between legacy programming and prompt engineering. We can do this 
from scratch, but a library exists that handles much of this under the hood-- [LangChain](https://docs.langchain.com/docs/),
which "is a framework for developing applications powered by language models."

## Today's Project

Today we will be exploring LangChain and building custom tools for an LLM to consume. Ultimately our program will utilize
AI to generate a themed Spotify playlist. I've opted to use the [spotipy](https://spotipy.readthedocs.io/) library to 
interact with the Spotify API. The general flow will be as follows:

1. We provide a theme to chatGPT, "Songs about Mountains" or "Songs about Idaho"
2. chatGPT will use an existing LangChain tool `google-search` to find a list of songs that match the theme.
3. The LLM will need to use custom tools that we create to interact with spotify to find songs and add them to a playlist.

**Note:** This article will focus on the interesting parts of the project. The full code can be found on [github](https://github.com/johnsosoka/playlist-generator)

## Custom Tools

Let's begin by constructing our custom tools. LangChain provides an interface `BaseTool` that we can implement to start
building custom tools. In particular, we will need to implement the `_run` method. This method will be "called" by the LLM
when it opts to use the tool. The `_run` method will be passed the input parameters defined in the `args_schema` as well.

I'm placing "called" in quotes because in reality, the LangChain framework will be parsing the response from the LLM and
determining if the response is a tool command. If it is, the framework will parse the command and hand it off to the 
custom tool.

### Find Song Tool

The spotipy client will be using credentials that are set as an environment variable, so do not be alarmed with the lack
of credentials in the following code.

Within `find_song_tool.py` I'll begin by defining the scope for the spotify client and defining the input for the FindSongTool.

```python
import spotipy
from langchain.tools import BaseTool
from typing import Optional, Type

from pydantic import BaseModel, Field

from langchain.callbacks.manager import (
    AsyncCallbackManagerForToolRun,
    CallbackManagerForToolRun,
)
from spotipy.oauth2 import SpotifyOAuth

scope = "user-library-read playlist-modify-public playlist-modify-private"
spotify = spotipy.Spotify(auth_manager=SpotifyOAuth(scope=scope))

class FindSongInput(BaseModel):
   """Input for WriteFileTool."""

   artist: str = Field(..., description="name of artist/band")
   title: str = Field(..., description="The title of the song")
```

The `FindSongInput` class is ultimately used to tell the LLM _how_ to interact with the tool. It defines two input
parameters, `artist` and `title` which will need to be provided in order to search for a song via the spotify API.

```python
class FindSongTool(BaseTool):
    """Tool that finds a song on Spotify."""

    name: str = "find_song"
    args_schema: Type[BaseModel] = FindSongInput
    description: str = "Finds a song on Spotify. Returns the Spotify URI if found."

    def _run(
            self,
            artist: str,
            title: str,
            run_manager: Optional[CallbackManagerForToolRun] = None,
    ) -> str:
        results = spotify.search(q=f"track:{title} artist:{artist}", type="track")

        if results["tracks"]["items"]:
            top_result_item = results["tracks"]["items"][0]
            return top_result_item["uri"]
        else:
            # Handle the case where the search didn't return any results
            message = f"No results found for track:{title} artist:{artist}"
            return message

    async def _arun(
            self,
            file_path: str,
            text: str,
            append: bool = False,
            run_manager: Optional[AsyncCallbackManagerForToolRun] = None,
    ) -> str:
        raise NotImplementedError
```

Note than in the above our args_schema is defined as `FindSongInput`. This is a pydantic model that defines the input. 
Additionally, the `_run` method has input parameters which match the argsSchema. If chatGPT opts to utilize this tool,
the `_run` method will be called with the input parameters. In the spirit of keeping this exploration simple, I have
opted not to implement the async run method.

### Add Song Tool

The `AddSongTool` is very similar to the `FindSongTool` in that it will be interacting with the spotify API. 

```python
import spotipy
from langchain.tools import BaseTool
from typing import Optional, Type

from pydantic import BaseModel, Field

from langchain.callbacks.manager import (
    AsyncCallbackManagerForToolRun,
    CallbackManagerForToolRun,
)
from spotipy.oauth2 import SpotifyOAuth

scope = "user-library-read playlist-modify-public playlist-modify-private"
spotify = spotipy.Spotify(auth_manager=SpotifyOAuth(scope=scope))


class AddSongInput(BaseModel):
    """Input for WriteFileTool."""

    uri: str = Field(..., description="the uri of the song to add")
    playlist_id: str = Field(..., description="the id of the playlist to add the song to")


class AddSongTool(BaseTool):
    """Tool that adds a song to a spotify playlist. for a given URI."""

    name: str = "add_song"
    args_schema: Type[BaseModel] = AddSongInput
    description: str = "Adds a song to a spotify playlist for a given URI."

    def _run(
            self,
            uri: str,
            playlist_id: str,
            run_manager: Optional[CallbackManagerForToolRun] = None,
    ) -> str:

        try:
            spotify.playlist_add_items(playlist_id, [uri])
            return f"Song added successfully to playlist."
        except Exception as e:
            print(str(e))
            return "Unable to add song to playlist. Error: "

    async def _arun(
            self,
            file_path: str,
            text: str,
            append: bool = False,
            run_manager: Optional[AsyncCallbackManagerForToolRun] = None,
    ) -> str:
        raise NotImplementedError
```

We follow the same pattern as the `FindSongTool` in that we define the input parameters in the `args_schema` and implement
the `BaseTool` methods.

For the sake of Brevity, I will skip the `PlaylistContent` tool. It is almost identical to the others, except it returns 
the contents of a spotify playlist--This is to _help_ reduce the chances of adding duplicate songs to the playlist.

## Tie it All Together

Now that we have our custom tools created, we will need to wire everything together and hand them off to an LLM. 

The first potion of the `playlist_generator.py` handles the setup:

```python
from langchain import PromptTemplate
from langchain.vectorstores import FAISS
from langchain.docstore import InMemoryDocstore
from langchain.embeddings import OpenAIEmbeddings
import faiss
from config.config_loader import ConfigLoader
from langchain_experimental.autonomous_agents import AutoGPT
from langchain.chat_models import ChatOpenAI
from langchain.agents import load_tools

# Define your embedding model
embeddings_model = OpenAIEmbeddings()
# Initialize the vectorstore as empty
embedding_size = 1536
index = faiss.IndexFlatL2(embedding_size)
vectorstore = FAISS(embeddings_model.embed_query, index, InMemoryDocstore({}), {})

# configure
config_loader = ConfigLoader("config.yml")
config_loader.set_environment_variables()
config = config_loader.load_config()

from src.tools.add_song_tool import AddSongTool
from src.tools.playlist_content_tool import PlaylistContentsTool
from tools.find_song_tool import FindSongTool
```

This first portion is a little awkward. Since I opted to use environment variables for spotipy, I need to set them
_before_ importing the custom tools which utilize Spotipy. This is why the tools are imported after my ConfigLoader
sets the environment variables.

Next up, we will define the Agent, Tools & Prompt:

```python
tools = load_tools(["google-search"])
tools += [
    FindSongTool(),
    AddSongTool(),
    PlaylistContentsTool()
]

agent = AutoGPT.from_llm_and_tools(
    ai_name="Tom",
    ai_role="Assistant",
    tools=tools,
    llm=ChatOpenAI(temperature=0),
    memory=vectorstore.as_retriever(),
)
# Set verbose to be true
agent.chain.verbose = True

task_template = """
Your task is to build a themed spotify playlist. The playlist must not contain any duplicate songs. To add
a song to a spotify playlist, you must identify the URI.

1. Identify songs that fit the theme: '{song_theme}' using existing knowledge and internet search.
2. Find the URI for the song on spotify.
3. Check the playlist contents to ensure that the song is not already in the playlist. If the song is already in the playlist DO NOT ADD IT. Find another song.
4. Add the song to playlist id {playlist_id}

Your task is complete when the playlist has {num_items} songs in it.

Remember that it is essential that only unique songs are added to the playlist. Check the playlist contents before adding a song
to ensure that it is not already in the playlist. If the song is already in the playlist and you add it again, you will be penalized.
"""

prompt = PromptTemplate.from_template(task_template)
```

The above will hand off the 4 tools we defined to the `AutoGPT` agent. Additionally, we define a prompt template with 
placeholder values for the song theme, playlist id and number of items.

Finally, we will define our variables, populate the prompt template and run the agent:

```python
prompt = PromptTemplate.from_template(task_template)


playlist_id = "0ylrX64UMWUwS1gjrDY2UO"
topic = "songs about mountains"
target_playlist_size = 5


agent.run([prompt.format(song_theme=topic, playlist_id=playlist_id, num_items=target_playlist_size)])
```

Yes the playlist ID and topic are hard coded. This is just a proof of concept. In a real world application, these would
be collected from user input or a config. 

## Execute

Now that we have everything wired up, we can execute the script and see what happens. I will only include a snippet of the
original message provided to the bot. This should really demonstrate how the custom tools are handed off and utilized
by the Agent.

```bash
Prompt after formatting:
System: You are Tom, Assistant
Your decisions must always be made independently without seeking user assistance.
Play to your strengths as an LLM and pursue simple strategies with no legal complications.
If you have completed all your tasks, make sure to use the "finish" command.

GOALS:

1. 
Your task is to build a themed spotify playlist. The playlist must not contain any duplicate songs. To add
a song to a spotify playlist, you must identify the URI.

1. Identify songs that fit the theme: 'songs about mountains' using existing knowledge and internet search.
2. Find the URI for the song on spotify.
3. Check the playlist contents to ensure that the song is not already in the playlist. If the song is already in the playlist DO NOT ADD IT. Find another song.
4. Add the song to playlist id 0ylrX64UMWUwS1gjrDY2UO

Your task is complete when the playlist has 5 songs in it.

Remember that it is essential that only unique songs are added to the playlist. Check the playlist contents before adding a song
to ensure that it is not already in the playlist. If the song is already in the playlist and you add it again, you will be penalized.



Constraints:
1. ~4000 word limit for short term memory. Your short term memory is short, so immediately save important information to files.
2. If you are unsure how you previously did something or want to recall past events, thinking about similar events will help you remember.
3. No user assistance
4. Exclusively use the commands listed in double quotes e.g. "command name"

Commands:
1. google_search: A wrapper around Google Search. Useful for when you need to answer questions about current events. Input should be a search query., args json schema: {"query": {"title": "Query", "type": "string"}}
2. find_song: Finds a song on Spotify. Returns the Spotify URI if found., args json schema: {"artist": {"title": "Artist", "description": "name of artist/band", "type": "string"}, "title": {"title": "Title", "description": "The title of the song", "type": "string"}}
3. add_song: Adds a song to a spotify playlist for a given URI., args json schema: {"uri": {"title": "Uri", "description": "the uri of the song to add", "type": "string"}, "playlist_id": {"title": "Playlist Id", "description": "the id of the playlist to add the song to", "type": "string"}}
4. get_spotify_playlist_contents: Returns the songs of a spotify playlist for a given playlist ID., args json schema: {"playlist_id": {"title": "Playlist Id", "description": "the id of the playlist to get contents from", "type": "string"}}
5. finish: use this to signal that you have finished all your objectives, args: "response": "final response to let people know you have finished your objectives"

Resources:
1. Internet access for searches and information gathering.
2. Long Term memory management.
3. GPT-3.5 powered Agents for delegation of simple tasks.
4. File output.

Performance Evaluation:
1. Continuously review and analyze your actions to ensure you are performing to the best of your abilities.
2. Constructively self-criticize your big-picture behavior constantly.
3. Reflect on past decisions and strategies to refine your approach.
4. Every command has a cost, so be smart and efficient. Aim to complete tasks in the least number of steps.

You should only respond in JSON format as described below 
Response Format: 
{
    "thoughts": {
        "text": "thought",
        "reasoning": "reasoning",
        "plan": "- short bulleted\n- list that conveys\n- long-term plan",
        "criticism": "constructive self-criticism",
        "speak": "thoughts summary to say to user"
    },
    "command": {
        "name": "command name",
        "args": {
            "arg name": "value"
        }
    }
} 
Ensure the response can be parsed by Python json.loads
System: The current time and date is Tue Aug  8 15:12:54 2023
System: This reminds you of these events from your past:
[]


Human: Determine which next command to use, and respond using the format specified above:
```

The LangChain Framework takes all the component pieces we set up and presents them to the LLM with a conversational tone.
LangChain is also capable of parsing the responses, and executing the commands.

Below is a snippet of the Agent choosing to use the `google_search` tool to find songs about mountains:

```bash
AI: {
    "thoughts": {
        "text": "I need to start by searching for songs about mountains. Once I find a song, I can check if it's already in the playlist and add it if it's not. I should repeat this process until the playlist has 5 unique songs.",
        "reasoning": "I need to search for songs about mountains because that's the theme of the playlist. Checking if a song is already in the playlist will ensure that I don't add duplicates. Adding songs until the playlist has 5 unique songs will fulfill the objective.",
        "plan": "- Search for songs about mountains\n- Check if the song is already in the playlist\n- If not, add the song to the playlist\n- Repeat until the playlist has 5 unique songs",
        "criticism": "I need to be careful not to add duplicate songs to the playlist. It's important to check the playlist contents before adding a song.",
        "speak": "I will start by searching for songs about mountains and add them to the playlist if they are not already there."
    },
    "command": {
        "name": "google_search",
        "args": {
            "query": "songs about mountains"
        }
    }
}
System: Command google_search returned: Mar 14, 2023 ... Ain't No Mountain High Enough – Marvin Gaye & Tammi Terrell ... First on our list is the classic 1967 song Ain't No Mountain High Enough by Marvin ... Feb 26, 2023 ... 25 Best Songs about Mountains to Lift You Up · You Gave Me a Mountain – Elvis Presley · Misty Mountain Hop – Led Zeppelin · Rocky Mountain High – ... 5. “The Mountains Win Again” By Blues Traveler ... Jul 24, 2023 ... 27 Best Songs About Mountains (In The Title & Lyrics) · “Ain't No Mountain High Enough” by Marvin Gaye & Tammi Terrell · “Mountain Sound” by Of ... The Mountain - 50 Great Songs About Mountains ; 1. Blue Ridge Mountain Song. Alan Jackson ; 2. Mountains Of Sorrow. Amos Lee ; 3. Bluebirds Over The Mountain - ... Jul 9, 2022 ... 20 Songs About Mountains (Music Video + Lyrics!) · 1. Rocky Mountain High by John Denver · 2. Half Moon Rising by Yonder Mountain String Band · 3. This playlist is jam-packed with songs about mountains that will leave you wanting to visit the various mountain ranges across America. Upcoming show tapings for Song of the Mountains. ... Song of the Mountains® showcases the best talents in Bluegrass, ... Songs From the Road Band. ARCHIVED ... Feb 28, 2023 ... You Gave Me a Mountain – Elvis Presley ... “You Gave Me a Mountain” is a powerful and emotional ballad sung by Elvis Presley. The song was ... Nov 13, 2019 ... Travelling To The Mountains And Don't Have A Playlist? We Have You Covered · Train Song, Gully boy. This upbeat song is the perfect start to your ...
Human: Determine which next command to use, and respond using the format specified above:
```

## Wrapping Up

Harnessing the capabilities of Large Language Models (LLMs) like ChatGPT, combined with the power of LangChain, opens up 
a world of possibilities for developers. In this exploration, we've seen how to integrate LLMs with existing APIs via custom
tools. LangChain makes it incredibly easy to create custom tools and hand them off to Agents. The future of AI-driven
applications looks promising, and with Frameworks like LangChain at our disposal, the sky's the limit. 

Happy Coding!

_**Further Reading:**_

These past few weeks I have been exploring ways to interact with, and customize chatGPT. My most 
recent blog post was on using custom data with chatGPT, which you can [read here](/blog/2023/07/12/custom-gpt-data.html).

