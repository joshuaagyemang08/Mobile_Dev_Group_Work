final _emailRegex = RegExp(
  r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$',
);

const _disposableDomains = <String>{
  'mailinator.com',
  'guerrillamail.com',
  '10minutemail.com',
  'temp-mail.org',
  'tempmail.com',
  'yopmail.com',
  'trashmail.com',
  'sharklasers.com',
  'getnada.com',
  'maildrop.cc',
};

const _domainTypos = <String, String>{
  'gamil.com': 'gmail.com',
  'gnail.com': 'gmail.com',
  'gmial.com': 'gmail.com',
  'hotnail.com': 'hotmail.com',
  'outlok.com': 'outlook.com',
  'yaho.com': 'yahoo.com',
};

const _commonDomains = <String>[
  'gmail.com',
  'yahoo.com',
  'outlook.com',
  'hotmail.com',
  'icloud.com',
  'live.com',
  'msn.com',
];

String? validateEmailForAuth(String? input) {
  final value = (input ?? '').trim().toLowerCase();
  if (value.isEmpty) return 'Email address is required';
  if (!_emailRegex.hasMatch(value)) return 'Enter a valid email address';

  final parts = value.split('@');
  if (parts.length != 2) return 'Enter a valid email address';

  final local = parts[0];
  final domain = parts[1];

  if (local.startsWith('.') || local.endsWith('.')) {
    return 'Enter a valid email address';
  }
  if (value.contains('..')) return 'Enter a valid email address';
  if (!domain.contains('.')) return 'Enter a valid email address';

  final tld = domain.split('.').last;
  if (tld.length < 2) return 'Enter a valid email address';

  if (_disposableDomains.contains(domain)) {
    return 'Temporary/disposable email addresses are not allowed';
  }

  final suggestion = _domainTypos[domain];
  if (suggestion != null) {
    return 'Did you mean ${local}@$suggestion ?';
  }

  final commonSuggestion = _matchCommonDomainTypo(domain);
  if (commonSuggestion != null) {
    return 'Did you mean ${local}@$commonSuggestion ?';
  }

  return null;
}

String? _matchCommonDomainTypo(String domain) {
  for (final common in _commonDomains) {
    if (_isNearMatch(domain, common)) {
      return common;
    }
  }
  return null;
}

bool _isNearMatch(String value, String target) {
  if (value == target) return false;
  if (value.length == target.length) {
    var diffCount = 0;
    var first = -1;
    var second = -1;
    for (var i = 0; i < value.length; i++) {
      if (value[i] != target[i]) {
        diffCount++;
        if (first == -1) {
          first = i;
        } else if (second == -1) {
          second = i;
        }
      }
      if (diffCount > 2) return false;
    }

    if (diffCount == 1) return true;
    if (diffCount == 2 &&
        second == first + 1 &&
        value[first] == target[second] &&
        value[second] == target[first]) {
      return true;
    }
    return false;
  }

  if ((value.length - target.length).abs() != 1) return false;

  final shorter = value.length < target.length ? value : target;
  final longer = value.length < target.length ? target : value;
  var i = 0;
  var j = 0;
  var foundDifference = false;
  while (i < shorter.length && j < longer.length) {
    if (shorter[i] != longer[j]) {
      if (foundDifference) return false;
      foundDifference = true;
      j++;
      continue;
    }
    i++;
    j++;
  }
  return true;
}
