{{flutter_js}}
{{flutter_build_config}}

// Loads the app with settings every WebUI host needs: CanvasKit from the
// module itself (hosts may be offline, and WebUI X's CSP blocks gstatic), no
// service worker (no host runs them), and single-threaded Skwasm without a
// warning (no host can send the COOP/COEP headers threads need).
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: 'canvaskit/',
    suppressMultithreadingWarning: true,
  },
}).catch(function (error) {
  console.error('Flutter failed to start', error);
  location.replace('fallback.html');
});
