// Encode source before adding presentation markup for the static renderer.
export function highlight(source) {
  const escaped = source.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  return escaped.replace(/'[^'\n]*'|##|#\||\|#|#\[|\]#|\b(?:local|return|function|if|then|for|in|do|end|integer|record|cstring|cint|byte|uint8|usize|nilptr|cexport|codename|comptime|\d+)\b/g, token => {
    const kind = token.startsWith("'") || /^\d/.test(token) ? 'literal' : 'keyword';
    return `<span class="code-${kind}">${token}</span>`;
  });
}
