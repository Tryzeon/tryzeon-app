import { S3Client, PutObjectCommand, GetObjectCommand } from "npm:@aws-sdk/client-s3";
import { getSignedUrl } from "npm:@aws-sdk/s3-request-presigner";

let _r2Client: S3Client | null = null;

const SIGNED_URL_EXPIRY_SECONDS = 604800; // 7 days

const validateR2Env = () => {
  const requiredVars = [
    "R2_ACCESS_KEY_ID",
    "R2_SECRET_ACCESS_KEY",
    "R2_ENDPOINT",
    "R2_TRYON_VIDEOS_BUCKET_NAME",
    "R2_TRYON_IMAGES_BUCKET_NAME",
  ];

  for (const envVar of requiredVars) {
    if (!Deno.env.get(envVar)) {
      throw new Error(`Missing required environment variable: ${envVar}`);
    }
  }
};

export const getR2Client = () => {
  if (!_r2Client) {
    validateR2Env();
    _r2Client = new S3Client({
      region: "auto",
      endpoint: Deno.env.get("R2_ENDPOINT")!,
      credentials: {
        accessKeyId: Deno.env.get("R2_ACCESS_KEY_ID")!,
        secretAccessKey: Deno.env.get("R2_SECRET_ACCESS_KEY")!,
      },
    });
  }
  return _r2Client;
};

async function uploadToR2(
  bucket: string,
  key: string,
  body: Uint8Array,
  contentType: string,
): Promise<string> {
  const s3Client = getR2Client();

  const putCommand = new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    Body: body,
    ContentType: contentType,
  });

  await s3Client.send(putCommand);

  const getCommand = new GetObjectCommand({
    Bucket: bucket,
    Key: key,
  });

  return await getSignedUrl(s3Client, getCommand, {
    expiresIn: SIGNED_URL_EXPIRY_SECONDS,
  });
}

export async function uploadVideoToR2(buffer: ArrayBuffer, fileName: string): Promise<string> {
  const bucketName = Deno.env.get("R2_TRYON_IMAGES_BUCKET_NAME")!;
  return await uploadToR2(bucketName, fileName, new Uint8Array(buffer), "video/mp4");
}

export async function uploadImageToR2(
  buffer: ArrayBuffer,
  fileName: string,
  contentType: string,
): Promise<string> {
  const bucketName = Deno.env.get("R2_TRYON_IMAGES_BUCKET_NAME")!;
  return await uploadToR2(bucketName, fileName, new Uint8Array(buffer), contentType);
}
