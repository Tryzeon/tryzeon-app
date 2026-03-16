import { CONFIG } from "../_shared/supabase.ts";

const DEFAULT_VIDEO_PROMPT =
  "The person is wearing the new outfit and turning slightly to show the fit of the clothing. Natural movement, professional fashion video style.";

function buildVideoPrompt(transitionPrompt?: string): string {
  if (!transitionPrompt) {
    return DEFAULT_VIDEO_PROMPT;
  }

  let prompt = "The person is wearing the new outfit and showing the fit of the clothing.";

  if (transitionPrompt) {
    prompt += ` Camera and transition style: ${transitionPrompt}.`;
  }

  prompt += " Natural movement, professional fashion video style.";
  return prompt;
}

const MAX_POLL_ATTEMPTS = 60;
const POLL_INTERVAL_MS = 2000;

function getVertexEndpoint(model: string, action: "predictLongRunning" | "fetchPredictOperation"): string {
  const location = CONFIG.GOOGLE_CLOUD_LOCATION;
  const projectId = CONFIG.GOOGLE_CLOUD_PROJECT_ID;
  return `https://${location}-aiplatform.googleapis.com/v1/projects/${projectId}/locations/${location}/publishers/google/models/${model}:${action}`;
}

async function startVideoGeneration(
  tryonImageBase64: string,
  transitionPrompt?: string,
): Promise<string> {
  const prompt = buildVideoPrompt(transitionPrompt);
  const model = CONFIG.VERTEX_VIDEO_MODEL;
  const endpoint = getVertexEndpoint(model, "predictLongRunning");

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
      generateAudio: true,
    },
  };

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "x-goog-api-key": CONFIG.GOOGLE_CLOUD_API_KEY,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error("Failed to start video generation:", errorText);
    throw new Error(`Failed to start video generation: ${response.status} ${errorText}`);
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
    headers: {
      "x-goog-api-key": CONFIG.GOOGLE_CLOUD_API_KEY,
    },
  });

  if (!videoResponse.ok) {
    const errorText = await videoResponse.text();
    console.error("Failed to download video:", errorText);
    throw new Error(`Failed to download video: ${videoResponse.status}`);
  }

  const videoBuffer = await videoResponse.arrayBuffer();
  return btoa(Array.from(new Uint8Array(videoBuffer), (b) => String.fromCharCode(b)).join(""));
}

async function pollForCompletion(operationName: string): Promise<string> {
  let attempts = 0;
  const pollUrl = getVertexEndpoint(CONFIG.VERTEX_VIDEO_MODEL, "fetchPredictOperation");

  while (attempts < MAX_POLL_ATTEMPTS) {
    await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS));
    attempts++;

    const pollResponse = await fetch(pollUrl, {
      method: "POST",
      headers: {
        "x-goog-api-key": CONFIG.GOOGLE_CLOUD_API_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        operationName: operationName,
      }),
    });

    if (!pollResponse.ok) {
      const errorText = await pollResponse.text();
      console.error(`Poll attempt ${attempts} failed:`, errorText);
      continue;
    }

    const pollData = await pollResponse.json();

    if (!pollData.done) continue;

    if (pollData.error) {
      console.error("Video generation failed:", pollData.error);
      throw new Error(`Video generation failed: ${JSON.stringify(pollData.error)}`);
    }

    const videos = pollData.response?.videos;
    if (!videos || videos.length === 0) {
      console.error("No videos in completed response:", pollData);
      throw new Error("No videos in response");
    }

    const videoUri = videos[0].gcsUri;
    if (!videoUri) {
      console.error("No video URI in response:", pollData);
      throw new Error("No video URI in response");
    }

    return downloadVideo(videoUri);
  }

  throw new Error("Video generation timeout");
}

export async function generateTryonVideo(
  tryonImageBase64: string,
  transitionPrompt?: string,
): Promise<string> {
  const operationName = await startVideoGeneration(tryonImageBase64, transitionPrompt);
  const videoBase64 = await pollForCompletion(operationName);
  
  return videoBase64;
}
