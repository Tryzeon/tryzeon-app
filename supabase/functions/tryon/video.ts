// default model: veo-3.1-fast-generate-preview
import { VERTEX_CONFIG } from "../_shared/vertex-ai.ts";
import { uploadVideoToR2 } from "../_shared/r2.ts";

const DEFAULT_VIDEO_PROMPT =
  "The person is wearing the new outfit and turning slightly to show the fit of the clothing. Natural movement, professional fashion video style.";

function buildVideoPrompt(transitionPrompt?: string): string {
  if (!transitionPrompt) {
    return DEFAULT_VIDEO_PROMPT;
  }

  let prompt = "The person is wearing the new outfit and showing the fit of the clothing.";
  prompt += ` Camera and transition style: ${transitionPrompt}.`;
  prompt += " Natural movement, professional fashion video style.";

  return prompt;
}

const MAX_POLL_ATTEMPTS = 25; 
const POLL_INTERVAL_MS = 2000;

async function startVideoGeneration(
  tryonImageBase64: string,
  transitionPrompt?: string,
): Promise<string> {
  const prompt = buildVideoPrompt(transitionPrompt);
  const requestBody = {
    instances: [{
      prompt,
      image: {
        bytesBase64Encoded: tryonImageBase64,
        mimeType: "image/png",
      },
    }],
    parameters: {
      aspectRatio: "9:16",
      durationSeconds: 8,
    },
  };

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${VERTEX_CONFIG.VIDEO_MODEL}:predictLongRunning`,
    {
      method: "POST",
      headers: {
        "x-goog-api-key": VERTEX_CONFIG.API_KEY!,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestBody),
    },
  );

  if (!response.ok) {
    const errorText = await response.text();
    console.error("Failed to start video generation. Status:", response.status, "Body:", errorText);
    throw new Error(`Failed to start video generation: ${response.statusText} - ${errorText}`);
  }

  const data = await response.json();
  if (!data.name) {
    console.error("No operation name returned:", data);
    throw new Error("Invalid response from video API");
  }

  return data.name;
}

async function downloadVideo(videoUri: string): Promise<string> {
  const videoResponse = await fetch(videoUri, {
    headers: { "x-goog-api-key": VERTEX_CONFIG.API_KEY! },
  });

  if (!videoResponse.ok) {
    console.error("Failed to download video. Status:", videoResponse.status);
    throw new Error("Failed to download video");
  }

  const videoBuffer = await videoResponse.arrayBuffer();

  // Generate a unique filename using crypto.randomUUID()
  const fileName = `videos/${crypto.randomUUID()}.mp4`;

  // Upload to R2 and get signed URL
  const videoUrl = await uploadVideoToR2(videoBuffer, fileName);
  return videoUrl;
}

async function pollForCompletion(operationName: string): Promise<string> {
  let attempts = 0;

  while (attempts < MAX_POLL_ATTEMPTS) {
    await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS));
    attempts++;

    const pollResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/${operationName}`,
      { headers: { "x-goog-api-key": VERTEX_CONFIG.API_KEY! } },
    );

    if (!pollResponse.ok) {
      console.error("Failed to poll operation. Status:", pollResponse.status);
      continue;
    }

    const pollData = await pollResponse.json();

    if (!pollData.done) continue;

    if (pollData.error) {
      console.error("Video generation failed:", pollData.error);
      throw new Error("Video generation failed");
    }

    const videoUri = pollData.response?.generateVideoResponse?.generatedSamples?.[0]?.video?.uri;
    if (!videoUri) {
      console.error("No video URL in completed response:", pollData);
      throw new Error("No video URL in response");
    }

    return downloadVideo(videoUri);
  }

  throw new Error("Video generation timeout - polling limit reached");
}

export async function generateTryonVideo(
  tryonImageBase64: string,
  transitionPrompt?: string,
): Promise<string> {
  const operationName = await startVideoGeneration(tryonImageBase64, transitionPrompt);
  return pollForCompletion(operationName);
}
