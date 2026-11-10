// AI photo check for mission evidence, using Claude's vision.
//
// Child safety first: only the image and the mission text are sent (no name,
// account or location). Claude is told not to identify or describe people,
// and a photo only appears in the public community feed if Claude says it is
// safe to share.
import Anthropic from '@anthropic-ai/sdk';
import { betaZodOutputFormat } from '@anthropic-ai/sdk/helpers/beta/zod';
import { z } from 'zod';

const MODEL = 'claude-opus-5-5';
// Claude's per-image limit is 5 MB; the app downsizes before uploading.
const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

export const PhotoVerdictSchema = z.object({
  /** Does the photo plausibly show the mission being done? */
  matches: z.boolean(),
  confidence: z.enum(['low', 'medium', 'high']),
  /**
   * False if the photo shows a recognisable face, personal details (address,
   * school name, documents, screens with names) or anything inappropriate.
   */
  safe_to_share: z.boolean(),
  /** 1–2 encouraging sentences addressed to the young person. */
  feedback: z.string(),
});
export type PhotoVerdict = z.infer<typeof PhotoVerdictSchema>;

export interface PhotoCheckInput {
  image: Uint8Array;
  mediaType: 'image/jpeg' | 'image/png' | 'image/webp';
  missionTitle: string;
  missionDescription: string;
}

export interface PhotoChecker {
  /** Returns null when no verdict could be produced (refusal, bad output). */
  check(input: PhotoCheckInput): Promise<PhotoVerdict | null>;
}

const SYSTEM = `You review photos that young people (often aged 10–16) submit as evidence of small sustainability actions in an educational app about the UN Sustainable Development Goals.

Decide two things:
1. matches: does the photo plausibly show the mission described? Be generous – a reusable bottle on a desk counts for "use a reusable bottle"; a sorted pile of recycling counts for "sort waste". If you genuinely can't tell, say false with low confidence.
2. safe_to_share: could this photo be shown publicly to other young users? Say false if it shows a recognisable face, anyone's identity, personal details (addresses, house numbers, school names or logos, name tags, documents, screens with names or messages), or anything unsafe or inappropriate.

Privacy rules: never identify, name or describe any person, and never comment on anyone's appearance. Talk only about the action.

feedback: one or two short, warm sentences to the young person about their action. If it matches, celebrate something specific about the action. If it doesn't, encourage them kindly, without accusing them. If it isn't safe to share, add a gentle note that the photo will be kept private. No emojis.`;

function toBase64(bytes: Uint8Array): string {
  // btoa needs a binary string; build it in chunks to avoid call-stack limits.
  let binary = '';
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(binary);
}

export function createClaudePhotoChecker(apiKey: string): PhotoChecker {
  const client = new Anthropic({ apiKey, timeout: 30_000, maxRetries: 1 });

  return {
    async check({ image, mediaType, missionTitle, missionDescription }) {
      if (image.byteLength === 0 || image.byteLength > MAX_IMAGE_BYTES) return null;

      const response = await client.beta.messages.parse({
        model: MODEL,
        max_tokens: 1024,
        system: SYSTEM,
        // Simple judgement – low effort keeps it fast and inexpensive.
        output_config: {
          effort: 'low',
          format: betaZodOutputFormat(PhotoVerdictSchema),
        },
        // If a safety classifier declines, retry on Anthropic's recommended
        // fallback model instead of failing.
        betas: ['server-side-fallback-2026-07-01'],
        fallbacks: 'default',
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'image',
                source: { type: 'base64', media_type: mediaType, data: toBase64(image) },
              },
              {
                type: 'text',
                text: `Mission: ${missionTitle}\nWhat the mission asks: ${missionDescription}`,
              },
            ],
          },
        ],
      });

      // Check why it stopped before trusting the content.
      if (response.stop_reason === 'refusal' || response.stop_reason === 'max_tokens') {
        return null;
      }
      return response.parsed_output ?? null;
    },
  };
}

/** Runs a check with a hard time limit; any failure yields null. */
export async function checkWithTimeout(
  checker: PhotoChecker,
  input: PhotoCheckInput,
  ms = 25_000,
): Promise<PhotoVerdict | null> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      checker.check(input),
      new Promise<null>((resolve) => {
        timer = setTimeout(() => resolve(null), ms);
      }),
    ]);
  } catch (err) {
    if (err instanceof Anthropic.RateLimitError) {
      console.warn('Photo check rate limited');
    } else if (err instanceof Anthropic.APIError) {
      console.warn(`Photo check API error ${err.status}: ${err.message}`);
    } else {
      console.warn('Photo check failed', err);
    }
    return null;
  } finally {
    if (timer) clearTimeout(timer);
  }
}
