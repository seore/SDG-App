import 'package:url_launcher/url_launcher.dart';

import 'api_client.dart';

/// Users younger than this need a parent's approval (must match the
/// server's CONSENT_AGE; the server has the final say).
const int consentAge = 13;

/// Youngest age someone born in [birthYear] can be – anyone who *might* be
/// under the threshold is treated as such.
int minimumAge(int birthYear, [DateTime? now]) =>
    (now ?? DateTime.now()).year - birthYear - 1;

bool needsParentalConsent(int birthYear) => minimumAge(birthYear) < consentAge;

Uri get privacyPolicyUrl => Uri.parse('${ApiClient.baseUrl}/privacy');

Future<void> openPrivacyPolicy() =>
    launchUrl(privacyPolicyUrl, mode: LaunchMode.inAppBrowserView);
