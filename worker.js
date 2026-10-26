// Static-asset passthrough for the "italai" worker: serves the built Jekyll
// site (_site/, uploaded as this worker's static assets — see wrangler.jsonc).
// No logic beyond handing every request to the asset server.
export default {
  async fetch(request, env) {
    return env.ASSETS.fetch(request);
  },
};
