import { Hono } from 'hono';

import type { AppEnv } from '../context';
import { consentAge } from './consent';

// DRAFT privacy policy. It describes what this codebase actually collects,
// but it is a starting point only – have it reviewed by someone qualified
// for the countries you launch in before publishing.

export const privacy = new Hono<AppEnv>();

privacy.get('/privacy', (c) => {
  const config = c.get('config');
  const contact = config.privacyContact ?? 'privacy@example.com';
  const age = consentAge(config);
  return c.html(`<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Privacy policy – SDG Journey</title>
<style>
  body{font-family:-apple-system,system-ui,sans-serif;max-width:720px;margin:0 auto;padding:24px;color:#101828;line-height:1.6}
  h1{font-size:26px} h2{font-size:18px;margin-top:28px} .muted{color:#667085;font-size:14px}
</style></head><body>
<h1>SDG Journey privacy policy</h1>
<p class="muted">Draft – last updated ${new Date().toISOString().slice(0, 10)}</p>

<p>SDG Journey helps young people learn about the UN Sustainable Development Goals through small daily actions, lessons and games. We collect as little as we can, never show adverts, and never sell personal data.</p>

<h2>What we collect</h2>
<ul>
  <li><strong>Account:</strong> email address, username, a hashed password, and birth year (to check whether a parent needs to give permission).</li>
  <li><strong>Activity:</strong> missions completed, XP, streaks, quiz and game scores, focus goals and team memberships.</li>
  <li><strong>Optional location:</strong> when you complete a mission, an approximate location for the community map. Others only ever see it rounded to about 1&nbsp;km.</li>
  <li><strong>Optional photos:</strong> photos you add to missions. They are checked automatically (see below) and only shown to others if they contain no faces or personal details.</li>
  <li><strong>Parent's email</strong> for users under ${age}, used only to ask for and record permission.</li>
</ul>

<h2>How we use it</h2>
<ul>
  <li>To run the app: your progress, daily missions, team challenges and impact totals.</li>
  <li>To show other users anonymous-by-default community information: usernames, completed missions, rounded map locations and checked photos.</li>
  <li>To send emails you or your parent ask for (password reset, parental consent).</li>
</ul>

<h2>Photo checks</h2>
<p>If enabled, mission photos are sent to Anthropic's Claude AI service to check that they show the mission and contain no faces or personal details. Only the photo and the mission's description are sent – not your name, email or location.</p>

<h2>Children</h2>
<p>If you tell us you are under ${age}, we ask a parent or guardian for permission before you can share anything with other users. Until they agree, you can learn and play privately: no stories, photos, map location or teams. A parent can decline, which deletes the account.</p>

<h2>Who we share data with</h2>
<p>Only the services that run the app: our database host (Neon), our API host (Cloudflare), photo storage, our email provider and the AI photo check. They process data on our behalf and may not use it for anything else.</p>

<h2>How long we keep it</h2>
<p>Until you delete your account. Deleting it (Profile → Delete account) removes your profile, activity, stories, photos and team memberships.</p>

<h2>Your rights</h2>
<p>You can see, correct, download or delete your data. Contact us at <a href="mailto:${contact}">${contact}</a> and we will reply within 30 days. Parents can contact us about their child's account at the same address.</p>
</body></html>`);
});
