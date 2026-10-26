// Routes only /lang/nelua/* on spacegho.st to the public Sites deployment.
const SITE = "https://nelua-language.spaceghostc2c.chatgpt.site";
const PREFIX = "/langs/nelua";

addEventListener("fetch", (event) => {
  event.respondWith(route(event.request));
});

async function route(request) {
  const incoming = new URL(request.url);
  if (incoming.pathname === PREFIX || incoming.pathname === PREFIX + "/nelibc") {
    incoming.pathname += "/";
    return Response.redirect(incoming.toString(), 308);
  }
  if (incoming.pathname !== PREFIX + "/" && !incoming.pathname.startsWith(PREFIX + "/")) {
    return new Response("Not found", { status: 404 });
  }

  const upstream = new URL(SITE);
  upstream.pathname = incoming.pathname.slice(PREFIX.length) || "/";
  upstream.search = incoming.search;
  const response = await fetch(new Request(upstream.toString(), request));
  const headers = new Headers(response.headers);
  headers.delete("set-cookie");
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}
