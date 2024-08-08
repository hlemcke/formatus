

class TextHelper {
  ///
  /// Splits `name` into parts separated by space.
  /// Build initials from first letters of each part (up to 3).
  ///
  static String extractInitials(String name) {
    name = name.trim();
    List<String> parts = name.split(' ');
    String initials =
    name.isEmpty ? '?' : parts[0].substring(0, 1).toUpperCase();
    if (parts.length > 1) {
      initials += parts[1].substring(0, 1).toUpperCase();
    }
    if (parts.length > 2) {
      initials += parts[2].substring(0, 1).toUpperCase();
    }
    return initials;
  }

  static String extractWord(String text, int offset) {
    RegExp regExp = RegExp(r'[a-zA-Z0-9]');
    int index = offset;
    while (index < text.length) {
      if (!text[index].contains(regExp)) break;
      index++;
    }
    return text.substring(offset, index);
  }

  ///
  /// Finds an enumeration item either by its name or by its key
  ///
  static dynamic findEnum(
      String? text,
      List<dynamic> values, {
        dynamic defaultValue,
        bool withKey = true,
      }) {
    if (text != null) {
      if (withKey) {
        for (dynamic enumItem in values) {
          if (enumItem.key == text) {
            return enumItem;
          }
        }
      }
      if (!text.contains('.')) {
        String name = values[0].toString();
        name = name.substring(0, name.indexOf('.'));
        text = '$name.$text';
      }
      text = text.toLowerCase();
      for (dynamic enumItem in values) {
        if (enumItem.toString().toLowerCase() == text) {
          return enumItem;
        }
      }
    }
    return defaultValue;
  }

  /// Replaces path parameters in `restPath` like ".../{key}"
  /// with value from map and removes the entry from map.
  static String replacePathParams(
      String restPath, Map<String, String> httpParams) {
    int i = -1;
    while ((i = restPath.indexOf('/{')) > 0) {
      int j = restPath.indexOf('}', i);
      String key = restPath.substring(i + 2, j);
      String suffix = (j < restPath.length) ? restPath.substring(j + 1) : '';
      restPath = '${restPath.substring(0, i)}/${httpParams[key]}$suffix';
      httpParams.remove(key);
    }
    return restPath;
  }
}
