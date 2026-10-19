import { initAndLogin } from "./liff";
import { ensureSession } from "./auth";
import { type AvatarProfile, fetchAvatarProfile } from "../api/profile";
import { BootstrapError, type BootstrapStep } from "./bootstrap-error";

async function step<T>(name: BootstrapStep, run: () => Promise<T>): Promise<T> {
  try {
    return await run();
  } catch (err) {
    throw new BootstrapError(name, err);
  }
}

export async function bootstrap(): Promise<AvatarProfile> {
  await step("liff", initAndLogin);
  const userId = await step("session", ensureSession);
  return step("profile", () => fetchAvatarProfile(userId));
}
