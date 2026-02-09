/// Fix audio URL by replacing 'audio-surah' with 'audio'
/// Some reciters have URLs with outdated path structure
String fixAudioUrl(String url) {
  if (url.contains('audio-surah')) {
    return url.replaceAll('audio-surah', 'audio');
  }
  return url;
}
