/**
 * Built on first use and kept for the isolate, deliberately not at import:
 * `chat/run.ts` names its Vertex runner as the default, so anything touching
 * the chat core pulls this module in — including callers that always inject
 * their own runner, and tests that never reach the network. Building at import
 * would make Vertex credentials a requirement for all of them.
 */
import { createVertex } from "@ai-sdk/google-vertex/edge";
import { type LanguageModel, wrapLanguageModel } from "ai";
import { compactingFetch } from "./compact-body.ts";
import { vertexLocation, vertexServiceAccount } from "./config.ts";
import { isBusy } from "./errors.ts";

let provider: ReturnType<typeof createVertex> | null = null;

/**
 * The provider itself. The edge variant signs the service-account JWT via Web
 * Crypto, so project and location must be named — unlike express mode, where
 * the key implied both. Its `fetch` resolves the global per request rather
 * than capturing it here, which is what lets a test observe the call.
 */
function vertexProvider() {
  if (provider) return provider;

  const { projectId, ...googleCredentials } = vertexServiceAccount();
  return provider = createVertex({
    project: projectId,
    location: vertexLocation(),
    googleCredentials,
    fetch: compactingFetch,
  });
}

function announce(modelId: string) {
  console.info(`vertex: model=${modelId} region=${vertexLocation()}`);
}

export function vertexModel(modelId: string) {
  announce(modelId);
  return vertexProvider()(modelId);
}

/**
 * Vertex meters image generation per model, so a model refused for quota can
 * be served at once by the next one in the list. The sweep lives in middleware
 * so that it runs inside the SDK's retry loop: a sweep that finds every model
 * spent rethrows the last refusal untranslated, the loop backs off as it would
 * for a single model, and the next attempt sweeps again. Each model is logged
 * with its verdict, since which one served is only known after the fact.
 */
export function vertexModelSweep(modelIds: string[]): LanguageModel {
  if (modelIds.length === 1) return vertexModel(modelIds[0]);

  const region = vertexLocation();
  const models = modelIds.map((modelId) => ({
    modelId,
    model: vertexProvider()(modelId),
  }));

  return wrapLanguageModel({
    model: models[0].model,
    middleware: {
      specificationVersion: "v3",
      wrapGenerate: async ({ params }) => {
        let refusal: unknown;
        for (const { modelId, model } of models) {
          try {
            const result = await model.doGenerate(params);
            console.info(`vertex: model=${modelId} region=${region} served`);
            return result;
          } catch (err) {
            if (!isBusy(err)) throw err;
            console.warn(
              `vertex: model=${modelId} region=${region} refused for capacity`,
            );
            refusal = err;
          }
        }
        throw refusal;
      },
    },
  });
}

export function vertexVideoModel(modelId: string) {
  announce(modelId);
  return vertexProvider().videoModel(modelId);
}

export function vertexInteractionsModel(modelId: string) {
  announce(modelId);
  return vertexProvider().interactions(modelId);
}
