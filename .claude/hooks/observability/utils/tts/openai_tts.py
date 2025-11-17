#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "openai",
#     "python-dotenv",
# ]
# ///

import os
import sys
import subprocess
import tempfile
from pathlib import Path

# Add parent directory to path to import from utils
sys.path.insert(0, str(Path(__file__).parent.parent))
from constants import load_central_env

# Load central environment variables
load_central_env()


def main():
    """
    OpenAI TTS Script

    Uses OpenAI's latest TTS model for high-quality text-to-speech.
    Accepts optional text prompt as command-line argument.

    Usage:
    - ./openai_tts.py                    # Uses default text
    - ./openai_tts.py "Your custom text" # Uses provided text

    Features:
    - OpenAI gpt-4o-mini-tts model (latest)
    - Nova voice (engaging and warm)
    - File-based playback with mpv (configurable via FORCE_MPV_FOR_OPENAI)
    """

    # Get API key from environment
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        print("❌ Error: OPENAI_API_KEY not found in environment variables")
        print("Please add your OpenAI API key to .env file:")
        print("OPENAI_API_KEY=your_api_key_here")
        sys.exit(1)

    # Check if we should force mpv (for Void Linux compatibility)
    force_mpv = os.getenv("FORCE_MPV_FOR_OPENAI", "").lower() == "true"

    try:
        from openai import OpenAI

        # Initialize OpenAI client
        client = OpenAI(api_key=api_key)

        print("🎙️  OpenAI TTS")
        print("=" * 20)

        # Get text from command line argument or use default
        if len(sys.argv) > 1:
            text = " ".join(sys.argv[1:])  # Join all arguments as text
        else:
            text = "Today is a wonderful day to build something people love!"

        print(f"🎯 Text: {text}")
        print("🔊 Generating audio...")

        try:
            if force_mpv:
                # Force mpv playback (for Void/Arch/Gentoo - uses temp file)
                print("🔊 Generating audio...")
                response = client.audio.speech.create(
                    model="gpt-4o-mini-tts",
                    voice="nova",
                    input=text,
                )

                with tempfile.NamedTemporaryFile(suffix='.mp3', delete=False) as tmp_file:
                    tmp_path = tmp_file.name
                    response.stream_to_file(tmp_path)

                print("🔊 Playing audio...")
                subprocess.run(
                    ['mpv', '--no-terminal', '--really-quiet', tmp_path],
                    check=True,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )
                os.unlink(tmp_path)
            else:
                # Try LocalAudioPlayer first (Ubuntu/Debian - streaming, no temp file)
                try:
                    import asyncio
                    from openai import AsyncOpenAI

                    async def stream_audio():
                        async_client = AsyncOpenAI(api_key=api_key)
                        async with async_client.audio.speech.with_streaming_response.create(
                            model="gpt-4o-mini-tts",
                            voice="nova",
                            input=text,
                        ) as response:
                            # Try importing LocalAudioPlayer
                            try:
                                from openai.helpers import LocalAudioPlayer
                                print("🔊 Streaming audio...")
                                await LocalAudioPlayer().play(response)
                            except ImportError:
                                # LocalAudioPlayer not available, fallback to mpv
                                raise Exception("LocalAudioPlayer not available")

                    asyncio.run(stream_audio())

                except Exception:
                    # Fallback to mpv if LocalAudioPlayer fails
                    print("🔊 Generating audio (fallback to mpv)...")
                    response = client.audio.speech.create(
                        model="gpt-4o-mini-tts",
                        voice="nova",
                        input=text,
                    )

                    with tempfile.NamedTemporaryFile(suffix='.mp3', delete=False) as tmp_file:
                        tmp_path = tmp_file.name
                        response.stream_to_file(tmp_path)

                    print("🔊 Playing audio...")
                    subprocess.run(
                        ['mpv', '--no-terminal', '--really-quiet', tmp_path],
                        check=True,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL
                    )
                    os.unlink(tmp_path)

            print("✅ Playback complete!")

        except Exception as e:
            print(f"❌ Error: {e}")
            sys.exit(1)

    except ImportError as e:
        print("❌ Error: Required package not installed")
        print("This script uses UV to auto-install dependencies.")
        print("Make sure UV is installed: https://docs.astral.sh/uv/")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()