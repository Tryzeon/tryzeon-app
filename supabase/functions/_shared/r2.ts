import { S3Client, PutObjectCommand, GetObjectCommand } from "npm:@aws-sdk/client-s3";
import { getSignedUrl } from "npm:@aws-sdk/s3-request-presigner";

let _r2Client: S3Client | null = null;

const validateR2Env = () => {
  const requiredVars = [
    "R2_ACCESS_KEY_ID",
    "R2_SECRET_ACCESS_KEY",
    "R2_ENDPOINT",
    "R2_VIDEOS_BUCKET_NAME",
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

export async function uploadVideoToR2(buffer: ArrayBuffer, fileName: string): Promise<string> {
  const s3Client = getR2Client();
  const bucketName = Deno.env.get("R2_VIDEOS_BUCKET_NAME")!;

  const putCommand = new PutObjectCommand({
    Bucket: bucketName,
    Key: fileName,
    Body: new Uint8Array(buffer),
    ContentType: "video/mp4",
  });

  await s3Client.send(putCommand);

  const getCommand = new GetObjectCommand({
    Bucket: bucketName,
    Key: fileName,
  });

  // Generate a presigned URL valid for 7 days (604800 seconds)
  const signedUrl = await getSignedUrl(s3Client, getCommand, { expiresIn: 604800 });
  return signedUrl;
}
