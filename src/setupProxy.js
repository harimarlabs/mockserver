const { createProxyMiddleware } = require("http-proxy-middleware");

const baseUrl = "http://cms-loadbalancer-test-3-200805129.ap-south-1.elb.amazonaws.com";
console.log(baseUrl);
module.exports = (app) => {
  app.use(
    "/authentication",
    createProxyMiddleware({
      target: `${baseUrl}:9003`,
      changeOrigin: true,
      pathRewrite: {
        "^/authentication": "/",
      },
    }),
  );
  app.use(
    "/administration",
    createProxyMiddleware({
      target: `${baseUrl}:9002`,
      changeOrigin: true,
      pathRewrite: {
        "^/administration": "/",
      },
    }),
  );
  app.use(
    "/careplan",
    createProxyMiddleware({
      target: `${baseUrl}:9006`,
      changeOrigin: true,
      pathRewrite: {
        "^/careplan": "/",
      },
    }),
  );
  app.use(
    "/notification",
    createProxyMiddleware({
      target: `${baseUrl}:9007`,
      changeOrigin: true,
      pathRewrite: {
        "^/notification": "/",
      },
    }),
  );
  app.use(
    "/patientenrollment",
    createProxyMiddleware({
      target: `${baseUrl}:9008`,
      changeOrigin: true,
      pathRewrite: {
        "^/patientenrollment": "/",
      },
    }),
  );
  app.use(
    "/inboundintegration",
    createProxyMiddleware({
      target: `${baseUrl}:9005`,
      changeOrigin: true,
      pathRewrite: {
        "^/inboundintegration": "/",
      },
    }),
  );
  // app.use(
  //   "/riskevaluation",
  //   createProxyMiddleware({
  //     target: `${baseUrl}:9005`,
  //     changeOrigin: true,
  //     pathRewrite: {
  //       "^/riskevaluation": "/",
  //     },
  //   }),
  // );
};
