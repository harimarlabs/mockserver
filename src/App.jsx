import React, { Suspense, lazy } from "react";
import { Routes, Route } from "react-router-dom";

import routes from "./routes/MainRoute";
import MainLoader from "./components/commons/MainLoader";
import SessionTimeout from "./components/sessionTimeOut/SessionTimeout";
// import IdleMonitor from "./components/sessionTimeOut/IdleMonitor";
// import IdleMonitor from "./components/sessionOut/IdleMonitor";

// import ProtectedRoute from "./routes/ProtectedRoute";
// import Login from "./pages/auth/Login";
// import SignUp from "./pages/auth/SignUp";
// import NotFound from "./pages/NotFound";
// import Unauthorized from "./pages/Unauthorized";
// import Layout from "./components/container/Layout";

const ProtectedRoute = lazy(() => import("./routes/ProtectedRoute"));
const Login = lazy(() => import("./pages/auth/Login/Login"));
const SignUp = lazy(() => import("./pages/auth/Signup/SignUp"));
const NotFound = lazy(() => import("./pages/NotFound"));
const Unauthorized = lazy(() => import("./pages/Unauthorized"));
const Layout = lazy(() => import("./components/container/Layout"));

const App = () => {
  return (
    <div className="calyx-app">
      <Suspense fallback={<MainLoader />}>
        <Routes>
          <Route path="login" element={<Login />} />
          <Route path="signup" element={<SignUp />} />
          <Route path="unauthorized" element={<Unauthorized />} />
          <Route path="*" element={<NotFound />} />

          <Route path="/" element={<Layout />}>
            {routes.map(({ path, element, roles }) =>
              roles && roles.length ? (
                <Route key={path} element={<ProtectedRoute roles={roles} />}>
                  <Route exact path={path} element={element} />
                </Route>
              ) : (
                <Route key={path} exact path={path} element={element} />
              ),
            )}
          </Route>
        </Routes>

        {/* <SessionTimeout /> */}
        {/* <IdleMonitor /> */}
      </Suspense>
    </div>
  );
};

export default App;
